import 'package:get/get.dart';

import '../driver/driver_home_controller.dart';
import '../messages/conversations_controller.dart';
import '../passenger/my_rides_controller.dart';
import '../passenger/ride_search_controller.dart';
import 'home_controller.dart';

/// Controllers das quatro abas; ficam vivos enquanto a Home estiver na pilha.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => RideSearchController());
    Get.lazyPut(() => MyRidesController());
    Get.lazyPut(() => DriverHomeController());
    Get.lazyPut(() => ConversationsController());
  }
}
