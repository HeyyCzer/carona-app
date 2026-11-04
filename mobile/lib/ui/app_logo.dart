import 'package:flutter/material.dart';

/// Logo do app (carro visto de cima), com cantos arredondados como um ícone.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset('assets/images/logo.png', width: size, height: size, filterQuality: FilterQuality.medium),
    );
  }
}
