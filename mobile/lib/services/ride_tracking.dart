import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../api/api_client.dart';
import '../api/carona_api.dart';
import '../api/models.dart';
import '../config.dart';

/// Acompanha a posição do carro de uma carona em tempo real pelo WebSocket `/ws/tracking`.
/// Ao conectar o backend já manda a última posição; a conexão volta sozinha se cair.
class RideTracker {
  final CaronaApi api;
  final int rideId;

  final location = Rxn<VehicleLocation>();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _attempts = 0;
  bool _closed = false;

  RideTracker(this.api, this.rideId);

  void start() {
    _closed = false;
    _connect();
  }

  void _connect() {
    _reconnectTimer?.cancel();
    final token = api.client.token;
    if (_closed || token == null) return;

    final uri = Uri.parse('${AppConfig.wsUrl}/ws/tracking')
        .replace(queryParameters: {'rideId': '$rideId', 'token': token});
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _subscription = channel.stream.listen(
      _onData,
      onError: (_) => _scheduleReconnect(channel),
      onDone: () => _scheduleReconnect(channel),
      cancelOnError: true,
    );
    channel.ready.then((_) {
      _attempts = 0;
    }).catchError((_) {
      // A falha também chega pelo stream (onError), que agenda a reconexão.
    });
  }

  void _onData(dynamic data) {
    try {
      final update = VehicleLocation.fromJson(jsonDecode(data as String));
      if (update.rideId == rideId) location.value = update;
    } catch (_) {
      // Ignora qualquer coisa que não seja uma posição.
    }
  }

  void _scheduleReconnect(WebSocketChannel channel) {
    if (_channel != channel) return;
    _subscription?.cancel();
    _channel = null;
    if (_closed) return;
    // O backend fecha a conexão (1008) de quem não está na carona; mesmo assim tenta de novo devagar.
    final delay = Duration(seconds: min(30, 2 << min(_attempts, 4)));
    _attempts++;
    _reconnectTimer = Timer(delay, _connect);
  }

  void stop() {
    _closed = true;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _channel = null;
  }
}

/// Envia a posição do aparelho do motorista enquanto a tela da viagem está aberta.
/// Manda no máximo uma posição a cada [minInterval] (ou quando o carro andou bastante).
class LocationSharer {
  static const minInterval = Duration(seconds: 5);

  final CaronaApi api;
  final int rideId;

  final sharing = false.obs;
  final error = RxnString();
  final lastSentAt = Rxn<DateTime>();

  StreamSubscription<Position>? _positions;
  DateTime? _lastAttempt;
  bool _sending = false;

  LocationSharer(this.api, this.rideId);

  /// Pede permissão e começa a enviar; devolve false (com [error]) se não deu.
  Future<bool> start() async {
    if (sharing.value) return true;
    error.value = null;
    if (!await Geolocator.isLocationServiceEnabled()) {
      error.value = 'Ative a localização do aparelho para os passageiros verem o carro.';
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      error.value = 'Permita o acesso à localização nos ajustes do aparelho.';
      return false;
    }

    sharing.value = true;
    _positions = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen(_onPosition, onError: (_) {
      error.value = 'Não foi possível ler o GPS agora.';
    });
    return true;
  }

  Future<void> _onPosition(Position position) async {
    final now = DateTime.now();
    if (_sending || (_lastAttempt != null && now.difference(_lastAttempt!) < minInterval)) return;
    _lastAttempt = now;
    _sending = true;
    try {
      await api.sendLocation(
        rideId,
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
        speedMps: position.speed,
      );
      lastSentAt.value = now;
      error.value = null;
    } on ApiException catch (e) {
      error.value = e.message;
      // 409: a viagem acabou (concluída, cancelada ou passou do horário); para de enviar.
      if (e.statusCode == 409 || e.statusCode == 403) stop();
    } finally {
      _sending = false;
    }
  }

  void stop() {
    _positions?.cancel();
    _positions = null;
    sharing.value = false;
  }
}
