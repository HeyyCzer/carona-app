import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import 'new_route_controller.dart';

class NewRouteView extends GetView<NewRouteController> {
  const NewRouteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  const Row(
                    children: [
                      BackSquareButton(),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nova rota', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                          Text('Modo motorista', style: mutedStyle),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _placesCard(),
                  const SizedBox(height: 16),
                  _weekdays(),
                  const SizedBox(height: 16),
                  _times(context),
                  const SizedBox(height: 16),
                  _detour(),
                  const SizedBox(height: 16),
                  _seatsAndPrice(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Obx(() {
                final days = controller.weekdays.length;
                return PrimaryButton(
                  label: 'Publicar rota · ${days == 1 ? '1 dia' : '$days dias'}',
                  loading: controller.saving.value,
                  onPressed: controller.validationError == null ? controller.publish : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placesCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Obx(() {
        final distance = controller.roadDistance;
        return Column(
          children: [
            _placeRow(controller.origin.value, 'Saída (sua casa, por exemplo)', const RouteDot(), controller.pickOrigin,
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)),
            const Divider(height: 1, color: AppColors.border),
            _placeRow(
              controller.destination.value,
              'Destino (o campus)',
              const RouteDot(isDestination: true),
              controller.pickDestination,
              distance == null
                  ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)
                  : Text(formatDistance(distance), style: mutedStyle),
            ),
          ],
        );
      }),
    );
  }

  Widget _placeRow(Place? place, String hint, Widget dot, VoidCallback onTap, Widget trailing) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            dot,
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                place?.label ?? hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: place == null ? AppColors.textHint : AppColors.text,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _weekdays() {
    return Obx(() => Row(
          children: [
            for (final (i, day) in Weekday.values.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _dayChip(day, controller.weekdays.contains(day))),
            ],
          ],
        ));
  }

  Widget _dayChip(Weekday day, bool selected) {
    return Material(
      color: selected ? AppColors.primary : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => controller.toggleDay(day),
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(
              day.short,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _times(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            onTap: () => controller.pickOutboundTime(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saída da ida', style: mutedStyle),
                const SizedBox(height: 4),
                Obx(() => Text(
                      controller.outboundTime.value.format(),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            onTap: () => controller.pickReturnTime(context),
            padding: const EdgeInsets.fromLTRB(18, 18, 6, 18),
            child: Obx(() {
              final time = controller.returnTime.value;
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saída da volta', style: mutedStyle),
                        const SizedBox(height: 4),
                        Text(
                          time?.format() ?? 'Sem volta',
                          style: TextStyle(
                            fontSize: time == null ? 18 : 28,
                            height: time == null ? 1.85 : null,
                            fontWeight: FontWeight.w700,
                            color: time == null ? AppColors.textHint : AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (time != null)
                    IconButton(
                      tooltip: 'Sem volta',
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                      onPressed: () => controller.returnTime.value = null,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _detour() {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Desvio máximo pra buscar alguém', style: mutedStyle),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatDistance(controller.detourMeters.value),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Tag('≈ +${controller.detourMinutes} min', color: AppColors.primary),
                ],
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.surfaceMuted,
                  thumbColor: AppColors.primary,
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                  trackHeight: 4,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                ),
                child: Slider(
                  value: controller.detourMeters.value.toDouble(),
                  max: NewRouteController.maxDetour.toDouble(),
                  divisions: NewRouteController.maxDetour ~/ 50,
                  onChanged: (v) => controller.detourMeters.value = v.round(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Só na rota', style: mutedStyle),
                  Text(formatDistance(NewRouteController.maxDetour), style: mutedStyle),
                ],
              ),
            ],
          )),
    );
  }

  Widget _seatsAndPrice() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vagas', style: mutedStyle),
                  const SizedBox(height: 8),
                  Obx(() => Row(
                        children: [
                          _stepButton(Icons.remove_rounded, controller.seats.value > 1 ? () => controller.seats.value-- : null),
                          Expanded(
                            child: Text(
                              '${controller.seats.value}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                            ),
                          ),
                          _stepButton(
                            Icons.add_rounded,
                            controller.seats.value < NewRouteController.maxSeats ? () => controller.seats.value++ : null,
                            highlighted: true,
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppCard(
              onTap: controller.editPrice,
              child: Obx(() {
                final suggestion = controller.suggestedPrice;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Valor por trecho', style: mutedStyle),
                    const SizedBox(height: 4),
                    FittedBox(
                      child: Text(
                        formatMoney(controller.priceCents.value),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (suggestion != null)
                      Text(
                        suggestion.$1 == suggestion.$2
                            ? 'sugerido ${formatMoneyShort(suggestion.$1)}'
                            : 'sugerido ${formatMoneyShort(suggestion.$1)}–'
                                '${formatMoneyShort(suggestion.$2).replaceFirst('R\$', '').trim()}',
                        style: mutedStyle.copyWith(fontSize: 12),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onTap, {bool highlighted = false}) {
    return Material(
      color: highlighted ? AppColors.primarySoft : AppColors.surfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            icon,
            color: onTap == null ? AppColors.textHint : (highlighted ? AppColors.primary : AppColors.text),
          ),
        ),
      ),
    );
  }
}
