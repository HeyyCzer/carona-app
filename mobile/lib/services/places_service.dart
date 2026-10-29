import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/models.dart';

/// Origem/destino da busca do passageiro e locais usados recentemente, salvos no aparelho.
class PlacesService extends GetxService {
  static const _originKey = 'places.origin';
  static const _destinationKey = 'places.destination';
  static const _recentKey = 'places.recent';
  static const _maxRecent = 8;

  /// Sugestão fixa para facilitar o primeiro uso (mesmas coordenadas dos testes do backend).
  static const suggestions = [
    Place(label: 'Unirp - Unidade III', latitude: -20.7850, longitude: -49.3600),
  ];

  final SharedPreferences prefs;

  final origin = Rxn<Place>();
  final destination = Rxn<Place>();
  final recent = <Place>[].obs;

  PlacesService(this.prefs);

  @override
  void onInit() {
    super.onInit();
    origin.value = _read(_originKey);
    destination.value = _read(_destinationKey);
    final raw = prefs.getString(_recentKey);
    if (raw != null) {
      recent.assignAll((jsonDecode(raw) as List).map((e) => Place.fromJson(e)));
    }
  }

  Place? _read(String key) {
    final raw = prefs.getString(key);
    return raw == null ? null : Place.fromJson(jsonDecode(raw));
  }

  void setOrigin(Place place) {
    origin.value = place;
    prefs.setString(_originKey, jsonEncode(place.toJson()));
    remember(place);
  }

  void setDestination(Place place) {
    destination.value = place;
    prefs.setString(_destinationKey, jsonEncode(place.toJson()));
    remember(place);
  }

  void swap() {
    final o = origin.value, d = destination.value;
    if (o == null || d == null) return;
    setOrigin(d);
    setDestination(o);
  }

  void remember(Place place) {
    recent.assignAll([place, ...recent.where((p) => p != place)].take(_maxRecent));
    prefs.setString(_recentKey, jsonEncode(recent.map((p) => p.toJson()).toList()));
  }
}
