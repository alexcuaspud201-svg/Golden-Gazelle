import 'dart:async';
import 'dart:developer' as log;
import 'dart:math';
import 'package:dr_ai/core/utils/theme/color.dart';
import 'package:dr_ai/core/utils/helper/extention.dart';
import 'package:dr_ai/core/utils/helper/location.dart';
import 'package:dr_ai/data/model/place_directions.dart';
import 'package:dr_ai/data/model/place_location.dart';
import 'package:dr_ai/controller/validation/formvalidation_cubit.dart';
import 'package:dr_ai/controller/permissions/permissions_cubit.dart';
import 'package:dr_ai/view/widget/button_loading_indicator.dart';
import 'package:dr_ai/view/widget/custom_button.dart';
import 'package:dr_ai/view/widget/custom_tooltip.dart';
import 'package:dr_ai/view/widget/directions_details_card.dart';
import 'package:dr_ai/view/widget/floating_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Unified LatLng
import '../../../core/utils/helper/scaffold_snakbar.dart';
import '../../../data/model/find_hospital_place_info.dart';
import '../../../controller/maps/maps_cubit.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  void initState() {
    super.initState();
    _scaffoldKey = GlobalKey<ScaffoldState>();
    _getCurrentLocation();
  }

  late GlobalKey<ScaffoldState> _scaffoldKey;

  Future<void> _getCurrentLocation() async {
    LocationData? locationData =
        await LocationHelper.determineCurrentPosition(context);
    if (locationData != null) {
      _locationData = locationData;
      setState(() {});
    }
  }

  void _goToSearchedPlaceLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
        mapController.move(
          LatLng(_selectedPlace.lat, _selectedPlace.lng),
          17.0,
        );
    });
  }

  MapController mapController = MapController();
  static LocationData? _locationData;

  List<Marker> _markers = [];
  late PlaceLocationModel _selectedPlace;
  late Marker _searchedPlaceMarker;
  late LatLng _goToSearchedForPlace;

  bool _isLoading = false;
  List<FindHospitalsPlaceInfo?> _hospitalList = [];

  @override
  Widget build(BuildContext context) {
    return BlocListener<PermissionsCubit, PermissionsState>(
      listener: (context, state) {
       // logic removed
      },
      child: Scaffold(
          key: _scaffoldKey,
          drawerScrimColor: ColorManager.black.withOpacity(0.4),
          drawer: _buildDrawer(),
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              _locationData != null ? _buildMap() : _buildLoadingIndicator(),
              _buildSelectedPlaceLocation(),
              _isSearchedPlaceMarkerClicked && _placeDirections != null
                  ? DistanceAndTime(
                      isTimeAndDistanceVisible: _isTimeAndDistanceVisible,
                      placeDirections: _placeDirections)
                  : Container(),
              _buildPlaceDirections(),
              const MyFloatingSearchBar(),
            ],
          ),
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isTimeAndDistanceVisible)
                CustomToolTip(
                  bottomMargin: 20,
                  message: "Ubicación buscada",
                  child: FloatingActionButton.small(
                    splashColor: ColorManager.white.withOpacity(0.3),
                    backgroundColor: ColorManager.green,
                    heroTag: 2,
                    onPressed: () {
                      _goToSearchedPlaceLocation();
                    },
                    child: const Icon(
                      Icons.location_searching_outlined,
                      color: ColorManager.white,
                    ),
                  ),
                )
              else
                const SizedBox(),
              Gap(10.h),
              CustomToolTip(
                bottomMargin: 20,
                message: "Ubicación actual",
                child: FloatingActionButton(
                  splashColor: ColorManager.white.withOpacity(0.3),
                  backgroundColor: ColorManager.green,
                  heroTag: 3,
                  onPressed: _goToMyCurrentLocation,
                  child: const Icon(
                    Icons.zoom_in_map_rounded,
                    color: ColorManager.white,
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  void _buildCameraNewPosition() {
    _isSearchedPlaceMarkerClicked = false;
    log.log("${_selectedPlace.lat}  ${_selectedPlace.lng}");
    _goToSearchedForPlace = LatLng(
        _selectedPlace.lat,
        _selectedPlace.lng,
      );
    setState(() {});
  }

  Widget _buildMap() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _locationData != null 
            ? LatLng(_locationData!.latitude!, _locationData!.longitude!)
            : const LatLng(-0.1807, -78.4678), // Default (Quito/Eq) or Safe fallback
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.dr_ai',
        ),
        MarkerLayer(
          markers: _markers.map((m) {
             return Marker(
               point: m.point,
               width: 40,
               height: 40,
               child: const Icon(Icons.location_on, color: ColorManager.green, size: 40),
             );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _goToMyCurrentLocation() async {
    LocationData? locationData =
        await LocationHelper.determineCurrentPosition(context);
    if (locationData != null) {
      _locationData = locationData;
      setState(() {}); // Rebuild to update map center if needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
          mapController.move(
            LatLng(_locationData!.latitude!, _locationData!.longitude!), 17.0);
      });
    }
  }

  Widget _buildSelectedPlaceLocation() {
    return BlocListener<MapsCubit, MapsState>(
      listener: (context, state) {
        if (state is MapsLoadedLocationSuccess) {
          _selectedPlace = state.placeLocation[0];
          _placeDirections = null;
          setState(() {});
          log.log(_selectedPlace.toString());
          _goToMySearchedForLocation();
        }
      },
      child: Container(),
    );
  }

  Future<void> _goToMySearchedForLocation() async {
    _buildCameraNewPosition();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       mapController.move(_goToSearchedForPlace, 17.0);
    });
    _buildSearchedPlaceMarker();
  }

  void _buildSearchedPlaceMarker() {
    _searchedPlaceMarker = Marker(
      point: LatLng(_goToSearchedForPlace.latitude, _goToSearchedForPlace.longitude),
      width: 40,
      height: 40,
      child: GestureDetector(
        onTap: () {
          _isSearchedPlaceMarkerClicked = true;
          _isTimeAndDistanceVisible = true;
          _getDirections();
          setState(() {});
        },
        child: const Icon(Icons.location_on, color: ColorManager.green, size: 40),
      ),
    );

    _addMarkerToMarkersAndUpdateUI(_searchedPlaceMarker);
  }

  void _addMarkerToMarkersAndUpdateUI(Marker marker) {
    _markers = [];
    setState(() {
      _markers.add(marker);
    });
  }

  void _addMarkersFromHospitalList() {
    _markers = [];
    for (var hospital in _hospitalList) {
      if (hospital == null) continue;
      final marker = Marker(
        point: LatLng(hospital.lat, hospital.lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            _selectedPlace =
                PlaceLocationModel(lat: hospital.lat, lng: hospital.lng);
            _isSearchedPlaceMarkerClicked = true;
            _isTimeAndDistanceVisible = true;
            _getDirections();
            setState(() {});
          },
          child: const Icon(Icons.local_hospital, color: ColorManager.green, size: 40),
        ),
      );
      _markers.add(marker);
    }
    setState(() {});
  }

  PlaceDirectionsModel? _placeDirections;

  bool _isSearchedPlaceMarkerClicked = false;
  bool _isTimeAndDistanceVisible = false;

  Widget _buildPlaceDirections() {
    _placeDirections = null;
    setState(() {});
    return BlocListener<MapsCubit, MapsState>(
      listener: (context, state) {
        if (state is MapsLoadedDirectionsSuccess) {
          _placeDirections = state.placeDirections;
        }
      },
      child: Container(),
    );
  }

  Future<void> _getDirections() async {
    await context.bloc<MapsCubit>().getPlaceDirections(
          origin: LatLng(_locationData!.latitude!, _locationData!.longitude!),
          destination: LatLng(_selectedPlace.lat, _selectedPlace.lng),
        );
    setState(() {});
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ButtonLoadingIndicator(),
            SizedBox(height: 20),
            Text(
              'Cargando Mapa...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markNearestHospital() {
    if (_hospitalList.isEmpty) return;

    double nearestDistance = double.infinity;
    FindHospitalsPlaceInfo? nearestHospital;
    LatLng currentPosition =
        LatLng(_locationData!.latitude!, _locationData!.longitude!);

    for (var hospital in _hospitalList) {
      LatLng hospitalPosition = LatLng(hospital!.lat, hospital.lng);
      double distance = _calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        hospitalPosition.latitude,
        hospitalPosition.longitude,
      );

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestHospital = hospital;
      }
    }

    _markers = [];
    for (var hospital in _hospitalList) {
      if (hospital == null) continue;
      final isNearest = nearestHospital != null && hospital.placeId == nearestHospital.placeId;
      final marker = Marker(
        point: LatLng(hospital.lat, hospital.lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
            _selectedPlace =
                PlaceLocationModel(lat: hospital.lat, lng: hospital.lng);
            _isSearchedPlaceMarkerClicked = true;
            _isTimeAndDistanceVisible = true;
            _getDirections();
            setState(() {});
          },
          child: Icon(
            Icons.local_hospital,
            color: isNearest ? ColorManager.error : ColorManager.green,
            size: isNearest ? 50 : 40,
          ),
        ),
      );
      _markers.add(marker);
    }
  }

  // Haversine formula to calculate distance
  double _calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {
    const double earthRadius = 6371000; // in meters
    double dLat = _degreesToRadians(endLatitude - startLatitude);
    double dLon = _degreesToRadians(endLongitude - startLongitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(startLatitude)) *
            cos(_degreesToRadians(endLatitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c;

    return distance;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  Widget _buildDrawer() {
    return BlocConsumer<MapsCubit, MapsState>(
      listener: (context, state) {
        if (state is FindHospitalLoading) {
          _isLoading = true;
        } else if (state is FindHospitalSuccess) {
          context.read<PermissionsCubit>().checkMapLockStatus();
          _isLoading = false;
          _hospitalList = state.hospitalsList;
          _addMarkersFromHospitalList();
          _markNearestHospital();
        } else if (state is FindHospitalFailure) {
          _isLoading = false;

          customSnackBar(
              context, '¡Hubo un error! Inténtalo de nuevo más tarde.');
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1400),
            height: _hospitalList.isEmpty || _hospitalList.length <= 3
                ? context.height / 2
                : context.height,
            child: Drawer(
              backgroundColor: ColorManager.trasnsparent.withOpacity(0.2),
              width: context.width / 1.3,
              child: Column(
                children: [
                  _buildTotalHospital(
                      _hospitalList.isNotEmpty ? _hospitalList.length : 0
                      ),
                  Gap(2.h),
                  (_hospitalList.isNotEmpty)
                      ? Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _hospitalList.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 2,
                                color: ColorManager.white,
                                child: ListTile(
                                  onTap: () {
                                    _selectedPlace = PlaceLocationModel(
                                      lat: _hospitalList[index]!.lat,
                                      lng: _hospitalList[index]!.lng,
                                    );
                                    _buildCameraNewPosition();
                                    _goToSearchedPlaceLocation();
                                    _markNearestHospital();
                                    _getDirections();
                                    _isTimeAndDistanceVisible = true;
                                    _isSearchedPlaceMarkerClicked = true;
                                    setState(() {});
                                    _scaffoldKey.currentState?.closeDrawer();
                                  },
                                  title: Text(
                                    _hospitalList[index]?.name ?? '',
                                    textAlign: TextAlign.center,
                                    style:
                                        context.textTheme.bodySmall?.copyWith(
                                      color: ColorManager.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: (_hospitalList[index]!
                                          .internationalPhoneNumber!
                                          .isNotEmpty)
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "${_hospitalList[index]?.internationalPhoneNumber}",
                                              style: context.textTheme.bodySmall
                                                  ?.copyWith(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                            IconButton(
                                                onPressed: () {
                                                  context
                                                      .bloc<ValidationCubit>()
                                                      .copyText(_hospitalList[
                                                              index]
                                                          ?.internationalPhoneNumber);
                                                  customSnackBar(
                                                      context,
                                                      "Texto copiado al portapapeles",
                                                      null,
                                                      1);
                                                },
                                                icon: Icon(
                                                  Icons.content_copy,
                                                  size: 17.r,
                                                ))
                                          ],
                                        )
                                      : null,
                                  trailing: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "calificación",
                                        style: context.textTheme.bodyLarge
                                            ?.copyWith(
                                                fontSize: 12.spMin,
                                                fontWeight: FontWeight.w400),
                                      ),
                                      Text(
                                        (_hospitalList[index]?.rating)
                                            .toString(),
                                        style: context.textTheme.bodySmall
                                            ?.copyWith(
                                                color: _hospitalList[index]!
                                                            .rating! >=
                                                        2.5
                                                    ? ColorManager.correct
                                                    : ColorManager.error),
                                      )
                                    ],
                                  ),
                                  leading: _hospitalList[index]!.openNow!
                                      ? const Icon(
                                          Icons.lock_open,
                                          color: ColorManager.correct,
                                        )
                                      : const Icon(
                                          Icons.lock_outline,
                                          color: ColorManager.error,
                                        ),
                                ),
                              );
                            },
                          ),
                        )
                      : const Expanded(
                          child: Icon(
                            Icons.my_location_rounded,
                            color: ColorManager.green,
                            size: 60,
                          ),
                        ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: CustomButton(
                      isDisabled: _isLoading,
                      size: Size(context.width * 0.475, 38.w),
                      onPressed: () {
                        context.bloc<MapsCubit>().getNearestHospitals();
                      },
                      title: "Buscar Hospitales",
                      widget:
                          _isLoading ? const ButtonLoadingIndicator() : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalHospital(int totalHospital) {
    return Card(
      margin: EdgeInsets.only(left: 15.w, right: 15.w, top: 5.h, bottom: 2.h),
      color: ColorManager.green,
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 12.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Hospitales encontrados:  ",
                    style: context.textTheme.displayMedium?.copyWith(
                        fontSize: 14.spMin, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    totalHospital.toString(),
                    style: context.textTheme.displayMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
