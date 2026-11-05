import 'package:flutter/material.dart';

import '../api/models.dart';
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

/// Cor de cada situação da vaga: verde só para o que está valendo ou foi feito de fato.
Color bookingStageColor(BookingStage stage) => switch (stage) {
      BookingStage.reserved => AppColors.primary,
      BookingStage.awaitingConfirmation => AppColors.warning,
      BookingStage.confirmed || BookingStage.boarded || BookingStage.completed => AppColors.success,
      BookingStage.noShow || BookingStage.notConfirmed => AppColors.danger,
      BookingStage.cancelled || BookingStage.rideCancelled => AppColors.textHint,
    };
