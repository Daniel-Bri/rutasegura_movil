import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taller_movil/core/config/app_config.dart';
import 'auth_service.dart';

class OfflineAction {
  final String id;
  final String timestamp;
  final String endpoint;
  final String method;
  final Map<String, dynamic> body;
  final String label;

  OfflineAction({
    required this.id,
    required this.timestamp,
    required this.endpoint,
    required this.method,
    required this.body,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'timestamp': timestamp, 'endpoint': endpoint,
    'method': method, 'body': body, 'label': label,
  };

  factory OfflineAction.fromJson(Map<String, dynamic> j) => OfflineAction(
    id: j['id'] as String,
    timestamp: j['timestamp'] as String,
    endpoint: j['endpoint'] as String,
    method: j['method'] as String,
    body: j['body'] as Map<String, dynamic>,
    label: j['label'] as String,
  );
}

class OfflineQueueService extends ChangeNotifier {
  static final OfflineQueueService _instance = OfflineQueueService._();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._();

  static const _key = 'rutasegura_offline_queue';
  final _auth = AuthService();
  List<OfflineAction> _queue = [];
  bool _sincronizando = false;

  int get pendientes => _queue.length;
  List<OfflineAction> get queue => List.unmodifiable(_queue);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _queue = list.map((e) => OfflineAction.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _queue = [];
      }
    }
    notifyListeners();
  }

  Future<void> encolar(String endpoint, String method, Map<String, dynamic> body, String label) async {
    _queue.add(OfflineAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now().toIso8601String(),
      endpoint: endpoint,
      method: method,
      body: body,
      label: label,
    ));
    await _guardar();
    notifyListeners();
    debugPrint('[OfflineQueue] Encolado: $label (total: ${_queue.length})');
  }

  Future<void> sincronizar() async {
    if (_sincronizando || _queue.isEmpty) return;
    _sincronizando = true;

    final token = await _auth.getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final pendientes = [..._queue];
    for (final action in pendientes) {
      try {
        final url = Uri.parse('${AppConfig.baseUrl}${action.endpoint}');
        http.Response res;
        if (action.method == 'POST') {
          res = await http.post(url, headers: headers, body: jsonEncode(action.body));
        } else if (action.method == 'PATCH') {
          res = await http.patch(url, headers: headers, body: jsonEncode(action.body));
        } else {
          res = await http.put(url, headers: headers, body: jsonEncode(action.body));
        }
        if (res.statusCode >= 200 && res.statusCode < 400) {
          _queue.removeWhere((a) => a.id == action.id);
          await _guardar();
          notifyListeners();
          debugPrint('[OfflineQueue] Sincronizado: ${action.label}');
        } else {
          break;
        }
      } catch (e) {
        debugPrint('[OfflineQueue] Error sincronizando: $e');
        break;
      }
    }

    _sincronizando = false;
  }

  void limpiar() async {
    _queue.clear();
    await _guardar();
    notifyListeners();
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_queue.map((a) => a.toJson()).toList()));
  }
}
