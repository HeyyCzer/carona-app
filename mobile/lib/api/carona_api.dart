import 'api_client.dart';
import 'models.dart';

/// Endpoints do backend (ver backend/backend/src/main/kotlin/.../controllers).
class CaronaApi {
  final ApiClient client;

  CaronaApi(this.client);

  // Usuário

  Future<AuthResponse> login(String email, String password) async =>
      AuthResponse.fromJson(await client.post('/login', body: {'email': email, 'password': password}));

  Future<AuthResponse> register(String name, String email, String password) async => AuthResponse.fromJson(
        await client.post('/register', body: {'name': name, 'email': email, 'password': password}),
      );

  Future<User> me() async => User.fromJson(await client.get('/me'));

  // Passageiro

  Future<List<RideSearchResult>> searchRides({
    required Place origin,
    required Place destination,
    DateTime? date,
  }) async {
    final json = await client.get('/rides/search', query: {
      'originLat': '${origin.latitude}',
      'originLng': '${origin.longitude}',
      'destinationLat': '${destination.latitude}',
      'destinationLng': '${destination.longitude}',
      'date': date == null ? null : formatIsoDate(date),
    });
    return (json as List).map((e) => RideSearchResult.fromJson(e)).toList();
  }

  Future<Ride> ride(int id) async => Ride.fromJson(await client.get('/rides/$id'));

  /// Só o motorista e os passageiros confirmados podem ver (senão 403).
  Future<List<RidePassenger>> ridePassengers(int id) async =>
      ((await client.get('/rides/$id/passengers')) as List).map((e) => RidePassenger.fromJson(e)).toList();

  Future<RideRequest> requestSeat(int rideId, {required Place pickup, required bool recurring}) async =>
      RideRequest.fromJson(
        await client.post('/rides/$rideId/requests', body: {'pickup': pickup.toJson(), 'recurring': recurring}),
      );

  Future<List<RideRequest>> myRequests() async =>
      ((await client.get('/ride-requests/mine')) as List).map((e) => RideRequest.fromJson(e)).toList();

  Future<RideRequest> cancelRequest(int id) async =>
      RideRequest.fromJson(await client.post('/ride-requests/$id/cancel'));

  Future<List<Booking>> myBookings() async =>
      ((await client.get('/bookings/mine')) as List).map((e) => Booking.fromJson(e)).toList();

  Future<Booking> cancelBooking(int id) async => Booking.fromJson(await client.post('/bookings/$id/cancel'));

  // Motorista

  Future<RoutePreview> previewRoute(Place origin, Place destination) async =>
      RoutePreview.fromJson(await client.get('/routes/preview', query: {
        'originLat': '${origin.latitude}',
        'originLng': '${origin.longitude}',
        'destinationLat': '${destination.latitude}',
        'destinationLng': '${destination.longitude}',
      }));

  Future<DriverRoute> createRoute(NewRoute route) async =>
      DriverRoute.fromJson(await client.post('/routes', body: route.toJson()));

  Future<List<DriverRoute>> myRoutes() async =>
      ((await client.get('/routes/mine')) as List).map((e) => DriverRoute.fromJson(e)).toList();

  Future<void> deactivateRoute(int id) => client.delete('/routes/$id');

  Future<List<Ride>> drivingRides() async =>
      ((await client.get('/rides/driving')) as List).map((e) => Ride.fromJson(e)).toList();

  Future<Ride> cancelRide(int id) async => Ride.fromJson(await client.post('/rides/$id/cancel'));

  Future<Ride> completeRide(int id) async => Ride.fromJson(await client.post('/rides/$id/complete'));

  Future<List<RideRequest>> receivedRequests({RideRequestStatus? status}) async {
    final json = await client.get('/ride-requests/received', query: {'status': status?.name.toUpperCase()});
    return (json as List).map((e) => RideRequest.fromJson(e)).toList();
  }

  Future<RideRequest> acceptRequest(int id) async =>
      RideRequest.fromJson(await client.post('/ride-requests/$id/accept'));

  Future<RideRequest> rejectRequest(int id) async =>
      RideRequest.fromJson(await client.post('/ride-requests/$id/reject'));

  Future<Earnings> earnings({DateTime? from, DateTime? to}) async => Earnings.fromJson(
        await client.get('/earnings', query: {
          'from': from == null ? null : formatIsoDate(from),
          'to': to == null ? null : formatIsoDate(to),
        }),
      );

  // Mensagens (as novas chegam em tempo real pelo WebSocket, ver MessagesService)

  Future<List<ConversationSummary>> conversations() async =>
      ((await client.get('/messages')) as List).map((e) => ConversationSummary.fromJson(e)).toList();

  Future<List<Message>> messagesWith(int userId) async =>
      ((await client.get('/messages/$userId')) as List).map((e) => Message.fromJson(e)).toList();

  Future<Message> sendMessage(int userId, String content) async =>
      Message.fromJson(await client.post('/messages/$userId', body: {'content': content}));
}
