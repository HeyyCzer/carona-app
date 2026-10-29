// Modelos espelhando os DTOs do backend (controllers/dto).

import 'package:latlong2/latlong.dart';

import '../utils/polyline.dart';

/// Hora do dia sem data, serializada como "HH:mm" (o backend responde "HH:mm:ss").
class ClockTime implements Comparable<ClockTime> {
  final int hour;
  final int minute;

  const ClockTime(this.hour, this.minute);

  factory ClockTime.parse(String value) {
    final parts = value.split(':');
    return ClockTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  int get totalMinutes => hour * 60 + minute;

  String toJson() => format();

  String format() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  DateTime on(DateTime date) => DateTime(date.year, date.month, date.day, hour, minute);

  @override
  int compareTo(ClockTime other) => totalMinutes.compareTo(other.totalMinutes);

  @override
  String toString() => format();
}

/// Data sem hora, serializada como "yyyy-MM-dd".
DateTime parseDate(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

String formatIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Dias da semana no formato do java.time.DayOfWeek.
enum Weekday {
  monday('MONDAY', 'Seg', 'Segunda'),
  tuesday('TUESDAY', 'Ter', 'Terça'),
  wednesday('WEDNESDAY', 'Qua', 'Quarta'),
  thursday('THURSDAY', 'Qui', 'Quinta'),
  friday('FRIDAY', 'Sex', 'Sexta'),
  saturday('SATURDAY', 'Sáb', 'Sábado'),
  sunday('SUNDAY', 'Dom', 'Domingo');

  final String api;
  final String short;
  final String long;

  const Weekday(this.api, this.short, this.long);

  static Weekday fromApi(String value) => values.firstWhere((d) => d.api == value);

  /// DateTime.weekday vai de 1 (segunda) a 7 (domingo).
  static Weekday fromDate(DateTime date) => values[date.weekday - 1];
}

enum RideDirection {
  outbound('OUTBOUND', 'Ida'),
  returning('RETURN', 'Volta');

  final String api;
  final String label;

  const RideDirection(this.api, this.label);

  static RideDirection fromApi(String value) => values.firstWhere((d) => d.api == value);
}

enum RideStatus { scheduled, cancelled, completed }

enum RideRequestStatus { pending, accepted, rejected, cancelled }

enum BookingStatus { confirmed, cancelled }

T _enumByName<T extends Enum>(List<T> values, String name) =>
    values.firstWhere((v) => v.name.toUpperCase() == name);

class User {
  final int id;
  final String name;
  final String email;
  final Set<String> permissions;

  const User({required this.id, required this.name, required this.email, required this.permissions});

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        permissions: Set<String>.from(json['permissions'] ?? const []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'permissions': permissions.toList(),
      };
}

class AuthResponse {
  final String accessToken;
  final int expiresIn;
  final User user;

  const AuthResponse({required this.accessToken, required this.expiresIn, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'],
        expiresIn: json['expiresIn'],
        user: User.fromJson(json['user']),
      );
}

class Person {
  final int id;
  final String name;

  const Person({required this.id, required this.name});

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory Person.fromJson(Map<String, dynamic> json) => Person(id: json['id'], name: json['name']);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class Place {
  final String label;
  final double latitude;
  final double longitude;

  const Place({required this.label, required this.latitude, required this.longitude});

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        label: json['label'],
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'label': label, 'latitude': latitude, 'longitude': longitude};

  Place withLabel(String label) => Place(label: label, latitude: latitude, longitude: longitude);

  @override
  bool operator ==(Object other) =>
      other is Place && other.label == label && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(label, latitude, longitude);
}

class Ride {
  final int id;
  final int routeId;
  final RideDirection direction;
  final DateTime date;
  final ClockTime departureTime;
  final ClockTime estimatedArrivalTime;
  final RideStatus status;
  final int distanceMeters;

  /// Trajeto pelas ruas (ou a linha reta, se o backend não conseguiu calcular).
  final List<LatLng> path;
  final Place from;
  final Place to;
  final Person driver;
  final int priceCents;
  final int seats;
  final int seatsAvailable;

  const Ride({
    required this.id,
    required this.routeId,
    required this.direction,
    required this.date,
    required this.departureTime,
    required this.estimatedArrivalTime,
    required this.status,
    required this.distanceMeters,
    required this.path,
    required this.from,
    required this.to,
    required this.driver,
    required this.priceCents,
    required this.seats,
    required this.seatsAvailable,
  });

  DateTime get departure => departureTime.on(date);

  bool get hasDeparted => !departure.isAfter(DateTime.now());

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
        id: json['id'],
        routeId: json['routeId'],
        direction: RideDirection.fromApi(json['direction']),
        date: parseDate(json['date']),
        departureTime: ClockTime.parse(json['departureTime']),
        estimatedArrivalTime: ClockTime.parse(json['estimatedArrivalTime']),
        status: _enumByName(RideStatus.values, json['status']),
        distanceMeters: json['distanceMeters'],
        path: decodePolyline(json['path']),
        from: Place.fromJson(json['from']),
        to: Place.fromJson(json['to']),
        driver: Person.fromJson(json['driver']),
        priceCents: json['priceCents'],
        seats: json['seats'],
        seatsAvailable: json['seatsAvailable'],
      );
}

class RideSearchResult {
  final Ride ride;
  final int distanceFromYouMeters;
  final Place pickupPoint;
  final ClockTime estimatedPickupTime;

  const RideSearchResult({
    required this.ride,
    required this.distanceFromYouMeters,
    required this.pickupPoint,
    required this.estimatedPickupTime,
  });

  factory RideSearchResult.fromJson(Map<String, dynamic> json) => RideSearchResult(
        ride: Ride.fromJson(json['ride']),
        distanceFromYouMeters: json['distanceFromYouMeters'],
        pickupPoint: Place.fromJson(json['pickupPoint']),
        estimatedPickupTime: ClockTime.parse(json['estimatedPickupTime']),
      );
}

class RideRequest {
  final int id;
  final Ride ride;
  final Person passenger;
  final bool recurring;
  final List<Weekday> weekdays;
  final Place pickup;
  final int detourMeters;
  final int detourMinutes;
  final RideRequestStatus status;
  final DateTime createdAt;

  const RideRequest({
    required this.id,
    required this.ride,
    required this.passenger,
    required this.recurring,
    required this.weekdays,
    required this.pickup,
    required this.detourMeters,
    required this.detourMinutes,
    required this.status,
    required this.createdAt,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) => RideRequest(
        id: json['id'],
        ride: Ride.fromJson(json['ride']),
        passenger: Person.fromJson(json['passenger']),
        recurring: json['recurring'],
        weekdays: (json['weekdays'] as List).map((d) => Weekday.fromApi(d)).toList(),
        pickup: Place.fromJson(json['pickup']),
        detourMeters: json['detourMeters'],
        detourMinutes: json['detourMinutes'],
        status: _enumByName(RideRequestStatus.values, json['status']),
        createdAt: DateTime.parse(json['createdAt']).toLocal(),
      );
}

class Booking {
  final int id;
  final int requestId;
  final Ride ride;
  final Place pickup;
  final int priceCents;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.requestId,
    required this.ride,
    required this.pickup,
    required this.priceCents,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'],
        requestId: json['requestId'],
        ride: Ride.fromJson(json['ride']),
        pickup: Place.fromJson(json['pickup']),
        priceCents: json['priceCents'],
        status: _enumByName(BookingStatus.values, json['status']),
      );
}

class DriverRoute {
  final int id;
  final Place origin;
  final Place destination;
  final int distanceMeters;
  final List<Weekday> weekdays;
  final ClockTime outboundTime;
  final ClockTime? returnTime;
  final int maxDetourMeters;
  final int maxDetourMinutes;
  final int seats;
  final int priceCents;
  final bool active;

  const DriverRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.weekdays,
    required this.outboundTime,
    required this.returnTime,
    required this.maxDetourMeters,
    required this.maxDetourMinutes,
    required this.seats,
    required this.priceCents,
    required this.active,
  });

