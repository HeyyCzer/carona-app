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
    final booking = next.booking!;
    final stage = booking.stage;
    return [
      Text(stage == BookingStage.boarded ? 'Em viagem' : 'Próxima carona', style: mutedStyle),
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
            decoration: BoxDecoration(color: bookingStageColor(stage), shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${_stageLine(stage)} · ${ride.driver.firstName}, ${booking.pickup.label}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: mutedStyle.copyWith(fontSize: 14),
            ),
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => controller.openDetails(next),
          icon: Icon(booking.canTrack ? Icons.near_me_outlined : Icons.info_outline_rounded, size: 18),
          label: Text(
            booking.canTrack
                ? 'Acompanhar viagem · ${ride.seats - ride.seatsAvailable}/${ride.seats} pessoas'
                : 'Ver detalhes',
          ),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.primary),
        ),
      ),
      if (stage == BookingStage.awaitingConfirmation) ...[
        const SizedBox(height: 4),
        _confirmCard(booking),
      ] else if (stage == BookingStage.confirmed && booking.boardingCode != null) ...[
        const SizedBox(height: 4),
        _codeCard(booking),
      ],
      const SizedBox(height: 12),
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
          if (_canSkip(next)) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ActionTile(
                icon: Icons.close_rounded,
                label: 'Não vou',
                onTap: controller.busy.value ? null : () => controller.skip(booking),
              ),
            ),
          ],
        ],
      ),
    ];
  }

  static String _stageLine(BookingStage stage) => switch (stage) {
        BookingStage.reserved => 'Reservada',
        BookingStage.awaitingConfirmation => 'Confirme sua presença',
        BookingStage.confirmed => 'Presença confirmada',
        BookingStage.boarded => 'A bordo',
        _ => stage.label,
      };

  /// Poucas horas antes da saída: "Vou" ou "Não vou". Sem resposta até o prazo, a vaga é liberada.
  Widget _confirmCard(Booking booking) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Você vai nessa carona?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Confirme até ${formatClock(booking.confirmationDeadline)}. Sem confirmação, sua vaga é liberada.',
            style: mutedStyle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SoftButton(
                  label: 'Não vou',
                  height: 48,
                  foreground: AppColors.danger,
                  onPressed: controller.busy.value ? null : () => controller.skip(booking),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: PrimaryButton(
                    label: 'Vou',
                    loading: controller.busy.value,
                    onPressed: () => controller.confirmPresence(booking),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _codeCard(Booking booking) {
    return AppCard(
      child: Row(
        children: [
          const Expanded(
            child: Text('Código de embarque\nMostre ao motorista ao entrar no carro', style: mutedStyle),
          ),
          Text(
            booking.boardingCode!,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: 8),
          ),
        ],
      ),
    );
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
    final stage = item.stage;
    final (status, color) = stage == null
        ? ('Aguardando', AppColors.warning)
        : (stage.label, bookingStageColor(stage));

    final taken = ride.seats - ride.seatsAvailable;

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
                  Text(monthShort(ride.date), style: mutedStyle.copyWith(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ride.direction.label} · ${ride.departureTime} → ${ride.estimatedArrivalTime}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ride.driver.firstName} · ${formatMoneyShort(item.priceCents)}',
                    style: mutedStyle,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${taken == 1 ? '1 passageiro' : '$taken passageiros'} · '
                          '${ride.seatsAvailable == 1 ? '1 vaga livre' : '${ride.seatsAvailable} vagas livres'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: mutedStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusLabel(status, color: color),
          ],
        ),
      ),
    );
  }

  void _showActions() {
    final booking = item.booking;
    final request = item.request;
    final canSkip = _canSkip(item);

    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.canOpenDetails(item))
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Ver detalhes da carona'),
                  onTap: () {
                    Get.back();
                    controller.openDetails(item);
                  },
                ),
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
              if (item.stage == BookingStage.awaitingConfirmation)
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success),
                  title: const Text('Vou nessa carona'),
                  subtitle: Text('Confirme até ${formatClock(booking!.confirmationDeadline)}'),
                  onTap: () {
                    Get.back();
                    controller.confirmPresence(booking);
                  },
                ),
              if (canSkip)
                ListTile(
                  leading: const Icon(Icons.close_rounded, color: AppColors.danger),
                  title: const Text('Não vou', style: TextStyle(color: AppColors.danger)),
                  subtitle: const Text('Libera sua vaga só neste dia'),
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

/// "Não vou" vale até a saída, enquanto o passageiro ainda não embarcou.
bool _canSkip(UpcomingItem item) {
  final stage = item.stage;
  return !item.ride.hasDeparted &&
      (stage == BookingStage.reserved || stage == BookingStage.awaitingConfirmation || stage == BookingStage.confirmed);
}
