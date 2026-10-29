import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme.dart';
import '../driver/driver_home_view.dart';
import '../messages/conversations_view.dart';
import '../passenger/my_rides_view.dart';
import '../passenger/ride_search_view.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  static const _pages = [RideSearchView(), MyRidesView(), DriverHomeView(), ConversationsView()];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final current = controller.tab.value;
      return Scaffold(
        body: SafeArea(bottom: false, child: IndexedStack(index: current.index, children: _pages)),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primarySoft,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
                fontSize: 13,
                fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
                color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: current.index,
            onDestinationSelected: (i) => controller.select(HomeTab.values[i]),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Buscar'),
              NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Caronas'),
              NavigationDestination(icon: Icon(Icons.directions_car_outlined), label: 'Dirigir'),
              NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Mensagens'),
            ],
          ),
        ),
      );
    });
  }
}
