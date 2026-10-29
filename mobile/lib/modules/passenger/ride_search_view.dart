import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/models.dart';
import '../../app/routes.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import '../home/home_controller.dart';
import '../home/profile_sheet.dart';
import 'ride_search_controller.dart';

/// Aba "Buscar": origem/destino, dia e caronas disponíveis.
class RideSearchView extends GetView<RideSearchController> {
  const RideSearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.search,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              ModePill(
                icon: Icons.swap_vert_rounded,
                label: 'Passageiro',
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
          Obx(() => Text(
                'Bora pra aula,\n${controller.auth.user.value?.firstName ?? ''}?',
                style: headlineStyle,
              )),
          const SizedBox(height: 24),
          _placesCard(),
          const SizedBox(height: 20),
          _dayChips(),
          const SizedBox(height: 20),
          Obx(() => Text(
                'Caronas para ${relativeDayLong(controller.selectedDay.value).toLowerCase()}',
                style: mutedStyle.copyWith(fontSize: 15),
              )),
          const SizedBox(height: 12),
          Obx(_results),
          const SizedBox(height: 20),
          SoftButton(
            label: 'Oferecer carona',
            icon: Icons.add_rounded,
            background: AppColors.primarySoft,
            foreground: AppColors.primary,
            height: 56,
            onPressed: () => Get.toNamed(Routes.newRoute),
          ),
        ],
      ),
    );
  }

  Widget _placesCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Obx(() {
        final origin = controller.places.origin.value;
        final destination = controller.places.destination.value;
        return Column(
          children: [
            _placeRow(
              'Saindo de',
              origin?.label,
              const RouteDot(),
              controller.pickOrigin,
              trailing: controller.places.locating.value
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      tooltip: 'Usar minha localização',
                      icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
                      onPressed: controller.useCurrentLocation,
                    ),
            ),
            const Divider(height: 1, color: AppColors.border),
            _placeRow(
              'Indo para',
              destination?.label,
              const RouteDot(isDestination: true),
              controller.pickDestination,
              trailing: origin != null && destination != null
                  ? IconButton(
                      tooltip: 'Inverter',
                      icon: const Icon(Icons.swap_vert_rounded, color: AppColors.textMuted),
                      onPressed: controller.places.swap,
                    )
                  : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ),
          ],
        );
      }),
    );
  }

  Widget _placeRow(String label, String? value, Widget dot, VoidCallback onTap, {Widget? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            dot,
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: mutedStyle),
                  const SizedBox(height: 2),
                  Text(
                    value ?? 'Escolher local',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: value == null ? AppColors.textHint : AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }

  Widget _dayChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Obx(() => Row(
            children: [
              for (final day in controller.days)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(relativeDayLabel(day)),
                    selected: isSameDay(day, controller.selectedDay.value),
                    onSelected: (_) => controller.selectedDay.value = day,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    labelStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSameDay(day, controller.selectedDay.value) ? Colors.white : AppColors.text,
                    ),
                  ),
                ),
            ],
          )),
    );
  }

  Widget _results() {
    if (!controller.canSearch) {
      return const AppCard(
        child: MessageView(
          icon: Icons.place_outlined,
          title: 'Para onde você vai?',
          subtitle: 'Escolha de onde sai e para onde vai para ver as caronas.',
        ),
      );
    }
    if (controller.loading.value && controller.results.isEmpty) return const LoadingView();
    if (controller.error.value != null) {
      return AppCard(child: MessageView.error(controller.error.value!, controller.search));
    }
    if (controller.results.isEmpty) {
      return const AppCard(
        child: MessageView(
          icon: Icons.directions_car_outlined,
          title: 'Nenhuma carona nesse dia',
          subtitle: 'Tente outro dia ou ajuste a origem e o destino.',
        ),
      );
    }
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          for (final (i, result) in controller.results.indexed) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border, indent: 8, endIndent: 8),
            _RideTile(result: result, onTap: () => controller.openRide(result)),
          ],
        ],
      ),
    );
  }
}

class _RideTile extends StatelessWidget {
  final RideSearchResult result;
  final VoidCallback onTap;

  const _RideTile({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ride = result.ride;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Row(
          children: [
            Avatar(name: ride.driver.name),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.driver.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ride.direction.label} ${ride.departureTime} · '
                    '${formatDistance(result.distanceFromYouMeters)} de você',
                    style: mutedStyle,
                  ),
                ],
              ),
            ),
            Tag(formatMoneyShort(ride.priceCents)),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
