import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../api/models.dart';
import '../../theme.dart';
import '../../ui/ui.dart';

class PickupMapArgs {
  final Place pickup;
  final Place? from;
  final Place? to;
  final List<LatLng>? path;
  final String? subtitle;

  const PickupMapArgs({required this.pickup, this.from, this.to, this.path, this.subtitle});
}

/// "Ver ponto": mapa em tela cheia com o ponto de embarque.
class PickupMapView extends StatelessWidget {
  final PickupMapArgs args;

  const PickupMapView({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          RouteMap(from: args.from, to: args.to, path: args.path, pickup: args.pickup),
          const SafeArea(child: Padding(padding: EdgeInsets.all(20), child: BackSquareButton())),
          Positioned(
            left: 20,
            right: 20,
            bottom: 32,
            child: AppCard(
              child: Row(
                children: [
                  const RouteDot(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(args.pickup.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        if (args.subtitle != null) Text(args.subtitle!, style: mutedStyle),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