  factory DriverRoute.fromJson(Map<String, dynamic> json) => DriverRoute(
        id: json['id'],
        origin: Place.fromJson(json['origin']),
        destination: Place.fromJson(json['destination']),
        distanceMeters: json['distanceMeters'],
        weekdays: (json['weekdays'] as List).map((d) => Weekday.fromApi(d)).toList(),
        outboundTime: ClockTime.parse(json['outboundTime']),
        returnTime: json['returnTime'] == null ? null : ClockTime.parse(json['returnTime']),
        maxDetourMeters: json['maxDetourMeters'],
        maxDetourMinutes: json['maxDetourMinutes'],
        seats: json['seats'],
        priceCents: json['priceCents'],
        active: json['active'],
      );
}

/// Distância, tempo e trajeto da ida antes de publicar a rota.
class RoutePreview {
  final int distanceMeters;
  final int durationMinutes;
  final List<LatLng> path;

  /// Falso quando o backend não conseguiu o trajeto pelas ruas e [path] é a linha reta.
  final bool followsRoads;

  const RoutePreview({
    required this.distanceMeters,
    required this.durationMinutes,
    required this.path,
    required this.followsRoads,
  });

  factory RoutePreview.fromJson(Map<String, dynamic> json) => RoutePreview(
        distanceMeters: json['distanceMeters'],
        durationMinutes: json['durationMinutes'],
        path: decodePolyline(json['path']),
        followsRoads: json['followsRoads'],
      );
}

