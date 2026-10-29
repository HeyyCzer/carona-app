import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../services/auth_service.dart';
import '../../services/driven_rides_service.dart';
import '../../services/messages_service.dart';
import '../../ui/ui.dart';
import '../home/home_controller.dart';

/// Aba "Dirigir": recebimentos da semana, próxima saída e pedidos de vaga pendentes.
class DriverHomeController extends GetxController {
  final CaronaApi _api = Get.find();
  final AuthService _auth = Get.find();
  final DrivenRidesService _drivenRides = Get.find();
  final MessagesService _messages = Get.find();

  final earnings = Rxn<Earnings>();
  final nextRide = Rxn<Ride>();
  final requests = <RideRequest>[].obs;
  final awaitingCompletion = 0.obs;
  final loading = false.obs;
  final error = RxnString();

  /// Pedidos sendo aceitos/recusados agora (para desabilitar os botões).
  final processing = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
    ever(Get.find<HomeController>().tab, (HomeTab tab) {
      if (tab == HomeTab.drive) load();
    });
  }

  Future<void> load() async {
    final user = _auth.user.value;
    if (user == null) return;
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([
        _api.earnings(),
        _api.drivingRides(),
        _api.receivedRequests(status: RideRequestStatus.pending),
      ]);
      earnings.value = results[0] as Earnings;
      final rides = results[1] as List<Ride>;
      nextRide.value = rides.firstOrNull;
      requests.assignAll(results[2] as List<RideRequest>);

      _drivenRides.remember(user.id, rides);
      _messages.addContacts(requests.map((r) => r.passenger));
      _drivenRides.awaitingCompletion(user.id).then((list) => awaitingCompletion.value = list.length);
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> accept(RideRequest request) => _respond(request, accept: true);

  Future<void> reject(RideRequest request) => _respond(request, accept: false);

  Future<void> _respond(RideRequest request, {required bool accept}) async {
    processing.add(request.id);
    try {
      if (accept) {
        await _api.acceptRequest(request.id);
        showMessage('${request.passenger.firstName} vai com você!');
      } else {
        await _api.rejectRequest(request.id);
        showMessage('Pedido recusado.');
      }
      requests.removeWhere((r) => r.id == request.id);
      if (accept) load();
    } catch (e) {
      showMessage(errorMessage(e), error: true);
      load();
    } finally {
      processing.remove(request.id);
    }
  }
}
