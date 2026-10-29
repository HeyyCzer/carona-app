import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../api/models.dart';
import '../config.dart';
import '../theme.dart';

LatLng toLatLng(Place place) => LatLng(place.latitude, place.longitude);

/// Mapa do OpenStreetMap com o trajeto e um destaque opcional para o ponto de embarque.
/// Sem [path], o trajeto é desenhado como linha reta entre [from] e [to].
class RouteMap extends StatelessWidget {
  final Place? from;
  final Place? to;
  final List<LatLng>? path;
  final Place? pickup;
  final String? pickupLabel;
  final bool interactive;

  const RouteMap(
      {super.key, this.from, this.to, this.path, this.pickup, this.pickupLabel, this.interactive = true});

  @override
  Widget build(BuildContext context) {
    final line = path != null && path!.length >= 2
        ? path!
        : [if (from != null && to != null) ...[toLatLng(from!), toLatLng(to!)]];
    final points = [...line, ...[from, to, pickup].whereType<Place>().map(toLatLng)];
    final camera = points.length >= 2
        ? CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.fromLTRB(48, 96, 48, 48))
        : null;

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.isEmpty ? const LatLng(-20.80, -49.37) : points.first,
        initialZoom: 15,
        initialCameraFit: camera,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
      ),
      children: [
        osmTileLayer(),
        if (line.isNotEmpty)
          PolylineLayer(polylines: [
            Polyline(points: line, color: AppColors.primary, strokeWidth: 5),
          ]),
        MarkerLayer(markers: [
          if (from != null)
            Marker(point: toLatLng(from!), width: 22, height: 22, child: const _RingMarker()),
          if (to != null)
            Marker(
              point: toLatLng(to!),
              width: 20,
              height: 20,
              child: Container(
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5)),
              ),
            ),
          if (pickup != null)
            Marker(
              point: toLatLng(pickup!),
              width: 180,
              height: 84,
              alignment: Alignment.topCenter,
              child: _PickupMarker(label: pickupLabel),
            ),
        ]),
        const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap')]),
      ],
    );
  }
}

TileLayer osmTileLayer() => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: AppConfig.userAgent,
    );

class _RingMarker extends StatelessWidget {
  const _RingMarker();

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 5),
        ),
      );
}

class _PickupMarker extends StatelessWidget {
  final String? label;

  const _PickupMarker({this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ponto de embarque', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (label != null) Text(label!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ],
    );
  }
}
