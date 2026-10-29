import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/format.dart';

/// Círculo lilás com as iniciais da pessoa (ou um ícone, para grupos).
class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final IconData? icon;

  const Avatar({super.key, required this.name, this.size = 44, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
      child: icon != null
          ? Icon(icon, color: AppColors.primary, size: size * 0.45)
          : Text(
              initials(name),
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: size * 0.34),
            ),
    );
  }
}
