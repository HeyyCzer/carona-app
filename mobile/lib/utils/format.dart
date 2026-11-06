import 'dart:math';

import 'package:intl/intl.dart';

import '../api/models.dart';

final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

/// "R$ 6,00"
String formatMoney(int cents) => _currency.format(cents / 100);

/// "R$ 6" quando não há centavos, "R$ 9,60" caso contrário (como nos cards do protótipo).
String formatMoneyShort(int cents) =>
    cents % 100 == 0 ? 'R\$ ${cents ~/ 100}' : formatMoney(cents);

/// "180 m" / "8,4 km"
String formatDistance(int meters) {
  if (meters < 1000) return '$meters m';
  return '${NumberFormat('#,##0.0', 'pt_BR').format(meters / 1000)} km';
}

DateTime today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "Hoje", "Amanhã" ou "Seg 26".
String relativeDayLabel(DateTime date) {
  final t = today();
  if (isSameDay(date, t)) return 'Hoje';
  if (isSameDay(date, t.add(const Duration(days: 1)))) return 'Amanhã';
  return '${Weekday.fromDate(date).short} ${date.day}';
}

/// "Hoje", "Amanhã" ou "Seg, 26/10".
String relativeDayLong(DateTime date) {
  final label = relativeDayLabel(date);
  if (label == 'Hoje' || label == 'Amanhã') return label;
  return '${Weekday.fromDate(date).short}, ${DateFormat('dd/MM').format(date)}';
}

/// "nov", "dez"...
String monthShort(DateTime date) => DateFormat('MMM', 'pt_BR').format(date).replaceAll('.', '');

/// "Seg, Qua e Sex"
String formatWeekdays(Iterable<Weekday> days) {
  final sorted = days.toList()..sort((a, b) => a.index.compareTo(b.index));
  final names = sorted.map((d) => d.short).toList();
  if (names.length == 7) return 'Todos os dias';
  if (names.length <= 1) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, min(2, parts.first.length)).toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Mesmas estimativas que o backend usa sem o OSRM (utils/Geo.kt): linha reta × 1,3 e 25 km/h de média.
class GeoEstimate {
  static const _earthRadius = 6371000.0;
  static const _roadFactor = 1.3;
  static const _metersPerMinute = 25000.0 / 60;

  static double distanceMeters(Place a, Place b) {
    double rad(double deg) => deg * pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h = pow(sin(dLat / 2), 2) + cos(rad(a.latitude)) * cos(rad(b.latitude)) * pow(sin(dLng / 2), 2);
    return 2 * _earthRadius * asin(sqrt(h));
  }

  static int roadDistanceMeters(Place a, Place b) => (distanceMeters(a, b) * _roadFactor).round();

  static int travelMinutes(int roadMeters) => (roadMeters / _metersPerMinute).ceil();
}

/// "06:30" se for hoje; senão "amanhã às 06:30" ou "seg, 26/10 às 06:30".
String formatClock(DateTime dateTime) {
  final time = DateFormat('HH:mm').format(dateTime);
  if (isSameDay(dateTime, today())) return time;
  return '${relativeDayLong(dateTime).toLowerCase()} às $time';
}
