import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../services/ride_tracking.dart';
import '../../theme.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';

class TripDetailArgs {
  final Ride ride;

  /// Vaga do passageiro; nula quando quem abre é o motorista.
  final Booking? booking;

  const TripDetailArgs({required this.ride, this.booking});
}

/// Detalhes de uma carona marcada, para o passageiro (com a vaga) ou para o motorista.
///
/// O passageiro confirma a presença, vê o código de embarque e acompanha o carro no mapa.
/// O motorista compartilha a posição, confere os códigos de embarque e conclui a viagem.
/// Quem abre a tela recarrega a lista ao voltar, porque quase tudo aqui muda a vaga ou a carona.
class TripDetailController extends GetxController {
  /// Iguais a `app.rides.tracking-*` no backend: a viagem "está acontecendo" de 30 min antes da saída até 6 h depois.
  static const trackingStartsBefore = Duration(minutes: 30);
  static const trackingMaxDuration = Duration(hours: 6);

  final TripDetailArgs args;
  final CaronaApi _api = Get.find();
  final AuthService _auth = Get.find();

  late final Rx<Ride> _ride = args.ride.obs;
  late final Rxn<Booking> _booking = Rxn(args.booking);
  final passengers = <RidePassenger>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final busy = false.obs;

  /// Hora atual, atualizada a cada 30 s para a contagem "Partida em X min".
  final now = DateTime.now().obs;
  Timer? _clock;

  late final RideTracker _tracker = RideTracker(_api, args.ride.id);
  late final LocationSharer sharer = LocationSharer(_api, args.ride.id);
  bool _tracking = false;

  TripDetailController(this.args);

  Ride get ride => _ride.value;
  Booking? get booking => _booking.value;
  BookingStage? get stage => booking?.stage;
  int get myId => _auth.currentUser.id;
  bool get isDriver => ride.driver.id == myId;
  VehicleLocation? get vehicle => _tracker.location.value;

  /// Entre pouco antes da saída e algumas horas depois, com a carona ainda agendada.
  bool get inTripWindow {
    if (ride.status != RideStatus.scheduled) return false;
    final t = now.value;
    return !t.isBefore(ride.departure.subtract(trackingStartsBefore)) &&
        t.isBefore(ride.departure.add(trackingMaxDuration));
  }

  /// O passageiro só acompanha o carro e vê os outros depois de confirmar que vai.
  bool get canSeeTrip => isDriver || (booking?.canTrack ?? false);

  bool get canConfirm => stage == BookingStage.awaitingConfirmation;

  bool get canCancel {
    if (ride.status != RideStatus.scheduled || !ride.departure.isAfter(now.value)) return false;
    if (isDriver) return true;
    return stage == BookingStage.reserved ||
        stage == BookingStage.awaitingConfirmation ||
        stage == BookingStage.confirmed;
  }

  bool get canComplete => isDriver && ride.status == RideStatus.scheduled && !ride.departure.isAfter(now.value);

  bool get canBoard => isDriver && inTripWindow;

  int get boardedCount => passengers.where((p) => p.stage == BookingStage.boarded).length;

  /// "Partida em 12 min", "Em viagem", "Você não embarcou"...
  String get headline {
    if (!isDriver) {
      switch (stage) {
        case BookingStage.rideCancelled:
          return 'Carona cancelada';
        case BookingStage.cancelled:
          return 'Você não vai nessa carona';
        case BookingStage.notConfirmed:
          return 'Presença não confirmada';
        case BookingStage.noShow:
          return 'Você não embarcou';
        case BookingStage.completed:
          return 'Viagem concluída';
        case BookingStage.boarded:
          return 'Em viagem';
        default:
          break;
      }
    }
    if (ride.status == RideStatus.cancelled) return 'Carona cancelada';
    if (ride.status == RideStatus.completed) return 'Viagem concluída';
    final minutes = ride.departure.difference(now.value).inMinutes;
    if (!ride.departure.isAfter(now.value)) return isDriver ? 'Em viagem' : 'Saiu às ${ride.departureTime}';
    if (minutes < 1) return 'Partida agora';
    if (minutes < 60) return 'Partida em $minutes min';
    return 'Partida ${relativeDayLong(ride.date).toLowerCase()} às ${ride.departureTime}';
  }

