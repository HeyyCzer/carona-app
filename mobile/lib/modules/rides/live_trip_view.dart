import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import 'trip_detail_controller.dart';
import 'trip_detail_view.dart';

/// Modo viagem: mapa em tela cheia com o carro e um painel arrastável com o essencial do trajeto.
///
/// O motorista vê o compartilhamento da posição, confere os códigos de embarque e conclui.
/// O passageiro vê o código de embarque, onde o carro está e a chegada prevista.
class LiveTripView extends GetView<TripDetailController> {
  const LiveTripView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Obx(() {
              final ride = controller.ride;
              return RouteMap(
                from: ride.from,
                to: ride.to,
                path: ride.path,
                pickup: controller.isDriver ? null : controller.booking?.pickup,
                pickupLabel: controller.isDriver ? null : 'Seu embarque',
                vehicle: controller.vehicle,
              );
            }),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const BackSquareButton(),
                  const Spacer(),
                  const _LivePill(),
                  const Spacer(),
                  SquareIconButton(
                    icon: Icons.info_outline_rounded,
                    background: AppColors.surface,
                    tooltip: 'Detalhes da carona',
                    onPressed: controller.exitLive,
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.48,
            minChildSize: 0.24,
            maxChildSize: 0.92,
            snap: true,
            snapSizes: const [0.48],
            builder: (context, scroll) => Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -4))],
              ),
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: Obx(
                  () => ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                    children: [
                      const _Handle(),
                      const SizedBox(height: 14),
                      ..._header(),
                      const SizedBox(height: 18),
                      if (controller.isDriver) ..._driver() else ..._passenger(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _header() {
    final ride = controller.ride;
    final pickupTime = controller.pickupTime;
    final taken = controller.passengers.length;
    return [
      Text(controller.headline, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      const SizedBox(height: 2),
      Text(
        '${ride.from.label} → ${ride.to.label}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: mutedStyle.copyWith(fontSize: 15),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          _Stat(label: 'Saída', value: '${ride.departureTime}'),
          const SizedBox(width: 10),
          if (controller.isDriver)
            _Stat(label: 'Embarcaram', value: '${controller.boardedCount}/$taken')
          else
            _Stat(label: 'Embarque', value: pickupTime == null ? '—' : '$pickupTime'),
          const SizedBox(width: 10),
          _Stat(label: 'Chegada', value: '${ride.estimatedArrivalTime}', highlighted: true),
        ],
      ),
    ];
  }

  // Motorista

  List<Widget> _driver() {
    final sharing = controller.sharer.sharing.value;
    final lastSent = controller.sharer.lastSentAt.value;
    final error = controller.sharer.error.value;
    final passengers = controller.passengers;

    return [
      AppCard(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        onTap: controller.toggleSharing,
        child: Row(
          children: [
            Icon(
              sharing ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
              color: sharing ? AppColors.success : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sharing ? 'Compartilhando localização' : 'Localização desligada',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    error ??
                        (!sharing
                            ? 'Os passageiros não veem o carro no mapa.'
                            : lastSent == null
                            ? 'Esperando o GPS...'
                            : 'Mantenha esta tela aberta durante o trajeto.'),
                    style: mutedStyle.copyWith(color: error != null ? AppColors.danger : null),
                  ),
                ],
              ),
            ),
            Switch(value: sharing, onChanged: (_) => controller.toggleSharing()),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (controller.canBoard) ...[
        PrimaryButton(
          label: 'Confirmar embarque',
          icon: Icons.pin_outlined,
          loading: controller.busy.value,
          onPressed: controller.board,
        ),
        const SizedBox(height: 16),
      ],
      AppCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.confirmedWaiting == 0
                  ? 'Passageiros'
                  : controller.confirmedWaiting == 1
                  ? 'Passageiros · falta 1 embarcar'
                  : 'Passageiros · faltam ${controller.confirmedWaiting} embarcar',
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            if (controller.loading.value && passengers.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: LoadingView())
            else if (passengers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Ninguém reservou vaga nesta viagem.', style: TextStyle(fontSize: 15)),
              )
            else
              for (final p in passengers)
                TripPersonRow(
                  person: p.passenger,
                  subtitle: p.pickup?.label ?? 'Passageiro',
                  stage: p.stage,
                  isMe: false,
                  onMessage: () => controller.message(p.passenger),
                ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      if (controller.canComplete)
        SoftButton(
          label: 'Concluir viagem',
          icon: Icons.flag_outlined,
          background: AppColors.primarySoft,
          foreground: AppColors.primary,
          onPressed: controller.busy.value ? null : controller.complete,
        )
      else
        const Text(
          'Você conclui a viagem depois da saída, ao chegar ao destino.',
          textAlign: TextAlign.center,
          style: mutedStyle,
        ),
      if (controller.canCancel) ...[const SizedBox(height: 8), _cancelButton('Cancelar carona')],
    ];
  }

  // Passageiro

  List<Widget> _passenger() {
    final booking = controller.booking;
    final ride = controller.ride;
    if (booking == null) return const [];

    return [
      if (booking.stage == BookingStage.boarded)
        _statusCard(
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
          title: 'Você está a bordo',
          subtitle: 'Boa viagem! Chegada prevista às ${ride.estimatedArrivalTime}.',
        )
      else if (booking.boardingCode != null)
        AppCard(
          color: AppColors.primary,
          child: Column(
            children: [
              const Text('Código de embarque', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                booking.boardingCode!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 16,
                ),
              ),
              Text(
                'Mostre ao ${ride.driver.firstName} quando entrar no carro.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      const SizedBox(height: 12),
      _liveRow(controller.vehicleSummary ?? 'Aguardando a posição do carro...', live: controller.vehicle != null),
      const SizedBox(height: 4),
      _liveRow(booking.pickup.label, icon: Icons.place_outlined),
      const SizedBox(height: 16),
      AppCard(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
        child: Column(
          children: [
            TripPersonRow(
              person: ride.driver,
              subtitle: 'Motorista',
              isMe: false,
              onMessage: () => controller.message(ride.driver),
            ),
            for (final p in controller.passengers)
              TripPersonRow(person: p.passenger, subtitle: 'Passageiro', isMe: p.passenger.id == controller.myId),
          ],
        ),
      ),
      if (controller.canCancel) ...[const SizedBox(height: 12), _cancelButton('Não vou')],
    ];
  }

  Widget _statusCard({required IconData icon, required Color color, required String title, required String subtitle}) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(subtitle, style: mutedStyle.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveRow(String text, {bool live = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: icon != null
                ? Icon(icon, size: 18, color: AppColors.textMuted)
                : Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: live ? AppColors.success : AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _cancelButton(String label) {
    return TextButton(
      onPressed: controller.busy.value ? null : controller.cancel,
      style: TextButton.styleFrom(foregroundColor: AppColors.danger),
      child: Text(label),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

/// "● AO VIVO" sobre o mapa.
class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: AppColors.text, borderRadius: BorderRadius.circular(999)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: AppColors.success),
          SizedBox(width: 8),
          Text(
            'MODO VIAGEM',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _Stat({required this.label, required this.value, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: mutedStyle),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: highlighted ? AppColors.primary : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
