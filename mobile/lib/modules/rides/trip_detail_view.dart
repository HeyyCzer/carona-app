import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'live_trip_view.dart';
import 'trip_detail_controller.dart';

/// Detalhes de uma carona marcada: mapa com o carro, contagem para a saída, presença, embarque e passageiros.
/// Enquanto a viagem acontece, mostra o modo viagem ([LiveTripView]) no lugar dos detalhes.
class TripDetailView extends GetView<TripDetailController> {
  const TripDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: controller.live.value ? const LiveTripView(key: ValueKey('live')) : _details(),
      ),
    );
  }

  Widget _details() {
    return Scaffold(
      key: const ValueKey('details'),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                Obx(() {
                  final ride = controller.ride;
                  final pickupMinutes = controller.pickupMinutes;
                  return RouteMap(
                    from: ride.from,
                    to: ride.to,
                    path: ride.path,
                    pickup: controller.booking?.pickup,
                    pickupLabel: pickupMinutes == null
                        ? null
                        : pickupMinutes <= 0
                        ? 'Saída do motorista'
                        : '$pickupMinutes min de carro',
                    vehicle: controller.vehicle,
                  );
                }),
                const SafeArea(
                  child: Padding(padding: EdgeInsets.all(20), child: BackSquareButton()),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.load,
              child: Obx(
                () => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  children: [
                    Text(
                      controller.headline,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(_subtitle(), style: mutedStyle.copyWith(fontSize: 16)),
                    if (controller.vehicleSummary != null) ...[
                      const SizedBox(height: 8),
                      _liveRow(controller.vehicleSummary!),
                    ],
                    const SizedBox(height: 16),
                    _infoRow(),
                    const SizedBox(height: 20),
                    if (controller.canGoLive) ...[_liveBanner(), const SizedBox(height: 16)],
                    if (controller.isDriver) ..._driverSection() else ..._passengerSection(),
                    _people(),
                  ],
                ),
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
                  label: controller.isDriver ? 'Cancelar carona' : 'Não vou',
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

  /// Atalho de volta para o modo viagem.
  Widget _liveBanner() {
    return AppCard(
      color: AppColors.primary,
      onTap: controller.enterLive,
      child: const Row(
        children: [
          Icon(Icons.navigation_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modo viagem', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                Text('Mapa em tela cheia, embarques e chegada', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
  }

  Widget _liveRow(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: mutedStyle.copyWith(fontSize: 14, color: AppColors.text))),
      ],
    );
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

  /// Confirmação de presença e código de embarque.
  List<Widget> _passengerSection() {
    final booking = controller.booking;
    if (booking == null) return const [];
    final hint = controller.presenceHint;

    return [
      if (booking.stage == BookingStage.confirmed && booking.boardingCode != null)
        AppCard(
          child: Column(
            children: [
              const Text('Código de embarque', style: mutedStyle),
              const SizedBox(height: 6),
              Text(
                booking.boardingCode!,
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700, letterSpacing: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Mostre ao ${controller.ride.driver.firstName} quando entrar no carro.',
                textAlign: TextAlign.center,
                style: mutedStyle,
              ),
            ],
          ),
        )
      else if (hint != null)
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                controller.canConfirm || booking.stage == BookingStage.reserved
                    ? Icons.schedule_rounded
                    : Icons.info_outline_rounded,
                color: bookingStageColor(booking.stage),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(hint, style: const TextStyle(fontSize: 15))),
            ],
          ),
        ),
      if (controller.canConfirm) ...[
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Vou nessa carona',
          icon: Icons.check_rounded,
          loading: controller.busy.value,
          onPressed: controller.confirmPresence,
        ),
      ],
      if (hint != null || booking.boardingCode != null) const SizedBox(height: 20),
    ];
  }

  /// Compartilhar a posição, conferir os códigos e concluir.
  List<Widget> _driverSection() {
    final widgets = <Widget>[];
    if (controller.inTripWindow) {
      final sharing = controller.sharer.sharing.value;
      final lastSent = controller.sharer.lastSentAt.value;
      widgets.add(
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: sharing,
                onChanged: (_) => controller.toggleSharing(),
                title: const Text('Compartilhar localização', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  controller.sharer.error.value ??
                      (sharing
                          ? lastSent == null
                                ? 'Esperando o GPS...'
                                : 'Os passageiros veem o carro no mapa. Mantenha esta tela aberta.'
                          : 'Os passageiros acompanham o carro em tempo real.'),
                  style: mutedStyle,
                ),
              ),
              const SizedBox(height: 4),
              PrimaryButton(
                label: 'Confirmar embarque',
                icon: Icons.pin_outlined,
                loading: controller.busy.value,
                onPressed: controller.board,
              ),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }
    if (controller.canComplete) {
      widgets.add(
        SoftButton(
          label: 'Concluir viagem',
          icon: Icons.flag_outlined,
          background: AppColors.primarySoft,
          foreground: AppColors.primary,
          onPressed: controller.busy.value ? null : controller.complete,
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }
    if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 8));
    return widgets;
  }

  Widget _people() {
    final ride = controller.ride;
    final passengers = controller.passengers;

    // Antes de confirmar a presença o passageiro vê só o motorista.
    if (!controller.canSeeTrip) {
      return AppCard(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: TripPersonRow(
          person: ride.driver,
          subtitle: 'Motorista',
          isMe: false,
          onMessage: () => controller.message(ride.driver),
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.isDriver && passengers.isNotEmpty
                ? 'Passageiros · ${controller.boardedCount}/${passengers.length} embarcaram'
                : 'Detalhes dos passageiros:',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          TripPersonRow(
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
              TripPersonRow(
                person: p.passenger,
                subtitle: ['Passageiro #${i + 1}', if (p.pickup != null) p.pickup!.label].join(' · '),
                stage: p.stage,
                isMe: p.passenger.id == controller.myId,
                // O motorista fala com todos; o passageiro, só com o motorista.
                onMessage: controller.isDriver ? () => controller.message(p.passenger) : null,
              ),
            if (ride.seats > passengers.length && ride.status == RideStatus.scheduled)
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
      ),
    );
  }
}

/// Linha de uma pessoa da carona (motorista ou passageiro), com a situação do embarque e o botão de mensagem.
class TripPersonRow extends StatelessWidget {
  final Person person;
  final String subtitle;
  final bool isMe;
  final BookingStage? stage;
  final VoidCallback? onMessage;

  const TripPersonRow({super.key, required this.person, required this.subtitle, required this.isMe, this.stage, this.onMessage});

  /// Para o motorista, a situação do embarque de cada passageiro.
  static String _stageText(BookingStage stage) => switch (stage) {
        BookingStage.reserved => 'Ainda não confirmou',
        BookingStage.awaitingConfirmation => 'Aguardando confirmação',
        BookingStage.confirmed => 'Confirmou · aguardando embarque',
        BookingStage.boarded => 'Embarcou',
        BookingStage.completed => 'Viajou',
        BookingStage.noShow => 'Não embarcou',
        _ => stage.label,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Avatar.person(person, size: 52),
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
                if (stage != null) ...[
                  const SizedBox(height: 4),
                  StatusLabel(_stageText(stage!), color: bookingStageColor(stage!)),
                ],
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
