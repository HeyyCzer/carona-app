import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../app/routes.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import '../home/home_controller.dart';
import '../home/profile_sheet.dart';
import '../rides/trip_detail_controller.dart';
import 'driver_home_controller.dart';

class DriverHomeView extends GetView<DriverHomeController> {
  const DriverHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      child: Obx(() => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  ModePill(
                    icon: Icons.swap_vert_rounded,
                    label: 'Motorista',
                    onTap: Get.find<HomeController>().toggleMode,
                  ),
                  const Spacer(),
                  const SquareIconButton(
                    icon: Icons.person_outline_rounded,
                    background: AppColors.surfaceMuted,
                    tooltip: 'Perfil',
                    onPressed: showProfileSheet,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (controller.error.value != null)
                AppCard(child: MessageView.error(controller.error.value!, controller.load))
              else
                _earningsCard(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ActionTile(
                      icon: Icons.add_rounded,
                      label: 'Nova rota',
                      highlighted: true,
                      onTap: () async {
                        if (await Get.toNamed(Routes.newRoute) == true) controller.load();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionTile(
                      icon: Icons.route_outlined,
                      label: 'Minhas rotas',
                      onTap: () async {
                        await Get.toNamed(Routes.myRoutes);
                        controller.load();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionTile(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Recebimentos',
                      onTap: () => Get.toNamed(Routes.earnings),
                    ),
                  ),
                ],
              ),
              if (controller.inProgress.isNotEmpty) ...[
                const SizedBox(height: 28),
                const Text('Em andamento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text(
                  'Abra o modo viagem para compartilhar a localização, conferir os embarques e concluir. '
                  'Só quem embarcou entra nos recebimentos.',
                  style: mutedStyle,
                ),
                const SizedBox(height: 14),
                for (final ride in controller.inProgress) _rideCard(ride, inProgress: true),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  const Expanded(child: Text('Pedidos de vaga', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
                  if (controller.requests.isNotEmpty)
                    Tag(
                      controller.requests.length == 1 ? '1 pendente' : '${controller.requests.length} pendentes',
                      color: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (controller.loading.value && controller.requests.isEmpty && controller.earnings.value == null)
                const LoadingView()
              else if (controller.requests.isEmpty)
                const AppCard(
                  child: MessageView(
                    icon: Icons.inbox_outlined,
                    title: 'Nenhum pedido pendente',
                    subtitle: 'Quando alguém pedir vaga nas suas rotas, aparece aqui.',
                  ),
                )
              else
                for (final request in controller.requests)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _RequestCard(request: request, controller: controller),
                  ),
              const SizedBox(height: 12),
              const Text('Próximas saídas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              if (controller.loading.value && controller.upcoming.isEmpty && controller.earnings.value == null)
                const LoadingView()
              else if (controller.upcoming.isEmpty)
                const AppCard(
                  child: MessageView(
                    icon: Icons.event_busy_outlined,
                    title: 'Nenhuma saída agendada',
                    subtitle: 'As caronas são criadas a partir das suas rotas ativas.',
                  ),
                )
              else
                for (final ride in controller.upcoming) _rideCard(ride, inProgress: false),
            ],
          )),
    );
  }

  Widget _earningsCard() {
    final earnings = controller.earnings.value;
    final next = controller.nextRide;
    return AppCard(
      color: AppColors.primarySoft,
      padding: const EdgeInsets.all(22),
      onTap: () => Get.toNamed(Routes.earnings),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recebido esta semana', style: TextStyle(fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            earnings == null ? '—' : formatMoney(earnings.totalCents),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Flexible(
                child: Text(
                  next == null
                      ? 'Nenhuma saída agendada'
                      : 'Próxima saída ${relativeDayLong(next.date).toLowerCase()}, ${next.departureTime}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  /// Embarques, localização e conclusão ficam na tela da viagem; ao voltar, a aba recarrega.
  Future<void> _open(Ride ride) async {
    await Get.toNamed(Routes.tripDetail, arguments: TripDetailArgs(ride: ride));
    controller.load();
  }

  Widget _rideCard(Ride ride, {required bool inProgress}) {
    final taken = ride.seats - ride.seatsAvailable;
    final busy = controller.cancelling.contains(ride.id);
    final live = ride.isHappening;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => _open(ride),
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
            Text(
              '${ride.from.label} → ${ride.to.label}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: mutedStyle,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(taken == 1 ? '1 passageiro' : '$taken passageiros', style: mutedStyle),
                const SizedBox(width: 12),
                const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('Chegada ${ride.estimatedArrivalTime}', style: mutedStyle),
                const Spacer(),
                Text(
                  formatMoneyShort(taken * ride.priceCents),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (inProgress || live) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: PrimaryButton(
                  label: live ? 'Abrir modo viagem' : 'Concluir viagem',
                  icon: live ? Icons.navigation_rounded : Icons.flag_outlined,
                  onPressed: () => _open(ride),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              SoftButton(
                label: 'Cancelar esta carona',
                height: 44,
                foreground: AppColors.danger,
                onPressed: busy ? null : () => controller.cancelRide(ride),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RideRequest request;
  final DriverHomeController controller;

  const _RequestCard({required this.request, required this.controller});

  @override
  Widget build(BuildContext context) {
    final ride = request.ride;
    final when = request.recurring
        ? formatWeekdays(request.weekdays)
        : '${relativeDayLong(ride.date)}, ${ride.departureTime}';

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Avatar.person(request.passenger),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.passenger.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    Text('$when · só ${ride.direction.label.toLowerCase()}', style: mutedStyle),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${formatDistance(request.detourMeters)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('+${request.detourMinutes} min', style: mutedStyle),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(request.pickup.label, style: mutedStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final busy = controller.processing.contains(request.id);
            return Row(
              children: [
                Expanded(
                  child: SoftButton(label: 'Recusar', onPressed: busy ? null : () => controller.reject(request)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: PrimaryButton(
                      label: 'Aceitar',
                      loading: busy,
                      onPressed: () => controller.accept(request),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
