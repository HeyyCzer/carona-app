import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../services/auth_service.dart';
import '../../utils/format.dart';

/// Recebimentos por semana (segunda a domingo), navegando entre semanas.
class EarningsController extends GetxController {
  final CaronaApi _api = Get.find();

  late final weekStart = _monday(today()).obs;
  final earnings = Rxn<Earnings>();
  final loading = false.obs;
  final error = RxnString();

  static DateTime _monday(DateTime d) => d.subtract(Duration(days: d.weekday - 1));

  DateTime get weekEnd => weekStart.value.add(const Duration(days: 6));

  bool get isCurrentWeek => isSameDay(weekStart.value, _monday(today()));

  @override
  void onInit() {
    super.onInit();
    ever(weekStart, (_) => load());
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      earnings.value = await _api.earnings(from: weekStart.value, to: weekEnd);
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  void previousWeek() => weekStart.value = weekStart.value.subtract(const Duration(days: 7));

  void nextWeek() {
    if (!isCurrentWeek) weekStart.value = weekStart.value.add(const Duration(days: 7));
  }
}
