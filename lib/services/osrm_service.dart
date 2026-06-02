import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmService {
  // OSRM público (gratuito, sin necesidad de API key)
  static const String _baseUrl = 'https://router.project-osrm.org/route/v1/driving/';
  
  static Future<List<LatLng>> getRoutePolyline({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    final url = Uri.parse(
      '$_baseUrl$originLng,$originLat;$destLng,$destLat'
      '?overview=full&geometries=geojson'
    );
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok') {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        }
      }
    } catch (e) {
      print('Error obteniendo ruta OSRM: $e');
    }
    return [];
  }
}