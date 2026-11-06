import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../api/models.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'requests_history_controller.dart';

class RequestsHistoryView extends GetView<RequestsHistoryController> {
  const RequestsHistoryView({super.key});

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
                      Text('Meus pedidos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (controller.loading.value && controller.requests.isEmpty)
                    const LoadingView()
                  else if (controller.error.value != null)
                    AppCard(child: MessageView.error(controller.error.value!, controller.load))
                  else if (controller.requests.isEmpty)
                    const AppCard(child: MessageView(icon: Icons.inbox_outlined, title: 'Você ainda não pediu vaga'))
                  else
                    for (final request in controller.requests)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RequestCard(request: request, controller: controller),
                      ),
                ],
              )),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RideRequest request;
  final RequestsHistoryController controller;

  const _RequestCard({required this.request, required this.controller});

  @override
  Widget build(BuildContext context) {
    final ride = request.ride;
    final (status, color) = switch (request.status) {
      RideRequestStatus.pending => ('Aguardando', AppColors.warning),
      RideRequestStatus.accepted => ('Aceito', AppColors.success),
      RideRequestStatus.rejected => ('Recusado', AppColors.danger),
      RideRequestStatus.cancelled => ('Cancelado', AppColors.textHint),
    };
    final when = request.recurring
        ? '${formatWeekdays(request.weekdays)} · ${ride.direction.label.toLowerCase()} às ${ride.departureTime}'
        : '${DateFormat('dd/MM').format(ride.date)} · ${ride.direction.label.toLowerCase()} às ${ride.departureTime}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar.person(ride.driver),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.driver.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    Text(when, style: mutedStyle),
                  ],
                ),
              ),
              StatusLabel(status, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text('${ride.from.label} → ${ride.to.label}', style: mutedStyle),
          if (request.recurring) ...[
            const SizedBox(height: 6),
            const Tag('Toda semana', color: AppColors.primary),
          ],
          if (controller.canCancel(request)) ...[
            const SizedBox(height: 12),
            SoftButton(label: 'Cancelar pedido', height: 44, onPressed: () => controller.cancel(request)),
          ],
        ],
      ),
    );
  }
}
