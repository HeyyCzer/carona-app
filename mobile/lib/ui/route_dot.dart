import 'package:flutter/material.dart';

import '../theme.dart';

/// Marcador do trajeto: círculo roxo para origem/embarque, quadrado escuro para destino.
class RouteDot extends StatelessWidget {
  final bool isDestination;

  const RouteDot({super.key, this.isDestination = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isDestination ? AppColors.text : AppColors.primary,
        shape: isDestination ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isDestination ? BorderRadius.circular(3) : null,
      ),
    );
  }
}
