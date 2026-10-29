import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/geocoding.dart';
import '../api/models.dart';

/// Não foi possível obter a localização do aparelho; [message] pode ser mostrada ao usuário.
class LocationUnavailable implements Exception {
  final String message;

  const LocationUnavailable(this.message);

  @override
  String toString() => message;
}

/// Origem/destino da busca do passageiro, posição atual do aparelho e locais usados recentemente.
/// A origem começa na posição atual e o destino começa vazio; só os recentes ficam salvos no aparelho.
class PlacesService extends GetxService {
  static const _recentKey = 'places.recent';
  static const _maxRecent = 8;

  /// Sugestão fixa para facilitar o primeiro uso (mesmas coordenadas dos testes do backend).
  static const suggestions = [
    Place(label: 'Unirp - Unidade III', latitude: -20.7850, longitude: -49.3600),
  ];

  final SharedPreferences prefs;
  final Geocoding geocoding;

  final origin = Rxn<Place>();
  final destination = Rxn<Place>();
  final recent = <Place>[].obs;

  /// Última posição conhecida do aparelho (com nome do endereço, se o Nominatim respondeu).
  final here = Rxn<Place>();
  final locating = false.obs;

  PlacesService(this.prefs, this.geocoding);

  @override
  void onInit() {
    super.onInit();
    final raw = prefs.getString(_recentKey);
    if (raw != null) {
      recent.assignAll((jsonDecode(raw) as List).map((e) => Place.fromJson(e)));
    }
    _startAtCurrentLocation();
  }

  Future<void> _startAtCurrentLocation() async {
    try {
      final place = await locate();
      if (origin.value == null) origin.value = place;
    } on LocationUnavailable {
      // Sem permissão ou GPS desligado: o usuário escolhe a origem na mão.
    }
  }

  /// Lê a posição atual do aparelho, pedindo permissão se preciso, e busca um nome para ela.
  Future<Place> locate() async {
    locating.value = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationUnavailable('Ative a localização do aparelho.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw const LocationUnavailable('Permita o acesso à localização nos ajustes do aparelho.');
      }

      final position = await _currentPosition();
      final place = await geocoding.reverse(position.latitude, position.longitude) ??
          Place(label: 'Minha localização', latitude: position.latitude, longitude: position.longitude);
      here.value = place;
      return place;
    } on LocationUnavailable {
      rethrow;
    } catch (e) {
      Get.log('Falha ao obter localização: $e', isError: true);
      throw const LocationUnavailable('Não foi possível obter sua localização agora.');
    } finally {
      locating.value = false;
    }
  }

  /// Posição atual; se o GPS não der um fix a tempo (lugar fechado, emulador), usa a última posição conhecida.
  Future<Position> _currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      rethrow;
    }
  }

  /// Distância em linha reta da posição atual até [place], ou null se a posição ainda não é conhecida.
  int? distanceFromHere(Place place) {
    final current = here.value;
    if (current == null) return null;
    return Geolocator.distanceBetween(current.latitude, current.longitude, place.latitude, place.longitude).round();
  }

  void setOrigin(Place place) {
    origin.value = place;
    remember(place);
  }

  void setDestination(Place place) {
    destination.value = place;
    remember(place);
  }

  void swap() {
    final o = origin.value, d = destination.value;
    if (o == null || d == null) return;
    origin.value = d;
    destination.value = o;
  }

  void remember(Place place) {
    recent.assignAll([place, ...recent.where((p) => p != place)].take(_maxRecent));
    prefs.setString(_recentKey, jsonEncode(recent.map((p) => p.toStorageJson()).toList()));
  }
}
