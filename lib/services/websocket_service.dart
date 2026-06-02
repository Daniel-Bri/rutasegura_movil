import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:taller_movil/core/config/app_config.dart';
import 'auth_service.dart';

class WsEvent {
  final String tipo;
  final Map<String, dynamic> payload;
  WsEvent({required this.tipo, required this.payload});
}

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _intentos = 0;
  bool _activo = false;

  final _controller = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get events => _controller.stream;

  Stream<Map<String, dynamic>> on(String tipo) =>
      events.where((e) => e.tipo == tipo).map((e) => e.payload);

  Future<void> conectar() async {
    if (_activo) return;
    _activo = true;
    await _connect();
  }

  Future<void> _connect() async {
    final token = await AuthService().getToken();
    if (token == null) return;

    final wsUrl = AppConfig.baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsUrl/ws?token=$token');

    try {
      debugPrint('[WS-Flutter] Conectando a $uri');
      _channel = WebSocketChannel.connect(uri);
      _intentos = 0;

      _sub = _channel!.stream.listen(
        (data) {
          try {
            final map = jsonDecode(data as String) as Map<String, dynamic>;
            if (map['tipo'] == 'pong') return;
            _controller.add(WsEvent(
              tipo: map['tipo'] as String,
              payload: map['payload'] as Map<String, dynamic>? ?? {},
            ));
          } catch (_) {}
        },
        onDone: () {
          _cleanup();
          if (_activo) _reconectar();
        },
        onError: (_) {
          _cleanup();
          if (_activo) _reconectar();
        },
      );

      _iniciarPing();
    } catch (e) {
      debugPrint('[WS-Flutter] Error al conectar: $e');
      if (_activo) _reconectar();
    }
  }

  void desconectar() {
    _activo = false;
    _reconnectTimer?.cancel();
    _cleanup();
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void _reconectar() {
    if (_intentos >= 10) return;
    _intentos++;
    final delay = Duration(milliseconds: 2000 * _intentos);
    _reconnectTimer = Timer(delay, () => _connect());
  }

  void _iniciarPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      try {
        _channel?.sink.add(jsonEncode({'tipo': 'ping'}));
      } catch (_) {}
    });
  }

  void dispose() {
    desconectar();
    _controller.close();
  }
}
