import 'dart:async';

import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';

class TripDetailArgs {
  final Ride ride;

  /// Vaga do passageiro; nula quando quem abre é o motorista.
  final Booking? booking;

  const TripDetailArgs({required this.ride, this.booking});
}

/// Detalhes de uma carona já marcada, para o passageiro (com a vaga) ou para o motorista.
/// Devolve `true` no `Get.back` quando a vaga ou a carona foi cancelada, para a lista recarregar.
class TripDetailController extends GetxController {
  final TripDetailArgs args;
  final CaronaApi _api = Get.find();
  final AuthService _auth = Get.find();

  final passengers = <RidePassenger>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final busy = false.obs;

  /// Hora atual, atualizada a cada 30 s para a contagem "Partida em X min".
  final now = DateTime.now().obs;
  Timer? _clock;

  TripDetailController(this.args);

  Ride get ride => args.ride;
  Booking? get booking => args.booking;
  int get myId => _auth.currentUser.id;
  bool get isDriver => ride.driver.id == myId;

  bool get canCancel {
    if (ride.status != RideStatus.scheduled || !ride.departure.isAfter(now.value)) return false;
    return isDriver || booking?.status == BookingStatus.confirmed;
  }

  /// "Partida em 12 min", "Partida hoje às 18:00", "Saiu às 07:30"...
  String get headline {
    if (ride.status == RideStatus.cancelled) return 'Carona cancelada';
    if (ride.status == RideStatus.completed) return 'Viagem concluída';
    final minutes = ride.departure.difference(now.value).inMinutes;
    if (!ride.departure.isAfter(now.value)) return 'Saiu às ${ride.departureTime}';
    if (minutes < 1) return 'Partida agora';
    if (minutes < 60) return 'Partida em $minutes min';
    return 'Partida ${relativeDayLong(ride.date).toLowerCase()} às ${ride.departureTime}';
  }

  /// Minutos estimados da saída do motorista até o ponto de embarque, proporcionais ao trajeto.
  int? get pickupMinutes {
    final pickup = booking?.pickup;
    if (pickup == null) return null;
    final toPickup = GeoEstimate.distanceMeters(ride.from, pickup);
    final rest = GeoEstimate.distanceMeters(pickup, ride.to);
    if (toPickup + rest == 0) return 0;
    final total = ride.estimatedArrivalTime.totalMinutes - ride.departureTime.totalMinutes;
    return (total * toPickup / (toPickup + rest)).round();
  }

  ClockTime? get pickupTime {
    final minutes = pickupMinutes;
    if (minutes == null) return null;
    final t = ride.departureTime.totalMinutes + minutes;
    return ClockTime((t ~/ 60) % 24, t % 60);
  }

  @override
  void onInit() {
    super.onInit();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) => now.value = DateTime.now());
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      passengers.assignAll(await _api.ridePassengers(ride.id));
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
    }
  }

  void message(Person person) => Get.toNamed(Routes.chat, arguments: person);

  Future<void> cancel() async {
    if (busy.value) return;
    final day = relativeDayLong(ride.date).toLowerCase();
    final ok = isDriver
        ? await confirm(
            'Cancelar esta carona?',
            'A ${ride.direction.label.toLowerCase()} de $day às ${ride.departureTime} será cancelada para todos '
                'os passageiros. A rota continua valendo nos outros dias.',
            confirmLabel: 'Cancelar carona',
            destructive: true,
          )
        : await confirm(
            'Cancelar reserva?',
            'Sua vaga de $day às ${ride.departureTime} será liberada. '
                'Se o pedido for semanal, os outros dias continuam reservados.',
            confirmLabel: 'Cancelar reserva',
            destructive: true,
          );
    if (!ok) return;

    busy.value = true;
    try {
      if (isDriver) {
        await _api.cancelRide(ride.id);
      } else {
        await _api.cancelBooking(booking!.id);
      }
      Get.back(result: true);
      showMessage(isDriver ? 'Carona cancelada.' : 'Reserva cancelada.');
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      busy.value = false;
    }
  }

  @override
  void onClose() {
    _clock?.cancel();
    super.onClose();
  }
}
