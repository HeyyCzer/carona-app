import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../services/messages_service.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import '../home/home_controller.dart';
import '../places/pickup_map_view.dart';
import '../rides/trip_detail_controller.dart';

/// Linha da lista "Próximas caronas": uma vaga confirmada/cancelada ou um pedido aguardando resposta.
class UpcomingItem {
  final Ride ride;
  final Booking? booking;
  final RideRequest? request;

  UpcomingItem.booking(Booking this.booking)
      : ride = booking.ride,
        request = null;

  UpcomingItem.request(RideRequest this.request)
      : ride = request.ride,
        booking = null;

  bool get isPending => request != null;
  bool get isConfirmed => booking?.status == BookingStatus.confirmed;
  int get priceCents => booking?.priceCents ?? ride.priceCents;
}

class MyRidesController extends GetxController {
  final CaronaApi _api = Get.find();
  final MessagesService _messages = Get.find();

  final items = <UpcomingItem>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final busy = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
    // Recarrega ao entrar na aba "Caronas".
    ever(Get.find<HomeController>().tab, (HomeTab tab) {
      if (tab == HomeTab.rides) load();
    });
  }

  /// Próxima vaga confirmada que ainda não saiu.
  UpcomingItem? get next => items.firstWhereOrNull((i) => i.isConfirmed && !i.ride.hasDeparted);

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      final results = await Future.wait([_api.myBookings(), _api.myRequests()]);
      final bookings = results[0] as List<Booking>;
      final requests = results[1] as List<RideRequest>;
      final start = today();

      final list = [
        ...bookings.map(UpcomingItem.booking),
        ...requests
            .where((r) => r.status == RideRequestStatus.pending && !r.ride.date.isBefore(start))
            .map(UpcomingItem.request),
      ]..sort((a, b) => a.ride.departure.compareTo(b.ride.departure));
      items.assignAll(list);

      _messages.addContacts([...bookings.map((b) => b.ride.driver), ...requests.map((r) => r.ride.driver)]);
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  /// Só quem tem vaga confirmada vê os outros passageiros.
  bool canOpenDetails(UpcomingItem item) => item.isConfirmed;

  Future<void> openDetails(UpcomingItem item) async {
    final changed = await Get.toNamed(
      Routes.tripDetail,
      arguments: TripDetailArgs(ride: item.ride, booking: item.booking),
    );
    if (changed == true) load();
  }

  void message(Ride ride) => Get.toNamed(Routes.chat, arguments: ride.driver);

  void showPickup(UpcomingItem item) {
    final pickup = item.booking?.pickup ?? item.request!.pickup;
    Get.toNamed(
      Routes.pickupMap,
      arguments: PickupMapArgs(
        pickup: pickup,
        from: item.ride.from,
        to: item.ride.to,
        path: item.ride.path,
        subtitle: '${relativeDayLong(item.ride.date)} · ${item.ride.driver.firstName} sai às ${item.ride.departureTime}',
      ),
    );
  }

  /// "Não vou": libera a vaga de um dia sem cancelar o pedido recorrente.
  Future<void> skip(Booking booking) async {
    final ok = await confirm(
      'Não vai nessa carona?',
      'Sua vaga de ${relativeDayLong(booking.ride.date).toLowerCase()} às ${booking.ride.departureTime} será liberada. '
          'Se o pedido for semanal, os outros dias continuam reservados.',
      confirmLabel: 'Liberar vaga',
      destructive: true,
    );
    if (!ok) return;
    await _run(() => _api.cancelBooking(booking.id), 'Vaga liberada.');
  }

  Future<void> cancelRequest(RideRequest request) async {
    final ok = await confirm(
      'Cancelar pedido?',
      'O pedido para a carona de ${request.ride.driver.firstName} será cancelado.',
      confirmLabel: 'Cancelar pedido',
      destructive: true,
    );
    if (!ok) return;
    await _run(() => _api.cancelRequest(request.id), 'Pedido cancelado.');
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    busy.value = true;
    try {
      await action();
      showMessage(success);
      await load();
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      busy.value = false;
    }
  }
}
