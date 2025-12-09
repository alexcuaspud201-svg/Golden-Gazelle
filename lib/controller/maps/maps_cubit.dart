import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import 'package:bloc/bloc.dart';
// import 'package:dio/dio.dart'; // Removed
import 'package:dr_ai/data/model/place_directions.dart';
import 'package:dr_ai/data/model/place_location.dart';
import 'package:dr_ai/data/model/place_suggetion.dart';
// import 'package:dr_ai/data/source/remote/maps_place.dart'; // Removed
import 'package:location/location.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart'; // For LatLngBounds
import 'package:meta/meta.dart';

import '../../data/model/find_hospital_place_info.dart';

part 'maps_state.dart';

class MapsCubit extends Cubit<MapsState> {
  MapsCubit() : super(MapsInitial());

  double? lat;
  double? lng;
  LocationData? _locationData;
  final Location _location = Location();

  //! Place suggetions using OpenStreetMap Nominatim API
  Future<void> getPlaceSuggetions({
    required String place,
    required String sessionToken,
  }) async {
    emit(MapsLoading());
    try {
      if (place.isEmpty) return;

      _locationData ??= await _location.getLocation();
      // userLocation can be used to bias results, but Nominatim 'viewbox' is preferred if we had bounding box.
      // For now, we search generally but could append country code if needed.
      // Adding '&countrycodes=ec' to limit to Ecuador as per user context (IESS).
      
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$place&format=json&addressdetails=1&limit=5&countrycodes=ec');

      final response = await http.get(url, headers: {
        'User-Agent': 'DrAi_App/1.0 (com.example.dr_ai)' // Required by Nominatim
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<PlaceSuggestionModel> suggestionList = data.map((item) {
          return PlaceSuggestionModel(
            placeId: item['place_id'].toString(),
            description: item['display_name'], // Full address
            mainText: item['name'] ?? item['display_name'].split(',')[0],
            secondaryText: item['address']?['city'] ?? item['type'] ?? '',
          );
        }).toList();

        emit(MapsLoadedSuggestionsSuccess(placeSuggestionList: suggestionList));
      } else {
        throw Exception('Failed to load suggestions');
      }
    } catch (err) {
      emit(MapsFailure(errMessage: err.toString()));
      log(err.toString());
    }
  }

  //! Place Location.
  Future<void> getPlaceLocation(
      {required String placeId,
      required String sessionToken,
      String? description}) async {
    emit(MapsLoading());
    try {
      // Fetch details using Nominatim 'details' endpoint or assume we can find it.
      // Since we don't have lat/lng passed directly, we fetch by place_id.
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/details?place_id=$placeId&format=json');
      
      final response = await http.get(url, headers: {
        'User-Agent': 'DrAi_App/1.0 (com.example.dr_ai)'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        PlaceLocationModel placeLocationModel = PlaceLocationModel(
            lat: double.parse(data['lat'] ?? data['centroid']['lat']), // Nominatim struct varies slightly
            lng: double.parse(data['lon'] ?? data['centroid']['lon'])
        );
        
        emit(MapsLoadedLocationSuccess(
            placeLocation: [placeLocationModel, description]));
      } else {
         throw Exception('Failed to load place details');
      }
    } catch (err) {
      log('Error getting place location: $err');
      // Fallback: if details fail, tries to search by description
      if (description != null) {
          try {
             final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$description&format=json&limit=1');
             final response = await http.get(url, headers: {'User-Agent': 'DrAi_App/1.0'});
             if(response.statusCode == 200) {
                final List data = json.decode(response.body);
                if (data.isNotEmpty) {
                    PlaceLocationModel placeLocationModel = PlaceLocationModel(
                        lat: double.parse(data[0]['lat']),
                        lng: double.parse(data[0]['lon'])
                    );
                    emit(MapsLoadedLocationSuccess(placeLocation: [placeLocationModel, description]));
                    return;
                }
             }
          } catch (e) {
             log("Fallback search failed: $e");
          }
      }
      emit(MapsFailure(errMessage: err.toString()));
    }
  }

  Future<void> getPlaceDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    emit(MapsLoading());
    try {
      // Offline Simulation: No directions or straight line
      await Future.delayed(const Duration(milliseconds: 50));
      PlaceDirectionsModel directions = PlaceDirectionsModel(
          bounds: LatLngBounds(origin, destination), 
          polylinePoints: [
              LatLng(origin.latitude, origin.longitude),
              LatLng(destination.latitude, destination.longitude)
          ], 
          totalDistance: "1 km", 
          totalDuration: "10 min"
      );

      emit(MapsLoadedDirectionsSuccess(placeDirections: directions));
    } catch (err) {
      emit(MapsFailure(errMessage: err.toString()));
      log(err.toString());
    }
  }

  Future<void> getNearestHospitals({double? radius}) async {
    try {
      emit(FindHospitalLoading());
      _locationData ??= await _location.getLocation();
      log('Searching nearest hospitals via Nominatim...');
      
      final lat = _locationData!.latitude;
      final lon = _locationData!.longitude;
      
      // Search for hospitals near the user. Nominatim doesn't have a specific radius param acting like Places API
      // but we can box the viewbox or just use the nearby logic 'q=hospital+near+...'. 
      // Better: q=hospital&lat=..&lon=.. (Not supported directly for proximity sorting consistently without viewbox).
      // Standard approach: q=hospital&limit=10&viewbox=left,top,right,bottom&bounded=1
      // Or simpler: q=hospital&countrycodes=ec (and sort by distance in client is hard if api returns random).
      // Nominatim isn't great for "nearest X". 
      // Alternative: Overpass API? No, too complex.
      // Let's us basic Nominatim search "hospital" prioritizing the area implies we might get local results depending on how they serve it.
      // Actually, standard Search endpoint works poorly for "nearest".
      // BUT for "hospital" in "City" works.
      // Let's try to reverse geocode city first? No, slow.
      // Let's try: q=hospital&amenity=hospital
      
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=hospital&format=json&limit=10&viewbox=${lon!-0.05},${lat!+0.05},${lon+0.05},${lat-0.05}&bounded=1');
          
      final response = await http.get(url, headers: {
        'User-Agent': 'DrAi_App/1.0 (com.example.dr_ai)'
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<FindHospitalsPlaceInfo> hospitalsData = data.map((item) {
           return FindHospitalsPlaceInfo(
              name: item['name'] ?? item['display_name'].split(',')[0],
              placeId: item['place_id'].toString(),
              lat: double.parse(item['lat']),
              lng: double.parse(item['lon']),
              rating: 4.0, // Nominatim doesn't have ratings
              openNow: true, 
              internationalPhoneNumber: "N/A"
           );
        }).toList();

        if (hospitalsData.isEmpty) {
          emit(FindHospitalFailure(message: 'No hospitals found nearby.'));
        } else {
          emit(FindHospitalSuccess(hospitalsList: hospitalsData));
        }
      } else {
         throw Exception('Failed to fetch nearby hospitals');
      }
    } catch (err) {
      log('Error: $err');
      emit(FindHospitalFailure(message: err.toString()));
    }
  }
}