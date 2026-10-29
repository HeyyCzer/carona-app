import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'my_routes_controller.dart';

class MyRoutesView extends GetView<MyRoutesController> {
  const MyRoutesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.newRoute,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova rota'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: Obx(() => ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                children: [
                  const Row(
                    children: [
                      BackSquareButton(),
                      SizedBox(width: 16),
                      Text('Minhas rotas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (controller.loading.value && controller.routes.isEmpty)
                    const LoadingView()
                  else if (controller.error.value != null)
                    AppCard(child: MessageView.error(controller.error.value!, controller.load))
                  else if (controller.routes.isEmpty)
                    const AppCard(
                      child: MessageView(
                        icon: Icons.route_outlined,
                        title: 'Você ainda não tem rotas',
                        subtitle: 'Publique o trajeto que você já faz e leve colegas junto.',
                      ),
                    )
                  else
                    for (final route in controller.routes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RouteCard(route: route, onDeactivate: () => controller.deactivate(route)),
                      ),
                ],
              )),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final DriverRoute route;
  final VoidCallback onDeactivate;

  const _RouteCard({required this.route, required this.onDeactivate});

  @override
  Widget build(BuildContext context) {
    final times = route.returnTime == null
        ? 'Ida ${route.outboundTime}'
        : 'Ida ${route.outboundTime} · volta ${route.returnTime}';

    return Opacity(
      opacity: route.active ? 1 : 0.55,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _place(const RouteDot(), route.origin.label),
            const SizedBox(height: 10),
            _place(const RouteDot(isDestination: true), route.destination.label),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Tag(formatWeekdays(route.weekdays)),
                Tag(times),
                Tag(route.seats == 1 ? '1 vaga' : '${route.seats} vagas'),
                Tag(formatMoneyShort(route.priceCents)),
                Tag('desvio ${formatDistance(route.maxDetourMeters)}'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    route.active ? '${formatDistance(route.distanceMeters)} de trajeto' : 'Rota desativada',
                    style: mutedStyle,
                  ),
                ),
                if (route.active)
                  TextButton(
                    onPressed: onDeactivate,
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('Desativar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _place(Widget dot, String label) => Row(
        children: [
          dot,
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        ],
      );
}
