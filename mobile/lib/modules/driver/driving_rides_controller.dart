import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../services/auth_service.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';

/// Caronas do motorista: as que já saíram (em andamento, para concluir) e as próximas (para cancelar se preciso).
class DrivingRidesController extends GetxController {
  final CaronaApi _api = Get.find();

  final upcoming = <Ride>[].obs;
  final toComplete = <Ride>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final processing = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([_api.drivingRides(), _api.drivingInProgress()]);
      upcoming.assignAll(results[0]);
      toComplete.assignAll(results[1]);
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> cancel(Ride ride) async {
    final ok = await confirm(
      'Cancelar esta carona?',
      'A ${ride.direction.label.toLowerCase()} de ${relativeDayLong(ride.date).toLowerCase()} às ${ride.departureTime} '
          'será cancelada para todos os passageiros. A rota continua valendo nos outros dias.',
      confirmLabel: 'Cancelar carona',
      destructive: true,
    );
    if (ok) await _run(ride, () => _api.cancelRide(ride.id), 'Carona cancelada.');
  }

  Future<void> _run(Ride ride, Future<void> Function() action, String success) async {
    processing.add(ride.id);
    try {
      await action();
      showMessage(success);
      await load();
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      processing.remove(ride.id);
    }
  }
}
