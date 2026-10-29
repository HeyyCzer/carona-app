import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../app/routes.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import '../home/home_controller.dart';
import 'my_rides_controller.dart';

/// Aba "Caronas": próxima carona confirmada e as próximas vagas/pedidos.
class MyRidesView extends GetView<MyRidesController> {
  const MyRidesView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      child: Obx(() {
        final next = controller.next;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Minhas caronas', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                ),
                SquareIconButton(
                  icon: Icons.history_rounded,
                  background: AppColors.surfaceMuted,
                  tooltip: 'Meus pedidos',
                  onPressed: () => Get.toNamed(Routes.requestsHistory),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (controller.loading.value && controller.items.isEmpty)
              const LoadingView()
            else if (controller.error.value != null)
              AppCard(child: MessageView.error(controller.error.value!, controller.load))
            else ...[
              if (next != null) ..._nextRide(next) else _noNextRide(),
              const SizedBox(height: 28),
              const Text('Próximas caronas', style: sectionTitleStyle),
              const SizedBox(height: 14),
              if (controller.items.isEmpty)
                const AppCard(
                  child: MessageView(icon: Icons.event_available_outlined, title: 'Nada agendado por enquanto'),
                )
              else
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      for (final (i, item) in controller.items.indexed) ...[
                        if (i > 0) const Divider(height: 1, color: AppColors.border, indent: 8, endIndent: 8),
                        _UpcomingTile(item: item, controller: controller),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        );
      }),
    );
  }

  List<Widget> _nextRide(UpcomingItem next) {
    final ride = next.ride;
    return [
      const Text('Próxima carona', style: mutedStyle),
      const SizedBox(height: 4),
      Text(
        '${relativeDayLong(ride.date)}, ${ride.departureTime}',
        style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Confirmada · ${ride.driver.firstName}, ${next.booking!.pickup.label}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: mutedStyle.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      Row(
        children: [
          Expanded(
            child: ActionTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Mensagem',
              highlighted: true,
              onTap: () => controller.message(ride),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ActionTile(
              icon: Icons.place_outlined,
              label: 'Ver ponto',
              onTap: () => controller.showPickup(next),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ActionTile(
              icon: Icons.close_rounded,
              label: 'Não vou',
              onTap: controller.busy.value ? null : () => controller.skip(next.booking!),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _noNextRide() {
    return AppCard(
      child: MessageView(
        icon: Icons.directions_car_outlined,
        title: 'Nenhuma carona confirmada',
        subtitle: 'Quando um motorista aceitar seu pedido, ela aparece aqui.',
        actionLabel: 'Buscar carona',
        onAction: () => Get.find<HomeController>().select(HomeTab.search),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final UpcomingItem item;
  final MyRidesController controller;

  const _UpcomingTile({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final ride = item.ride;
    final (status, color) = switch (item) {
      _ when item.isPending => ('Aguardando', AppColors.warning),
      _ when item.isConfirmed => ('Confirmada', AppColors.success),
      _ => ('Cancelada', AppColors.textHint),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showActions(),
      child: Padding(
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
                  Text(
                    '${ride.direction.label} · ${ride.departureTime}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  Text('${ride.driver.firstName} · ${formatMoneyShort(item.priceCents)}', style: mutedStyle),
                ],
              ),
            ),
            StatusLabel(status, color: color),
          ],
        ),
      ),
    );
  }

  void _showActions() {
    final booking = item.booking;
    final request = item.request;
    final canSkip = item.isConfirmed && !item.ride.hasDeparted;

    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline_rounded),
                title: Text('Mensagem para ${item.ride.driver.firstName}'),
                onTap: () {
                  Get.back();
                  controller.message(item.ride);
                },
              ),
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: const Text('Ver ponto de embarque'),
                onTap: () {
                  Get.back();
                  controller.showPickup(item);
                },
              ),
              if (canSkip)
                ListTile(
                  leading: const Icon(Icons.close_rounded, color: AppColors.danger),
                  title: const Text('Não vou nesse dia', style: TextStyle(color: AppColors.danger)),
                  onTap: () {
                    Get.back();
                    controller.skip(booking!);
                  },
                ),
              if (request != null)
                ListTile(
                  leading: const Icon(Icons.cancel_outlined, color: AppColors.danger),
                  title: const Text('Cancelar pedido', style: TextStyle(color: AppColors.danger)),
                  onTap: () {
                    Get.back();
                    controller.cancelRequest(request);
                  },
                ),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    );
  }
}
