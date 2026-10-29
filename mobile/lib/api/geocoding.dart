import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'models.dart';

/// Busca de endereços pelo Nominatim (OpenStreetMap). Não precisa de chave,
/// mas exige User-Agent e no máximo ~1 requisição por segundo.
class Geocoding {
  final http.Client _http;

  Geocoding({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  static const _host = 'nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': AppConfig.userAgent, 'Accept-Language': 'pt-BR'};

  Future<List<Place>> search(String query) async {
    final uri = Uri.https(_host, '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '8',
      'countrycodes': 'br',
      'addressdetails': '1',
    });
    final response = await _http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return const [];

    final results = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return results.map((r) {
      return Place(
        label: _shortLabel(r),
        latitude: double.parse(r['lat']),
        longitude: double.parse(r['lon']),
      );
    }).toList();
  }

  Future<String?> reverse(double latitude, double longitude) async {
    final uri = Uri.https(_host, '/reverse', {
      'lat': '$latitude',
      'lon': '$longitude',
      'format': 'jsonv2',
      'zoom': '18',
      'addressdetails': '1',
    });
    try {
      final response = await _http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      return _shortLabel(jsonDecode(utf8.decode(response.bodyBytes)));
    } catch (_) {
      return null;
    }
  }

  /// "Rua X, 123 · Bairro" em vez do display_name completo, que é enorme. O backend aceita até 120 caracteres.
  static String _shortLabel(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>?;
    final name = result['name'] as String?;
    String label;
    if (address != null) {
      final road = address['road'] as String?;
      final number = address['house_number'] as String?;
      final area = (address['suburb'] ?? address['neighbourhood'] ?? address['city'] ?? address['town']) as String?;
      final street = road == null ? null : (number == null ? road : '$road, $number');
      final main = (name != null && name.isNotEmpty && name != road) ? name : street;
      label = [main, if (main != street) street, area].whereType<String>().take(2).join(' · ');
    } else {
      label = '';
    }
    if (label.isEmpty) label = (result['display_name'] as String? ?? 'Local no mapa');
    return label.length > 120 ? label.substring(0, 120) : label;
  }
}
