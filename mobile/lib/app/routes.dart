import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../api/models.dart';

import '../modules/auth/login_controller.dart';
import '../modules/auth/login_view.dart';
import '../modules/auth/register_controller.dart';
import '../modules/auth/register_view.dart';
import '../modules/driver/driving_rides_controller.dart';
import '../modules/driver/driving_rides_view.dart';
import '../modules/driver/earnings_controller.dart';
import '../modules/driver/earnings_view.dart';
import '../modules/driver/my_routes_controller.dart';
import '../modules/driver/my_routes_view.dart';
import '../modules/driver/new_route_controller.dart';
import '../modules/driver/new_route_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/messages/chat_controller.dart';
import '../modules/messages/chat_view.dart';
import '../modules/passenger/requests_history_controller.dart';
import '../modules/passenger/requests_history_view.dart';
import '../modules/passenger/ride_detail_controller.dart';
import '../modules/passenger/ride_detail_view.dart';
import '../modules/places/pickup_map_view.dart';
import '../modules/places/place_picker_controller.dart';
import '../modules/places/place_picker_view.dart';
import '../modules/rides/trip_detail_controller.dart';
import '../modules/rides/trip_detail_view.dart';
import '../services/auth_service.dart';

abstract class Routes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  /// argumentos: [RideDetailArgs]
  static const rideDetail = '/ride';

  /// argumentos: [PlacePickerArgs]; devolve o [Place] escolhido
  static const placePicker = '/place-picker';

  /// argumentos: [PickupMapArgs]
  static const pickupMap = '/pickup-map';
  static const requestsHistory = '/requests-history';
  static const newRoute = '/routes/new';
  static const myRoutes = '/routes/mine';
  static const earnings = '/earnings';
  static const drivingRides = '/rides/driving';

  /// argumentos: [TripDetailArgs]; devolve `true` se a vaga/carona foi cancelada
  /// (quem abre recarrega ao voltar, porque a presença e os embarques mudam lá dentro)
  static const tripDetail = '/trip';

  /// argumentos: [Person]
  static const chat = '/chat';
}

final appPages = [
  GetPage(
    name: Routes.login,
    page: () => const LoginView(),
    binding: BindingsBuilder(() => Get.lazyPut(() => LoginController())),
  ),
  GetPage(
    name: Routes.register,
    page: () => const RegisterView(),
    binding: BindingsBuilder(() => Get.lazyPut(() => RegisterController())),
  ),
  GetPage(name: Routes.home, page: () => const HomeView(), binding: HomeBinding()),
  GetPage(
    name: Routes.rideDetail,
    page: () => _requireArgs<RideDetailArgs>(() => const RideDetailView()),
    binding: BindingsBuilder(() => Get.lazyPut(() => RideDetailController(Get.arguments))),
  ),
  GetPage(
    name: Routes.placePicker,
    page: () => _requireArgs<PlacePickerArgs>(() => const PlacePickerView()),
    binding: BindingsBuilder(() => Get.lazyPut(() => PlacePickerController(Get.arguments))),
  ),
  GetPage(name: Routes.pickupMap, page: () => _requireArgs<PickupMapArgs>(() => PickupMapView(args: Get.arguments))),
  GetPage(
    name: Routes.requestsHistory,
    page: () => const RequestsHistoryView(),
    binding: BindingsBuilder(() => Get.lazyPut(() => RequestsHistoryController())),
  ),
  GetPage(
    name: Routes.newRoute,
    page: () => const NewRouteView(),
    binding: BindingsBuilder(() => Get.lazyPut(() => NewRouteController())),
  ),
  GetPage(
    name: Routes.myRoutes,
    page: () => const MyRoutesView(),
    binding: BindingsBuilder(() => Get.lazyPut(() => MyRoutesController())),
  ),
  GetPage(
    name: Routes.earnings,
    page: () => const EarningsView(),
    binding: BindingsBuilder(() => Get.lazyPut(() => EarningsController())),
  ),
  GetPage(
    name: Routes.drivingRides,
    page: () => const DrivingRidesView(),
    binding: BindingsBuilder(() => Get.lazyPut(() => DrivingRidesController())),
  ),
  GetPage(
    name: Routes.tripDetail,
    page: () => _requireArgs<TripDetailArgs>(() => const TripDetailView()),
    binding: BindingsBuilder(() => Get.lazyPut(() => TripDetailController(Get.arguments))),
  ),
  GetPage(
    name: Routes.chat,
    page: () => _requireArgs<Person>(() => const ChatView()),
    binding: BindingsBuilder(() => Get.lazyPut(() => ChatController(Get.arguments))),
  ),
];

/// No web, recarregar a página reabre a URL atual, mas os argumentos da navegação se perdem.
/// Telas que dependem deles voltam para o início em vez de quebrar.
Widget _requireArgs<T>(Widget Function() page) => Get.arguments is T ? page() : const _BackToStart();

class _BackToStart extends StatelessWidget {
  const _BackToStart();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Get.find<AuthService>().isLoggedIn ? Routes.home : Routes.login);
    });
    return const SizedBox.shrink();
  }
}
