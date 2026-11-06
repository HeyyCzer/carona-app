import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../app/routes.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import '../home/home_controller.dart';
import '../home/profile_sheet.dart';
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
              else ...[
                _earningsCard(),
                if (controller.awaitingCompletion.value > 0) ...[
                  const SizedBox(height: 12),
                  _awaitingBanner(controller.awaitingCompletion.value),
                ],
              ],
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
            ],
          )),
    );
  }

  Widget _earningsCard() {
    final earnings = controller.earnings.value;
    final next = controller.nextRide.value;
    return AppCard(
      color: AppColors.primarySoft,
      padding: const EdgeInsets.all(22),
      onTap: () => Get.toNamed(Routes.drivingRides)?.then((_) => controller.load()),
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

  Widget _awaitingBanner(int count) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      onTap: () => Get.toNamed(Routes.drivingRides)?.then((_) => controller.load()),
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 1
                  ? '1 viagem em andamento: confira os embarques e conclua'
                  : '$count viagens em andamento: confira os embarques e conclua',
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
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
