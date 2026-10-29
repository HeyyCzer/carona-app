import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'apple_route_map.dart';
import 'route_map.dart';

/// Mapa livre para escolher um ponto: avisa o centro atual a cada movimento.
/// Apple Maps no iOS, OpenStreetMap nas outras plataformas.
class CenterPickerMap extends StatelessWidget {
  final LatLng initial;
  final ValueChanged<LatLng> onCenterChanged;

  const CenterPickerMap({super.key, required this.initial, required this.onCenterChanged});

  @override
  Widget build(BuildContext context) {
    if (useAppleMaps) {
      return apple.AppleMap(
        initialCameraPosition: apple.CameraPosition(target: toAppleLatLng(initial), zoom: 16),
        rotateGesturesEnabled: false,
        pitchGesturesEnabled: false,
        compassEnabled: false,
        onCameraMove: (pos) => onCenterChanged(LatLng(pos.target.latitude, pos.target.longitude)),
      );
    }
    return FlutterMap(
      options: MapOptions(
        initialCenter: initial,
        initialZoom: 16,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        onPositionChanged: (camera, _) => onCenterChanged(camera.center),
      ),
      children: [osmTileLayer(), osmAttribution()],
    );
  }
}
