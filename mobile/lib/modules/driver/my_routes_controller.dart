import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../ui/ui.dart';

class MyRoutesController extends GetxController {
  final CaronaApi _api = Get.find();

  final routes = <DriverRoute>[].obs;
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
      final list = await _api.myRoutes();
      // Ativas primeiro.
      list.sort((a, b) => (b.active ? 1 : 0).compareTo(a.active ? 1 : 0));
      routes.assignAll(list);
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> newRoute() async {
    if (await Get.toNamed(Routes.newRoute) == true) load();
  }

  Future<void> deactivate(DriverRoute route) async {
    final ok = await confirm(
      'Desativar rota?',
      'As próximas caronas de ${route.origin.label} → ${route.destination.label} deixam de aparecer na busca.',
      confirmLabel: 'Desativar',
      destructive: true,
    );
    if (!ok) return;
    try {
      await _api.deactivateRoute(route.id);
      showMessage('Rota desativada.');
      await load();
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    }
  }
}
