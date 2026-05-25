import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taller_movil/services/comunicacion_service.dart';

class LocationSharingService extends ChangeNotifier {
  static final LocationSharingService _instance = LocationSharingService._();
  factory LocationSharingService() => _instance;
  LocationSharingService._();

  final _svc = ComunicacionService();

  Timer? _timer;
  bool _compartiendo = false;
  double? latitud;
  double? longitud;
  String ultimaActualizacion = '--';
  int envios = 0;
  String? error;

  bool get compartiendo => _compartiendo;

  Future<bool> iniciar() async {
    if (_compartiendo) return true;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      error = 'Permiso de ubicación denegado. Habilítalo en Ajustes.';
      notifyListeners();
      return false;
    }

    _compartiendo = true;
    error = null;
    notifyListeners();
    await _enviar();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _enviar());
    return true;
  }

  void detener() {
    _timer?.cancel();
    _timer = null;
    _compartiendo = false;
    notifyListeners();
  }

  Future<void> _enviar() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _svc.actualizarMiUbicacion(
        latitud: pos.latitude,
        longitud: pos.longitude,
      );
      latitud = pos.latitude;
      longitud = pos.longitude;
      final now = DateTime.now();
      ultimaActualizacion =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      envios++;
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }
}
