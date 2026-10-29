import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/carona_api.dart';
import '../api/models.dart';

/// Lembra as caronas que o motorista viu como "próximas".
///
/// O backend só lista caronas que ainda não saíram (`GET /rides/driving`), mas só deixa
/// concluir (`POST /rides/{id}/complete`) depois da saída — e é a conclusão que conta nos
/// recebimentos. Guardando os ids, conseguimos buscar essas caronas depois com `GET /rides/{id}`.
class DrivenRidesService extends GetxService {
  static const _maxAge = Duration(days: 7);

  final CaronaApi api;
  final SharedPreferences prefs;

  DrivenRidesService(this.api, this.prefs);

  String _key(int userId) => 'driving.ids.$userId';

  void remember(int userId, Iterable<Ride> rides) {
    final ids = {...prefs.getStringList(_key(userId)) ?? <String>[], ...rides.map((r) => '${r.id}')};
    prefs.setStringList(_key(userId), ids.toList());
  }

  /// Caronas que já saíram e ainda estão como agendadas, esperando o motorista concluir.
  Future<List<Ride>> awaitingCompletion(int userId) async {
    final ids = prefs.getStringList(_key(userId)) ?? <String>[];
    final pending = <Ride>[];
    final keep = <String>[];
    final cutoff = DateTime.now().subtract(_maxAge);

    for (final id in ids) {
      try {
        final ride = await api.ride(int.parse(id));
        if (ride.status != RideStatus.scheduled || ride.departure.isBefore(cutoff)) continue;
        keep.add(id);
        if (ride.hasDeparted) pending.add(ride);
      } catch (_) {
        keep.add(id); // erro de rede: tenta de novo depois
      }
    }
    prefs.setStringList(_key(userId), keep);
    pending.sort((a, b) => a.departure.compareTo(b.departure));
    return pending;
  }
}
