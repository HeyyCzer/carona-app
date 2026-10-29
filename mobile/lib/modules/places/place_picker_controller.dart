import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';

import '../../api/geocoding.dart';
import '../../api/models.dart';
import '../../services/places_service.dart';
import '../../ui/ui.dart';

class PlacePickerArgs {
  final String title;
  final Place? initial;

  const PlacePickerArgs({required this.title, this.initial});
}

/// Escolha de um local por busca de endereço ou tocando no mapa. Devolve o [Place] via Get.back.
class PlacePickerController extends GetxController {
  final PlacePickerArgs args;
  final Geocoding _geocoding = Get.find();
  final PlacesService places = Get.find();

  final query = TextEditingController();
  final mapController = MapController();

  final results = <Place>[].obs;
  final searching = false.obs;
  final searched = false.obs;
  final mapMode = false.obs;
  final confirming = false.obs;

  final _term = ''.obs;

  PlacePickerController(this.args);

  @override
  void onInit() {
    super.onInit();
    query.addListener(() => _term.value = query.text.trim());
    // O Nominatim pede no máximo uma requisição por segundo.
    debounce(_term, _search, time: const Duration(milliseconds: 900));
  }

  Future<void> _search(String term) async {
    if (term.length < 3) {
      results.clear();
      searched.value = false;
      return;
    }
    searching.value = true;
    try {
      results.assignAll(await _geocoding.search(term));
    } catch (_) {
      results.clear();
      showMessage('Não foi possível buscar endereços agora.', error: true);
    } finally {
      searching.value = false;
      searched.value = true;
    }
  }

  void choose(Place place) => Get.back(result: place);

  /// Confirma o ponto no centro do mapa, buscando um nome para ele.
  Future<void> confirmMapCenter() async {
    final center = mapController.camera.center;
    confirming.value = true;
    final label = await _geocoding.reverse(center.latitude, center.longitude);
    confirming.value = false;
    choose(Place(label: label ?? 'Ponto no mapa', latitude: center.latitude, longitude: center.longitude));
  }

  @override
  void onClose() {
    query.dispose();
    mapController.dispose();
    super.onClose();
  }
}
