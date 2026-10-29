import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme.dart';

/// Quadrado branco arredondado com ícone (botão "voltar", perfil, filtros).
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color background;
  final Color color;
  final String? tooltip;

  const SquareIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.background = AppColors.surface,
    this.color = AppColors.text,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: SizedBox.square(dimension: 44, child: Icon(icon, color: color, size: 22)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Botão "voltar" padrão das telas internas.
class BackSquareButton extends StatelessWidget {
  const BackSquareButton({super.key});

  @override
  Widget build(BuildContext context) =>
      SquareIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Voltar', onPressed: () => Get.back());
}