class NewRoute {
  final Place origin;
  final Place destination;
  final Set<Weekday> weekdays;
  final ClockTime outboundTime;
  final ClockTime? returnTime;
  final int maxDetourMeters;
  final int seats;
  final int priceCents;

  const NewRoute({
    required this.origin,
    required this.destination,
    required this.weekdays,
    required this.outboundTime,
    required this.returnTime,
    required this.maxDetourMeters,
    required this.seats,
    required this.priceCents,
  });

  Map<String, dynamic> toJson() => {
        'origin': origin.toJson(),
        'destination': destination.toJson(),
        'weekdays': weekdays.map((d) => d.api).toList(),
        'outboundTime': outboundTime.toJson(),
        'returnTime': returnTime?.toJson(),
        'maxDetourMeters': maxDetourMeters,
        'seats': seats,
        'priceCents': priceCents,
      };
}

class EarningsRide {
  final int rideId;
  final DateTime date;
  final RideDirection direction;
  final int passengers;
  final int totalCents;

  const EarningsRide({
    required this.rideId,
    required this.date,
    required this.direction,
    required this.passengers,
    required this.totalCents,
  });

  factory EarningsRide.fromJson(Map<String, dynamic> json) => EarningsRide(
        rideId: json['rideId'],
        date: parseDate(json['date']),
        direction: RideDirection.fromApi(json['direction']),
        passengers: json['passengers'],
        totalCents: json['totalCents'],
      );
}

class Earnings {
  final DateTime from;
  final DateTime to;
  final int totalCents;
  final int ridesCount;
  final int passengersCount;
  final List<EarningsRide> rides;

  const Earnings({
    required this.from,
    required this.to,
    required this.totalCents,
    required this.ridesCount,
    required this.passengersCount,
    required this.rides,
  });

  factory Earnings.fromJson(Map<String, dynamic> json) => Earnings(
        from: parseDate(json['from']),
        to: parseDate(json['to']),
        totalCents: json['totalCents'],
        ridesCount: json['ridesCount'],
        passengersCount: json['passengersCount'],
        rides: (json['rides'] as List).map((r) => EarningsRide.fromJson(r)).toList(),
      );
}
