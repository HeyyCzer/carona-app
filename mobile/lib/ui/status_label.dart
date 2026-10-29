import 'package:flutter/material.dart';

import '../theme.dart';

/// Bolinha colorida + texto ("● Confirmada").
class StatusLabel extends StatelessWidget {
  final String text;
  final Color color;

  const StatusLabel(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: AppColors.text)),
      ],
    );
  }
}
