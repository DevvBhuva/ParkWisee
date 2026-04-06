import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PolylineDecoder {
  /// Decodes a polyline string into a list of [Position] objects.
  /// Based on the standard Google Polyline Algorithm.
  static List<Position> decodePolyline(String encoded) {
    List<Position> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      // Mapbox uses [longitude, latitude] for Position
      poly.add(Position(lng / 1E5, lat / 1E5));
    }

    return poly;
  }
}
