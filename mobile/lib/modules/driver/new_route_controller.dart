import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../api/carona_api.dart';
import '../../api/models.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../services/places_service.dart';
import '../../ui/ui.dart';
import '../../utils/format.dart';
import '../places/place_picker_controller.dart';

class NewRouteController extends GetxController {
  final CaronaApi _api = Get.find();
  final PlacesService _places = Get.find();

  static const maxDetour = 1000;
  static const maxSeats = 8;
  static const maxPriceCents = 100_00;

  final origin = Rxn<Place>();
  final destination = Rxn<Place>();
  final weekdays = <Weekday>{Weekday.monday, Weekday.wednesday, Weekday.friday}.obs;
  final outboundTime = const ClockTime(7, 0).obs;
  final returnTime = Rxn<ClockTime>(const ClockTime(22, 30));
  final detourMeters = 300.obs;
  final seats = 3.obs;
  final priceCents = 600.obs;
  final saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Começa com o trajeto da última busca, que costuma ser o mesmo do motorista.
    origin.value = _places.origin.value;
    destination.value = _places.destination.value;
  }

  int? get roadDistance {
    final o = origin.value, d = destination.value;
    return o == null || d == null ? null : GeoEstimate.roadDistanceMeters(o, d);
  }

  int get detourMinutes => GeoEstimate.travelMinutes(detourMeters.value);

  /// Faixa sugerida: divisão aproximada do combustível (~R$ 0,60 a 0,90 por km), mínimo de R$ 2.
  (int, int)? get suggestedPrice {
    final meters = roadDistance;
    if (meters == null) return null;
    int round(double cents) => ((cents / 50).round() * 50).clamp(200, maxPriceCents);
    final km = meters / 1000;
    return (round(km * 60), round(km * 90));
  }

  String? get validationError {
    if (origin.value == null || destination.value == null) return 'Escolha a origem e o destino.';
    if (origin.value == destination.value) return 'A origem e o destino precisam ser diferentes.';
    if (weekdays.isEmpty) return 'Escolha pelo menos um dia da semana.';
    return null;
  }

  void toggleDay(Weekday day) => weekdays.contains(day) ? weekdays.remove(day) : weekdays.add(day);

  Future<void> pickOrigin() async {
    final place = await Get.toNamed(Routes.placePicker,
        arguments: PlacePickerArgs(title: 'Saída da ida', initial: origin.value));
    if (place is Place) {
      origin.value = place;
      _places.remember(place);
    }
  }

  Future<void> pickDestination() async {
    final place = await Get.toNamed(Routes.placePicker,
        arguments: PlacePickerArgs(title: 'Destino da ida', initial: destination.value));
    if (place is Place) {
      destination.value = place;
      _places.remember(place);
    }
  }

  Future<void> pickOutboundTime(BuildContext context) async {
    final t = await _pickTime(context, outboundTime.value);
    if (t != null) outboundTime.value = t;
  }

  Future<void> pickReturnTime(BuildContext context) async {
    final t = await _pickTime(context, returnTime.value ?? const ClockTime(18, 0));
    if (t != null) returnTime.value = t;
  }

  Future<ClockTime?> _pickTime(BuildContext context, ClockTime initial) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      builder: (context, child) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    return picked == null ? null : ClockTime(picked.hour, picked.minute);
  }

  Future<void> editPrice() async {
    final field = TextEditingController(text: (priceCents.value / 100).toStringAsFixed(2).replaceAll('.', ','));
    final result = await Get.dialog<int>(AlertDialog(
      title: const Text('Valor por trecho'),
      content: TextField(
        controller: field,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(prefixText: 'R\$ '),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            final value = double.tryParse(field.text.replaceAll('.', '').replaceAll(',', '.'));
            if (value == null || value < 0 || value * 100 > maxPriceCents) {
              showMessage('Informe um valor entre R\$ 0 e R\$ 100.', error: true);
              return;
            }
            Get.back(result: (value * 100).round());
          },
          child: const Text('Salvar'),
        ),
      ],
    ));
    if (result != null) priceCents.value = result;
  }

  Future<void> publish() async {
    final error = validationError;
    if (error != null) {
      showMessage(error, error: true);
      return;
    }
    saving.value = true;
    try {
      await _api.createRoute(NewRoute(
        origin: origin.value!,
        destination: destination.value!,
        weekdays: weekdays.toSet(),
        outboundTime: outboundTime.value,
        returnTime: returnTime.value,
        maxDetourMeters: detourMeters.value,
        seats: seats.value,
        priceCents: priceCents.value,
      ));
      Get.back(result: true);
      showMessage('Rota publicada! Os passageiros já podem encontrar suas caronas.');
    } catch (e) {
      showMessage(errorMessage(e), error: true);
    } finally {
      saving.value = false;
    }
  }
}
