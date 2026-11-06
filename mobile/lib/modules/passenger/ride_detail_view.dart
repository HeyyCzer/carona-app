import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'ride_detail_controller.dart';

/// Detalhe de uma carona encontrada na busca, com o pedido de vaga.
class RideDetailView extends GetView<RideDetailController> {
  const RideDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final ride = controller.ride;
    final result = controller.result;
    final pickupMinutes = result.estimatedPickupTime.totalMinutes - ride.departureTime.totalMinutes;

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
                  pickup: result.pickupPoint,
                  pickupLabel: pickupMinutes <= 0 ? 'Saída do motorista' : '$pickupMinutes min de carro',
                ),
                const SafeArea(child: Padding(padding: EdgeInsets.all(20), child: BackSquareButton())),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              children: [
                Text(
                  '${ride.driver.firstName} passa às ${result.estimatedPickupTime}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${relativeDayLong(ride.date)} · chegada às ${ride.estimatedArrivalTime}',
                  style: mutedStyle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    children: [
                      _stop(
                        const RouteDot(),
                        'Ponto de embarque',
                        'Embarque · ${formatDistance(result.distanceFromYouMeters)} de você',
                        result.estimatedPickupTime.format(),
                      ),
                      const SizedBox(height: 16),
                      _stop(
                        const RouteDot(isDestination: true),
                        ride.to.label,
                        'Desembarque',
                        ride.estimatedArrivalTime.format(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Avatar.person(ride.driver),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ride.driver.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            Text(
                              ride.seatsAvailable == 1 ? '1 vaga livre' : '${ride.seatsAvailable} vagas livres',
                              style: mutedStyle,
                            ),
                          ],
                        ),
                      ),
                      SquareIconButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        background: AppColors.primarySoft,
                        color: AppColors.primary,
                        tooltip: 'Mensagem',
                        onPressed: controller.message,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Repetir toda semana', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                            Text(
                              'Todos os dias da rota, na ${ride.direction.label.toLowerCase()}',
                              style: mutedStyle,
                            ),
                          ],
                        ),
                      ),
                      Obx(() => Switch(value: controller.recurring.value, onChanged: controller.recurring.call)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(child: Text('Pix, depois da viagem', style: mutedStyle)),
                    Text(
                      formatMoney(ride.priceCents),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Obx(() => PrimaryButton(
                    label: 'Solicitar vaga',
                    loading: controller.sending.value,
                    onPressed: controller.requestSeat,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stop(Widget dot, String title, String subtitle, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 5), child: dot),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              Text(subtitle, style: mutedStyle),
            ],
          ),
        ),
        Text(time, style: const TextStyle(fontSize: 17, color: AppColors.textMuted)),
      ],
    );
  }
}
