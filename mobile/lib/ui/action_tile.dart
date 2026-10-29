import 'package:flutter/material.dart';

import '../theme.dart';

/// Atalho quadrado com rótulo embaixo ("Mensagem", "Ver ponto", "Nova rota"...).
class ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool highlighted;

  const ActionTile({super.key, required this.icon, required this.label, this.onTap, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: highlighted ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: onTap,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: Icon(icon, color: highlighted ? Colors.white : AppColors.text),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.text), textAlign: TextAlign.center),
      ],
    );
  }
}
