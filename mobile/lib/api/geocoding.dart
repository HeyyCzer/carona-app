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

  /// Com [near], prefere resultados em volta desse ponto (sem excluir os de fora).
  Future<List<Place>> search(String query, {Place? near}) async {
    final uri = Uri.https(_host, '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '8',
      'countrycodes': 'br',
      'addressdetails': '1',
      if (near != null) 'viewbox': _viewbox(near),
    });
    final response = await _http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return const [];

    final results = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return results.map((r) => _place(r, double.parse(r['lat']), double.parse(r['lon']))).toList();
  }

  /// Nome do endereço em [latitude], [longitude], ou null se o Nominatim falhar.
  Future<Place?> reverse(double latitude, double longitude) async {
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
      return _place(jsonDecode(utf8.decode(response.bodyBytes)), latitude, longitude);
    } catch (_) {
      return null;
    }
  }

  /// Retângulo de ~30 km em volta de [center], no formato do Nominatim (lng1,lat1,lng2,lat2).
  static String _viewbox(Place center) {
    const delta = 0.3;
    return [
      center.longitude - delta,
      center.latitude + delta,
      center.longitude + delta,
      center.latitude - delta,
    ].join(',');
  }

  static Place _place(Map<String, dynamic> result, double latitude, double longitude) =>
      Place(label: _shortLabel(result), latitude: latitude, longitude: longitude, detail: _cityLabel(result));

  /// "São José do Rio Preto - SP", para diferenciar lugares com o mesmo nome em cidades diferentes.
  static String? _cityLabel(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>?;
    if (address == null) return null;
    final city = (address['city'] ?? address['town'] ?? address['village'] ?? address['municipality']) as String?;
    // ISO3166-2-lvl4 vem como "BR-SP".
    final state = (address['ISO3166-2-lvl4'] as String?)?.split('-').last ?? address['state'] as String?;
    final parts = [city, state].whereType<String>();
    return parts.isEmpty ? null : parts.join(' - ');
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