  /// Explica o que o passageiro precisa fazer (ou o que aconteceu com a vaga).
  String? get presenceHint {
    final b = booking;
    if (b == null) return null;
    final deadline = formatClock(b.confirmationDeadline);
    return switch (b.stage) {
      BookingStage.reserved =>
        'Confirme sua presença a partir de ${formatClock(b.confirmationOpensAt)}, até $deadline. Quem não confirma perde a vaga.',
      BookingStage.awaitingConfirmation => 'Confirme até $deadline se você vai. Sem confirmação, a vaga é liberada.',
      BookingStage.notConfirmed => 'Você não confirmou a presença até $deadline e a vaga foi liberada.',
      BookingStage.noShow => 'O motorista concluiu a viagem sem registrar o seu embarque.',
      _ => null,
    };
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

  /// "Motorista a 1,2 km do seu ponto · atualizado há 10 s".
  String? get vehicleSummary {
    final v = vehicle;
    if (v == null) return null;
    final seconds = now.value.difference(v.updatedAt).inSeconds;
    final age = seconds < 60 ? 'agora há pouco' : 'há ${seconds ~/ 60} min';
    final pickup = booking?.pickup;
    if (pickup == null || stage == BookingStage.boarded) return 'Posição do carro atualizada $age';
    final meters = GeoEstimate.distanceMeters(
      Place(label: '', latitude: v.position.latitude, longitude: v.position.longitude),
      pickup,
    ).round();
    return 'Motorista a ${formatDistance(meters)} do seu ponto · atualizado $age';
  }

  @override
  void onInit() {
    super.onInit();
    _clock = Timer.periodic(const Duration(seconds: 15), (_) {
      now.value = DateTime.now();
      _syncTracking();
    });
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = null;
    try {
      if (isDriver) {
        _ride.value = await _api.ride(ride.id);
      } else if (booking != null) {
        final fresh = (await _api.myBookings()).firstWhereOrNull((b) => b.id == booking!.id);
        if (fresh != null) {
          _booking.value = fresh;
          _ride.value = fresh.ride;
        }
      }
      if (canSeeTrip) {
        passengers.assignAll(await _api.ridePassengers(ride.id));
      } else {
        passengers.clear();
      }
    } catch (e) {
      error.value = errorMessage(e);
    } finally {
      loading.value = false;
      _syncTracking();
    }
  }

  /// Liga o acompanhamento do carro quando a viagem está acontecendo (e desliga quando acaba).
  void _syncTracking() {
    final shouldTrack = canSeeTrip && inTripWindow;
    if (shouldTrack && !_tracking) {
      _tracking = true;
      _tracker.start();
    } else if (!shouldTrack && _tracking) {
      _tracking = false;
      _tracker.stop();
      if (sharer.sharing.value) sharer.stop();
    }
  }

  void message(Person person) => Get.toNamed(Routes.chat, arguments: person);

  // Passageiro

  Future<void> confirmPresence() async {
    final b = booking;
    if (b == null || busy.value) return;
    busy.value = true;
    try {
      final updated = await _api.confirmBooking(b.id);
      _booking.value = updated;
      _ride.value = updated.ride;
      showMessage('Presença confirmada! Mostre o código ao motorista no embarque.');
      await load();
    } catch (e) {
      showMessage(errorMessage(e), error: true);
      await load();
    } finally {
      busy.value = false;
    }
  }

  // Motorista

  Future<void> toggleSharing() async {
    if (sharer.sharing.value) {
      sharer.stop();
      return;
    }
    if (!await sharer.start()) showMessage(sharer.error.value ?? 'Não foi possível compartilhar a localização.', error: true);
  }

  /// Pede o código de 4 dígitos que o passageiro mostra no app dele.
  Future<void> board() async {
    final code = await Get.dialog<String>(const _BoardingCodeDialog());
    if (code == null || code.length != 4) return;
    busy.value = true;
    try {
      final passenger = await _api.board(ride.id, code);
      showMessage('${passenger.passenger.firstName} embarcou!');
      await load();
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      busy.value = false;
    }
  }

  Future<void> complete() async {
    final waiting = passengers.where((p) => p.stage == BookingStage.confirmed).length;
    final ok = await confirm(
      'Concluir viagem?',
      waiting == 0
          ? 'A viagem vai para os recebimentos com os passageiros que embarcaram.'
          : waiting == 1
          ? '1 passageiro não teve o embarque registrado e vai aparecer como "não embarcou". '
                'Só quem embarcou conta nos recebimentos.'
          : '$waiting passageiros não tiveram o embarque registrado e vão aparecer como "não embarcou". '
                'Só quem embarcou conta nos recebimentos.',
      confirmLabel: 'Concluir',
    );
    if (!ok) return;
    busy.value = true;
    try {
      _ride.value = await _api.completeRide(ride.id);
      sharer.stop();
      showMessage('Viagem concluída!');
      await load();
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      busy.value = false;
    }
  }

  // Os dois

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
            'Não vai nessa carona?',
            'Sua vaga de $day às ${ride.departureTime} será liberada. '
                'Se o pedido for semanal, os outros dias continuam reservados.',
            confirmLabel: 'Não vou',
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
      showMessage(isDriver ? 'Carona cancelada.' : 'Vaga liberada.');
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      busy.value = false;
    }
  }

  @override
  void onClose() {
    _clock?.cancel();
    _tracker.stop();
    sharer.stop();
    super.onClose();
  }
}

class _BoardingCodeDialog extends StatefulWidget {
  const _BoardingCodeDialog();

  @override
  State<_BoardingCodeDialog> createState() => _BoardingCodeDialogState();
}

class _BoardingCodeDialogState extends State<_BoardingCodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_code.text.length == 4) Get.back(result: _code.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Código de embarque'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Peça ao passageiro o código de 4 dígitos que aparece no app dele.', style: mutedStyle),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: 12),
            decoration: const InputDecoration(counterText: '', hintText: '0000'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Voltar')),
        TextButton(
          onPressed: _code.text.length == 4 ? _submit : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          child: const Text('Confirmar embarque'),
        ),
      ],
    );
  }
}
