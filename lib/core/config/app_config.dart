import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class AppConfig {
  static const _railwayUrl    = 'https://rutasegurabackend-production.up.railway.app';
  static const _localWeb      = 'http://localhost:8000';
// emulador
  static const _localFisico   = 'http://192.168.100.7:8000';   // celular físico en red local

  static String get baseUrl {
    if (kReleaseMode) return _railwayUrl;
    if (kIsWeb) return _localWeb;
    return _localFisico; // cambiar a _localAndroid si usas emulador
  }
}
