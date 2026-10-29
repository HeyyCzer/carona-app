import 'package:latlong2/latlong.dart';

/// Decodifica o formato "encoded polyline" do Google (precisão de 5 casas), usado pelo backend
/// para mandar o trajeto pelas ruas (vindo do OSRM).
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  var index = 0, lat = 0, lng = 0;

  int next() {
    var shift = 0, result = 0, chunk = 0;
    do {
      chunk = encoded.codeUnitAt(index++) - 63;
      result |= (chunk & 0x1f) << shift;
      shift += 5;
    } while (chunk >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    lat += next();
    lng += next();
    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
