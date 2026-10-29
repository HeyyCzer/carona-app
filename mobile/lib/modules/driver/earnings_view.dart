import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../api/models.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'earnings_controller.dart';

class EarningsView extends GetView<EarningsController> {
  const EarningsView({super.key});

  static final _dayMonth = DateFormat('dd/MM');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: Obx(() {
            final earnings = controller.earnings.value;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const Row(
                  children: [
                    BackSquareButton(),
                    SizedBox(width: 16),
                    Text('Recebimentos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Semana anterior',
                      onPressed: controller.previousWeek,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Text(
                        controller.isCurrentWeek
                            ? 'Esta semana'
                            : '${_dayMonth.format(controller.weekStart.value)} a ${_dayMonth.format(controller.weekEnd)}',
                        textAlign: TextAlign.center,
                        style: sectionTitleStyle,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Próxima semana',
                      onPressed: controller.isCurrentWeek ? null : controller.nextWeek,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppCard(
                  color: AppColors.primarySoft,
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total recebido', style: TextStyle(fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(
                        earnings == null ? '—' : formatMoney(earnings.totalCents),
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1),
                      ),
                      if (earnings != null)
                        Text(
                          '${earnings.ridesCount} ${earnings.ridesCount == 1 ? 'viagem' : 'viagens'} · '
                          '${earnings.passengersCount} ${earnings.passengersCount == 1 ? 'passageiro' : 'passageiros'}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contam as viagens marcadas como concluídas. O pagamento é feito por Pix, direto entre vocês.',
                  style: mutedStyle,
                ),
                const SizedBox(height: 20),
                if (controller.loading.value && earnings == null)
                  const LoadingView()
                else if (controller.error.value != null)
                  AppCard(child: MessageView.error(controller.error.value!, controller.load))
                else if (earnings != null && earnings.rides.isEmpty)
                  const AppCard(child: MessageView(icon: Icons.savings_outlined, title: 'Nenhuma viagem concluída'))
                else if (earnings != null)
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        for (final (i, ride) in earnings.rides.indexed) ...[
                          if (i > 0) const Divider(height: 1, color: AppColors.border, indent: 8, endIndent: 8),
                          _row(ride),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _row(EarningsRide ride) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(Weekday.fromDate(ride.date).short, style: mutedStyle),
                Text('${ride.date.day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.direction.label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                Text(ride.passengers == 1 ? '1 passageiro' : '${ride.passengers} passageiros', style: mutedStyle),
              ],
            ),
          ),
          Text(formatMoney(ride.totalCents), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
