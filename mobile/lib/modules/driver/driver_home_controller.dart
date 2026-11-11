import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../services/auth_service.dart';
import '../../services/messages_service.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import '../home/home_controller.dart';

/// Aba "Dirigir": recebimentos da semana, pedidos de vaga pendentes e as saídas (em andamento e próximas).
class DriverHomeController extends GetxController {
  final CaronaApi _api = Get.find();
  final AuthService _auth = Get.find();
  final MessagesService _messages = Get.find();

  final earnings = Rxn<Earnings>();
  final requests = <RideRequest>[].obs;

  /// Já saíram e esperam o motorista concluir.
  final inProgress = <Ride>[].obs;
  final upcoming = <Ride>[].obs;
  final loading = false.obs;
  final error = RxnString();

  /// Pedidos sendo aceitos/recusados agora (para desabilitar os botões).
  final processing = <int>{}.obs;

  /// Caronas sendo canceladas agora.
  final cancelling = <int>{}.obs;

  Ride? get nextRide => upcoming.firstOrNull;

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
        _api.drivingInProgress(),
      ]);
      earnings.value = results[0] as Earnings;
      upcoming.assignAll(results[1] as List<Ride>);
      requests.assignAll(results[2] as List<RideRequest>);
      inProgress.assignAll(results[3] as List<Ride>);

      _messages.addContacts(requests.map((r) => r.passenger));
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> cancelRide(Ride ride) async {
    final ok = await confirm(
      'Cancelar esta carona?',
      'A ${ride.direction.label.toLowerCase()} de ${relativeDayLong(ride.date).toLowerCase()} às ${ride.departureTime} '
          'será cancelada para todos os passageiros. A rota continua valendo nos outros dias.',
      confirmLabel: 'Cancelar carona',
      destructive: true,
    );
    if (!ok) return;
    cancelling.add(ride.id);
    try {
      await _api.cancelRide(ride.id);
      showMessage('Carona cancelada.');
      await load();
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      cancelling.remove(ride.id);
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
