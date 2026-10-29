import 'package:flutter/material.dart';

import '../theme.dart';

/// Etiqueta arredondada lilás ("R$ 6", "2 pendentes", "≈ +2 min").
class Tag extends StatelessWidget {
  final String text;
  final Color background;
  final Color color;

  const Tag(this.text, {super.key, this.background = AppColors.primarySoft, this.color = AppColors.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}
