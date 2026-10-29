import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../api/models.dart';
import '../../services/places_service.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'place_picker_controller.dart';

class PlacePickerView extends GetView<PlacePickerController> {
  const PlacePickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() => controller.mapMode.value ? _mapPicker() : _searchList()),
      ),
    );
  }

  Widget _header(String title, {VoidCallback? onBack}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          SquareIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Voltar', onPressed: onBack ?? Get.back),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _searchList() {
    return Column(
      children: [
        _header(controller.args.title),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: controller.query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar endereço ou lugar...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
              suffixIcon: Obx(() => controller.searching.value
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : const SizedBox.shrink()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            final results = controller.results;
            final showingResults = controller.searched.value || results.isNotEmpty;
            final recent = controller.places.recent;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                _tile(
                  icon: Icons.my_location_rounded,
                  title: 'Usar minha localização',
                  subtitle: controller.places.locating.value
                      ? 'Buscando sua localização...'
                      : controller.places.here.value?.label ?? 'Pelo GPS do aparelho',
                  onTap: controller.useCurrentLocation,
                ),
                _tile(
                  icon: Icons.map_outlined,
                  title: 'Escolher no mapa',
                  subtitle: 'Arraste o mapa até o ponto exato',
                  onTap: () => controller.mapMode.value = true,
                ),
                if (showingResults) ...[
                  _sectionLabel('Resultados'),
                  if (results.isEmpty && !controller.searching.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Nada encontrado. Tente outro termo ou escolha no mapa.', style: mutedStyle),
                    ),
                  ...results.map(_placeTile),
                ] else ...[
                  if (recent.isNotEmpty) ...[_sectionLabel('Recentes'), ...recent.map(_placeTile)],
                  _sectionLabel('Sugestões'),
                  ...PlacesService.suggestions.map((p) => _placeTile(p, icon: Icons.school_outlined)),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: mutedStyle),
      );

  Widget _placeTile(Place place, {IconData icon = Icons.place_outlined}) =>
      _tile(icon: icon, title: place.label, subtitle: _placeDetail(place), onTap: () => controller.choose(place));

  /// "São José do Rio Preto - SP · 2,3 km de você", com o que estiver disponível.
  String? _placeDetail(Place place) {
    final distance = controller.places.distanceFromHere(place);
    final parts = [place.detail, if (distance != null) '${formatDistance(distance)} de você'].whereType<String>();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Widget _tile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                  if (subtitle != null) Text(subtitle, style: mutedStyle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapPicker() {
    final initial = controller.args.initial ?? controller.places.origin.value;
    return Column(
      children: [
        _header('Escolher no mapa', onBack: () => controller.mapMode.value = false),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: controller.mapController,
                options: MapOptions(
                  initialCenter: initial == null ? const LatLng(-20.80, -49.37) : toLatLng(initial),
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                ),
                children: [
                  osmTileLayer(),
                  const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap')]),
                ],
              ),
              // Pino fixo no centro: o usuário move o mapa por baixo dele.
              const IgnorePointer(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.location_on, size: 48, color: AppColors.primary),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Obx(() => PrimaryButton(
                      label: 'Usar este ponto',
                      loading: controller.confirming.value,
                      onPressed: controller.confirmMapCenter,
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
