import 'package:carona_app/api/models.dart';
import 'package:carona_app/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('ClockTime', () {
    test('lê o formato do backend (HH:mm:ss) e envia HH:mm', () {
      final t = ClockTime.parse('07:05:00');
      expect(t.hour, 7);
      expect(t.minute, 5);
      expect(t.toJson(), '07:05');
    });
  });

  group('formatação', () {
    test('dinheiro', () {
      expect(formatMoney(600).replaceAll(' ', ' '), 'R\$ 6,00');
      expect(formatMoneyShort(600), 'R\$ 6');
      expect(formatMoneyShort(960).replaceAll(' ', ' '), 'R\$ 9,60');
    });

    test('distância', () {
      expect(formatDistance(180), '180 m');
      expect(formatDistance(8400), '8,4 km');
    });

    test('dias da semana', () {
      expect(formatWeekdays([Weekday.friday, Weekday.monday, Weekday.wednesday]), 'Seg, Qua e Sex');
      expect(formatWeekdays(Weekday.values), 'Todos os dias');
    });

    test('iniciais', () {
      expect(initials('Murilo da Silva'), 'MS');
      expect(initials('Ana'), 'AN');
    });
  });

  test('estimativas iguais às do backend (Geo.kt)', () {
    const casa = Place(label: 'Casa', latitude: -20.8113, longitude: -49.3758);
    const unirp = Place(label: 'Unirp', latitude: -20.7850, longitude: -49.3600);
    // O backend respondeu distanceMeters = 4360 para esta mesma rota.
    expect(GeoEstimate.roadDistanceMeters(casa, unirp), 4360);
    expect(GeoEstimate.travelMinutes(300), 1);
  });

  test('converte a resposta da busca do backend', () {
    final result = RideSearchResult.fromJson({
      'ride': {
        'id': 28,
        'routeId': 3,
        'direction': 'OUTBOUND',
        'date': '2026-10-29',
        'departureTime': '07:00:00',
        'estimatedArrivalTime': '07:11:00',
        'status': 'SCHEDULED',
        'from': {'label': 'Casa', 'latitude': -20.8113, 'longitude': -49.3758},
        'to': {'label': 'Unirp - Unidade III', 'latitude': -20.785, 'longitude': -49.36},
        'driver': {'id': 3, 'name': 'Cauanny Silva'},
        'priceCents': 600,
        'seats': 3,
        'seatsAvailable': 3,
      },
      'distanceFromYouMeters': 45,
      'pickupPoint': {'label': 'Ponto de embarque', 'latitude': -20.79795, 'longitude': -49.36778},
      'estimatedPickupTime': '07:06:00',
    });
    expect(result.ride.direction, RideDirection.outbound);
    expect(result.ride.status, RideStatus.scheduled);
    expect(result.ride.date, DateTime(2026, 10, 29));
    expect(result.estimatedPickupTime.format(), '07:06');
    expect(result.ride.driver.firstName, 'Cauanny');
  });
}
