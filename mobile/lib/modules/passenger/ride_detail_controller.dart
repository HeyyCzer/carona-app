import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../ui/ui.dart';
import '../home/home_controller.dart';
import 'my_rides_controller.dart';

class RideDetailArgs {
  final RideSearchResult result;

  /// Origem que o passageiro buscou; vira o nome do ponto de embarque enviado ao motorista.
  final Place passengerOrigin;

  const RideDetailArgs({required this.result, required this.passengerOrigin});
}

class RideDetailController extends GetxController {
  final RideDetailArgs args;
  final CaronaApi _api = Get.find();

  final recurring = false.obs;
  final sending = false.obs;

  RideDetailController(this.args);

  RideSearchResult get result => args.result;
  Ride get ride => args.result.ride;

  /// O backend devolve o ponto como "Ponto de embarque"; mandamos um nome que o motorista reconheça.
  Place get pickup {
    final label = 'Perto de ${args.passengerOrigin.label}';
    return result.pickupPoint.withLabel(label.length > 120 ? label.substring(0, 120) : label);
  }

  Future<void> requestSeat() async {
    if (sending.value) return;
    sending.value = true;
    try {
      await _api.requestSeat(ride.id, pickup: pickup, recurring: recurring.value);
      // Volta para a Home já na aba "Caronas", onde o pedido aparece como "Aguardando".
      Get.until((route) => route.settings.name == Routes.home);
      Get.find<HomeController>().select(HomeTab.rides);
      Get.find<MyRidesController>().load();
      showMessage('Pedido enviado! ${ride.driver.firstName} vai confirmar sua vaga.');
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      sending.value = false;
    }
  }

  void message() => Get.toNamed(Routes.chat, arguments: ride.driver);
}
