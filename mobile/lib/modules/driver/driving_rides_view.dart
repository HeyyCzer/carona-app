import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'driving_rides_controller.dart';

class DrivingRidesView extends GetView<DrivingRidesController> {
  const DrivingRidesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: Obx(() => ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  const Row(
                    children: [
                      BackSquareButton(),
                      SizedBox(width: 16),
                      Text('Minhas saídas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (controller.loading.value && controller.upcoming.isEmpty && controller.toComplete.isEmpty)
                    const LoadingView()
                  else if (controller.error.value != null)
                    AppCard(child: MessageView.error(controller.error.value!, controller.load))
                  else ...[
                    if (controller.toComplete.isNotEmpty) ...[
                      const Text('Para concluir', style: sectionTitleStyle),
                      const SizedBox(height: 4),
                      const Text('Marque as viagens feitas para elas entrarem nos recebimentos.', style: mutedStyle),
                      const SizedBox(height: 12),
                      for (final ride in controller.toComplete) _rideCard(ride, completed: true),
                      const SizedBox(height: 16),
                    ],
                    const Text('Próximas', style: sectionTitleStyle),
                    const SizedBox(height: 12),
                    if (controller.upcoming.isEmpty)
                      const AppCard(
                        child: MessageView(
                          icon: Icons.event_busy_outlined,
                          title: 'Nenhuma saída agendada',
                          subtitle: 'As caronas são criadas a partir das suas rotas ativas.',
                        ),
                      )
                    else
                      for (final ride in controller.upcoming) _rideCard(ride, completed: false),
                  ],
                ],
              )),
        ),
      ),
    );
  }

  Widget _rideCard(Ride ride, {required bool completed}) {
    final taken = ride.seats - ride.seatsAvailable;
    final busy = controller.processing.contains(ride.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${relativeDayLong(ride.date)} · ${ride.direction.label} ${ride.departureTime}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ),
                Tag('$taken/${ride.seats} vagas'),
              ],
            ),
            const SizedBox(height: 6),
            Text('${ride.from.label} → ${ride.to.label}', style: mutedStyle),
            const SizedBox(height: 12),
            if (completed)
              SizedBox(
                height: 48,
                child: PrimaryButton(
                  label: 'Marcar como concluída',
                  loading: busy,
                  onPressed: () => controller.complete(ride),
                ),
              )
            else
              SoftButton(
                label: 'Cancelar esta carona',
                height: 44,
                foreground: AppColors.danger,
                onPressed: busy ? null : () => controller.cancel(ride),
              ),
          ],
        ),
      ),
    );
  }
}
