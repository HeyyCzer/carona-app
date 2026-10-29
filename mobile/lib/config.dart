import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Endereço do backend. Pode ser sobrescrito com
/// `flutter run --dart-define=API_URL=http://192.168.0.10:8080`.
class AppConfig {
  static const _fromEnv = String.fromEnvironment('API_URL');

  static String get apiUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    // O emulador Android enxerga o localhost da máquina como 10.0.2.2
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8080';
    return 'http://localhost:8080';
  }

  /// User-Agent exigido pelos serviços do OpenStreetMap (tiles e Nominatim).
  static const userAgent = 'me.rafaelpereira.carona_app';
}
