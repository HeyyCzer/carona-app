import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../services/places_service.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import '../places/place_picker_controller.dart';
import 'ride_detail_controller.dart';

class RideSearchController extends GetxController {
  final CaronaApi _api = Get.find();
  final AuthService auth = Get.find();
  final PlacesService places = Get.find();

  /// Hoje, amanhã e os dois dias seguintes.
  final days = List.generate(4, (i) => today().add(Duration(days: i)));
  final selectedDay = today().obs;

  final results = <RideSearchResult>[].obs;
  final loading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    everAll([places.origin, places.destination, selectedDay], (_) => search());
    search();
  }

  bool get canSearch => places.origin.value != null && places.destination.value != null;

  Future<void> search() async {
    final origin = places.origin.value, destination = places.destination.value;
    if (origin == null || destination == null) return;
    loading.value = true;
    error.value = null;
    try {
      results.assignAll(await _api.searchRides(origin: origin, destination: destination, date: selectedDay.value));
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  Future<void> useCurrentLocation() async {
    try {
      places.origin.value = await places.locate();
    } on LocationUnavailable catch (e) {
      showMessage(e.message, error: true);
    }
  }

  Future<void> pickOrigin() async {
    final place = await Get.toNamed(
      Routes.placePicker,
      arguments: PlacePickerArgs(title: 'Saindo de', initial: places.origin.value),
    );
    if (place is Place) places.setOrigin(place);
  }

  Future<void> pickDestination() async {
    final place = await Get.toNamed(
      Routes.placePicker,
      arguments: PlacePickerArgs(title: 'Indo para', initial: places.destination.value),
    );
    if (place is Place) places.setDestination(place);
  }

  void openRide(RideSearchResult result) => Get.toNamed(
        Routes.rideDetail,
        arguments: RideDetailArgs(result: result, passengerOrigin: places.origin.value!),
      );
}
