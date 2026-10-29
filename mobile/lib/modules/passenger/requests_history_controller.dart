import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../services/auth_service.dart';
import '../../ui/ui.dart';
import 'my_rides_controller.dart';

/// Todos os pedidos de vaga do passageiro, inclusive os semanais, que podem ser encerrados aqui.
class RequestsHistoryController extends GetxController {
  final CaronaApi _api = Get.find();

  final requests = <RideRequest>[].obs;
  final loading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      requests.assignAll(await _api.myRequests());
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  bool canCancel(RideRequest r) =>
      r.status == RideRequestStatus.pending || (r.status == RideRequestStatus.accepted && r.recurring);

  Future<void> cancel(RideRequest request) async {
    final message = request.status == RideRequestStatus.accepted
        ? 'Você deixa de ir com ${request.ride.driver.firstName} toda semana e as próximas vagas são liberadas.'
        : 'O pedido para a carona de ${request.ride.driver.firstName} será cancelado.';
    if (!await confirm('Cancelar pedido?', message, confirmLabel: 'Cancelar pedido', destructive: true)) return;
    try {
      await _api.cancelRequest(request.id);
      showMessage('Pedido cancelado.');
      await load();
      if (Get.isRegistered<MyRidesController>()) Get.find<MyRidesController>().load();
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    }
  }
}
