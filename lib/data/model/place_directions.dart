import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart'; // For LatLngBounds
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class PlaceDirectionsModel {
  late LatLngBounds bounds;
  late List<LatLng> polylinePoints;
  late String totalDistance;
  late String totalDuration;

  PlaceDirectionsModel({
    required this.bounds,
    required this.polylinePoints,
    required this.totalDistance,
    required this.totalDuration,
  });

  factory PlaceDirectionsModel.fromJson(Map<String, dynamic> json) {
    // Basic offline stub or simple parsing if structure matches
    // For now, handling as simulation data mostly
    
    // If real data comes in unexpected format, provide defaults
    if (json.containsKey('routes') && (json['routes'] as List).isNotEmpty) {
        final data = json['routes'][0] as Map<String, dynamic>;
        final northeast = data['bounds']['northeast'];
        final southwest = data['bounds']['southwest'];
    
        final bounds = LatLngBounds(
          LatLng(northeast['lat'], northeast['lng']),
          LatLng(southwest['lat'], southwest['lng']),
        );
    
        String distance = "0 km";
        String duration = "0 min";
    
        if ((data['legs'] as List).isNotEmpty) {
          final leg = data['legs'][0];
          distance = leg['distance']['text'];
          duration = leg['duration']['text'];
        }

        final points = PolylinePoints()
          .decodePolyline(data['overview_polyline']['points'] as String)
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    
        return PlaceDirectionsModel(
          bounds: bounds,
          polylinePoints: points,
          totalDistance: distance,
          totalDuration: duration,
        );
    }
    
    // Fallback/Stub
    return PlaceDirectionsModel(
        bounds: LatLngBounds(const LatLng(0,0), const LatLng(0,0)), 
        polylinePoints: [], 
        totalDistance: "0 km", 
        totalDuration: "0 min"
    );

  }
}

