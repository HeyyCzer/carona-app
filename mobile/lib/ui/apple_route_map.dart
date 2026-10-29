import 'dart:math';

import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../api/models.dart';
import '../theme.dart';

apple.LatLng toAppleLatLng(LatLng p) => apple.LatLng(p.latitude, p.longitude);

/// Versão do [RouteMap] com o Apple Maps nativo (só iOS).
class AppleRouteMap extends StatelessWidget {
  final Place? from;
  final Place? to;
  final List<LatLng>? path;
  final Place? pickup;
  final String? pickupLabel;
  final bool interactive;

  const AppleRouteMap(
      {super.key, this.from, this.to, this.path, this.pickup, this.pickupLabel, this.interactive = true});

  static final _hue = HSVColor.fromColor(AppColors.primary).hue;

  apple.LatLng _at(Place p) => apple.LatLng(p.latitude, p.longitude);

  @override
  Widget build(BuildContext context) {
    final line = path != null && path!.length >= 2
        ? path!.map(toAppleLatLng).toList()
        : [if (from != null && to != null) ...[_at(from!), _at(to!)]];
    final points = [...line, ...[from, to, pickup].whereType<Place>().map(_at)];
    final pickupId = apple.AnnotationId('pickup');

    return apple.AppleMap(
      initialCameraPosition: apple.CameraPosition(
        target: points.isEmpty ? const apple.LatLng(-20.80, -49.37) : points.first,
        zoom: 15,
      ),
      // Espaço para o cabeçalho que fica por cima do mapa.
      padding: const EdgeInsets.only(top: 48),
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: false,
      pitchGesturesEnabled: false,
      compassEnabled: false,
      polylines: {
        if (line.isNotEmpty)
          apple.Polyline(
            polylineId: apple.PolylineId('route'),
            points: line,
            color: AppColors.primary,
            width: 5,
            polylineCap: apple.Cap.roundCap,
          ),
      },
      annotations: {
        if (from != null)
          apple.Annotation(
            annotationId: apple.AnnotationId('from'),
            position: _at(from!),
            icon: apple.BitmapDescriptor.markerAnnotationWithHue(_hue),
            infoWindow: apple.InfoWindow(title: 'Origem', snippet: from!.label),
          ),
        if (to != null)
          apple.Annotation(
            annotationId: apple.AnnotationId('to'),
            position: _at(to!),
            icon: apple.BitmapDescriptor.markerAnnotationWithHue(_hue),
            infoWindow: apple.InfoWindow(title: 'Destino', snippet: to!.label),
          ),
        if (pickup != null)
          apple.Annotation(
            annotationId: pickupId,
            position: _at(pickup!),
            icon: apple.BitmapDescriptor.markerAnnotationWithHue(apple.BitmapDescriptor.hueGreen),
            infoWindow: apple.InfoWindow(title: 'Ponto de embarque', snippet: pickupLabel),
            zIndex: 1,
          ),
      },
      onMapCreated: (controller) async {
        if (points.length >= 2) {
          await controller.moveCamera(apple.CameraUpdate.newLatLngBounds(_bounds(points), 48));
        }
        if (pickup != null) controller.showMarkerInfoWindow(pickupId);
      },
    );
  }

  static apple.LatLngBounds _bounds(List<apple.LatLng> points) {
    final lats = points.map((p) => p.latitude);
    final lngs = points.map((p) => p.longitude);
    return apple.LatLngBounds(
      southwest: apple.LatLng(lats.reduce(min), lngs.reduce(min)),
      northeast: apple.LatLng(lats.reduce(max), lngs.reduce(max)),
    );
  }
}
