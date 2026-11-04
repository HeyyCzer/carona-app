import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'trip_detail_controller.dart';

/// Detalhes de uma carona marcada: mapa, contagem para a saída, motorista e passageiros.
class TripDetailView extends GetView<TripDetailController> {
  const TripDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = controller.ride;
    final booking = controller.booking;
    final pickupMinutes = controller.pickupMinutes;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                RouteMap(
                  from: ride.from,
                  to: ride.to,
                  path: ride.path,
                  pickup: booking?.pickup,
                  pickupLabel: pickupMinutes == null
                      ? null
                      : pickupMinutes <= 0
                      ? 'Saída do motorista'
                      : '$pickupMinutes min de carro',
                ),
                const SafeArea(
                  child: Padding(padding: EdgeInsets.all(20), child: BackSquareButton()),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                children: [
                  Obx(
                    () => Text(
                      controller.headline,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_subtitle(), style: mutedStyle.copyWith(fontSize: 16)),
                  const SizedBox(height: 16),
                  _infoRow(),
                  const SizedBox(height: 20),
                  _people(),
                ],
              ),
            ),
          ),
          Obx(() {
            if (!controller.canCancel) return const SizedBox.shrink();
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SoftButton(
                  label: controller.isDriver ? 'Cancelar carona' : 'Cancelar reserva',
                  background: AppColors.danger.withValues(alpha: 0.12),
                  foreground: AppColors.danger,
                  height: 56,
                  onPressed: controller.busy.value ? null : controller.cancel,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _subtitle() {
    final ride = controller.ride;
    final arrival = 'Chegada em ${ride.to.label} às ${ride.estimatedArrivalTime}';
    final pickupTime = controller.pickupTime;
    if (pickupTime == null) return arrival;
    return 'Embarque às $pickupTime · $arrival';
  }

  /// Data, sentido, ocupação e preço em etiquetas.
  Widget _infoRow() {
    final ride = controller.ride;
    final taken = ride.seats - ride.seatsAvailable;
    final price = controller.booking?.priceCents ?? ride.priceCents;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(Icons.calendar_today_rounded, relativeDayLong(ride.date)),
        _chip(Icons.swap_horiz_rounded, '${ride.direction.label} · ${ride.departureTime}'),
        _chip(Icons.people_alt_outlined, '$taken/${ride.seats} vagas'),
        _chip(
          Icons.payments_outlined,
          controller.isDriver ? '${formatMoneyShort(price)} por pessoa' : formatMoneyShort(price),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _people() {
    final ride = controller.ride;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Obx(() {
        final passengers = controller.passengers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalhes dos passageiros:', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            _PersonRow(
              person: ride.driver,
              subtitle: 'Motorista',
              isMe: controller.isDriver,
              onMessage: controller.isDriver ? null : () => controller.message(ride.driver),
            ),
            if (controller.loading.value && passengers.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LoadingView())
            else if (controller.error.value != null && passengers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(controller.error.value!, style: mutedStyle),
              )
            else ...[
              for (final (i, p) in passengers.indexed)
                _PersonRow(
                  person: p.passenger,
                  subtitle: ['Passageiro #${i + 1}', if (p.pickup != null) p.pickup!.label].join(' · '),
                  isMe: p.passenger.id == controller.myId,
                  // O motorista fala com todos; o passageiro, só com o motorista.
                  onMessage: controller.isDriver ? () => controller.message(p.passenger) : null,
                ),
              if (ride.seats > passengers.length)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    ride.seats - passengers.length == 1
                        ? '1 vaga livre'
                        : '${ride.seats - passengers.length} vagas livres',
                    style: mutedStyle.copyWith(fontSize: 14),
                  ),
                ),
            ],
          ],
        );
      }),
    );
  }
}

class _PersonRow extends StatelessWidget {
  final Person person;
  final String subtitle;
  final bool isMe;
  final VoidCallback? onMessage;

  const _PersonRow({required this.person, required this.subtitle, required this.isMe, this.onMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Avatar(name: person.name, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '${person.name} (você)' : person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: mutedStyle.copyWith(fontSize: 15)),
              ],
            ),
          ),
          if (onMessage != null && !isMe)
            SquareIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              background: AppColors.primarySoft,
              color: AppColors.primary,
              tooltip: 'Mensagem para ${person.firstName}',
              onPressed: onMessage,
            ),
        ],
      ),
    );
  }
}
