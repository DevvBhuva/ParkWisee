import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:parkwise/core/services/mapbox_service.dart';
import 'package:parkwise/core/utils/polyline_decoder.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';
import 'package:parkwise/features/parking/services/parking_firestore_service.dart';

class MapProvider extends ChangeNotifier {
  final MapboxService _mapboxService = MapboxService();
  final ParkingFirestoreService _parkingService = ParkingFirestoreService();
  
  // Managers
  MapboxMap? mapboxMap;
  PointAnnotationManager? parkingAnnotationManager;
  PointAnnotationManager? selectionAnnotationManager;
  PointAnnotationManager? userLocationAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;

  // Parking Spots State
  List<ParkingSpot> parkingSpots = [];
  final Map<String, ParkingSpot> _annotationIdToSpot = {};
  StreamSubscription? _spotsSubscription;

  // Search State
  bool isSearchExpanded = false;
  List<dynamic> suggestions = [];
  Timer? _debounce;
  final TextEditingController searchController = TextEditingController();
  final DraggableScrollableController sheetController = DraggableScrollableController();

  // Selected Location & Route State
  Map<String, dynamic>? selectedLocation;
  ParkingSpot? selectedParkingSpot;
  String? routeDuration;
  String? routeDistance;
  bool isFetchingRoute = false;
  
  // Current Position
  geo.Position? currentUserPosition;

  // ---------------------------------------------------------------------------
  // initialization
  // ---------------------------------------------------------------------------

  Future<void> setMapOptions(MapboxMap map, PointAnnotationManager parking, PolylineAnnotationManager poly) async {
    // 🛡️ REASSEMBLE PROTECTION: Do not reset if already set
    if (mapboxMap != null) return;
    
    mapboxMap = map;
    parkingAnnotationManager = parking;
    polylineAnnotationManager = poly;
    
    // Create additional managers for selection and user location
    selectionAnnotationManager = await map.annotations.createPointAnnotationManager();
    userLocationAnnotationManager = await map.annotations.createPointAnnotationManager();
    
    // Start listening to parking spots
    _loadParkingSpots();
    notifyListeners();
  }

  void _loadParkingSpots() {
    _spotsSubscription?.cancel();
    _spotsSubscription = _parkingService.getParkingSpots().listen((spots) {
      parkingSpots = spots;
      _renderMarkers(spots);
      notifyListeners();
    });
  }

  Future<void> _renderMarkers(List<ParkingSpot> spots) async {
    if (parkingAnnotationManager == null) return;
    await parkingAnnotationManager?.deleteAll();
    _annotationIdToSpot.clear();

    final options = spots.map((spot) => PointAnnotationOptions(
      geometry: Point(coordinates: Position(spot.longitude, spot.latitude)),
      iconImage: "marker-15", // Ensure this exists in your Mapbox style
      iconSize: 1.5,
    )).toList();

    final annotations = await parkingAnnotationManager?.createMulti(options);
    if (annotations != null) {
      for (int i = 0; i < annotations.length; i++) {
        if (annotations[i] != null) {
          _annotationIdToSpot[annotations[i]!.id] = spots[i];
        }
      }
    }
  }

  void onMarkerTapped(PointAnnotation annotation) {
    final spot = _annotationIdToSpot[annotation.id];
    if (spot != null) {
      selectParkingSpot(spot);
    }
  }

  Future<void> selectParkingSpot(ParkingSpot spot) async {
    selectedParkingSpot = spot;
    selectedLocation = null;
    
    await _moveToLocation(spot.latitude, spot.longitude, zoom: 15.0);
    
    if (currentUserPosition != null) {
      await fetchRoute(spot.latitude, spot.longitude);
    }

    _expandSheet();
    notifyListeners();
  }

  void updateCurrentUserPosition(geo.Position position) {
    currentUserPosition = position;
    _updateUserMarker(position);
    notifyListeners();
  }

  Future<void> _updateUserMarker(geo.Position position) async {
    if (userLocationAnnotationManager == null) return;
    
    await userLocationAnnotationManager?.deleteAll();
    await userLocationAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(position.longitude, position.latitude)),
        iconImage: "dot-11", // Standard blue dot frequently found in Mapbox styles
        iconSize: 1.2,
        // Make it look like a blue dot if possible, otherwise rely on iconImage
        iconColor: Colors.blue.value, 
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Search logic
  // ---------------------------------------------------------------------------

  void toggleSearch(bool expand) {
    isSearchExpanded = expand;
    if (!expand) {
      searchController.clear();
      suggestions = [];
    }
    notifyListeners();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        suggestions = await _mapboxService.getSuggestions(
          query,
          lat: currentUserPosition?.latitude,
          lng: currentUserPosition?.longitude,
        );
      } else {
        suggestions = [];
      }
      notifyListeners();
    });
  }

  Future<void> selectSuggestion(dynamic feature) async {
    final location = _mapboxService.featureToLocation(feature);
    final center = feature['center']; // [lng, lat]
    
    await _moveToLocation(center[1], center[0]);
    
    selectedLocation = location;
    selectedParkingSpot = null;
    suggestions = [];
    isSearchExpanded = false;
    searchController.text = location['place_name'];
    
    _addMarker(center[1], center[0], isCurrentSelection: true);
    
    if (currentUserPosition != null) {
      await fetchRoute(center[1], center[0]);
    }
    
    _expandSheet();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Routing logic
  // ---------------------------------------------------------------------------

  Future<void> fetchRoute(double destLat, double destLng) async {
    if (currentUserPosition == null) return;
    
    isFetchingRoute = true;
    notifyListeners();

    try {
      final data = await _mapboxService.getRoute(
        currentUserPosition!.latitude,
        currentUserPosition!.longitude,
        destLat,
        destLng,
      );

      if (data != null && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];
        final geometry = route['geometry'] as String;
        final double duration = (route['duration'] as num).toDouble();
        final double distance = (route['distance'] as num).toDouble();

        routeDuration = _formatDuration(duration);
        routeDistance = _formatDistance(distance);
        
        // Draw Polyline
        final coordinates = PolylineDecoder.decodePolyline(geometry);
        _drawRoute(coordinates);
      }
    } catch (e) {
      print('MapProvider.fetchRoute error: $e');
    } finally {
      isFetchingRoute = false;
      notifyListeners();
    }
  }

  void _drawRoute(List<Position> coordinates) async {
    await polylineAnnotationManager?.deleteAll();
    await polylineAnnotationManager?.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: coordinates),
        lineColor: Colors.blue.value,
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // camera & Markers
  // ---------------------------------------------------------------------------

  Future<void> _moveToLocation(double lat, double lng, {double zoom = 14.0}) async {
    await mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(lng, lat)),
        zoom: zoom,
        bearing: 0,
        pitch: 0,
      ),
      MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> centerOnUser() async {
    if (currentUserPosition == null) return;
    await _moveToLocation(currentUserPosition!.latitude, currentUserPosition!.longitude, zoom: 15.0);
  }

  Future<void> zoomIn() async {
    final state = await mapboxMap?.getCameraState();
    if (state != null) {
       await mapboxMap?.flyTo(
        CameraOptions(zoom: state.zoom + 1),
        MapAnimationOptions(duration: 300),
      );
    }
  }

  Future<void> zoomOut() async {
    final state = await mapboxMap?.getCameraState();
    if (state != null) {
       await mapboxMap?.flyTo(
        CameraOptions(zoom: state.zoom - 1),
        MapAnimationOptions(duration: 300),
      );
    }
  }

  Future<void> _addMarker(double lat, double lng, {bool isCurrentSelection = false}) async {
    if (selectionAnnotationManager == null) return;
    
    // Clear previous selection
    await selectionAnnotationManager?.deleteAll();
    
    await selectionAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)),
        iconImage: "marker-15", 
        iconSize: 2.0,
        iconColor: Colors.red.value, 
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDuration(double seconds) {
    if (seconds < 60) return '${seconds.round()} sec';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = (minutes / 60).floor();
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    final km = (meters / 1000).toStringAsFixed(1);
    return '$km km';
  }

  void clearSelection() {
    selectedLocation = null;
    selectedParkingSpot = null;
    routeDuration = null;
    routeDistance = null;
    polylineAnnotationManager?.deleteAll();
    notifyListeners();
  }

  void _expandSheet() {
    if (sheetController.isAttached) {
      sheetController.animateTo(
        0.25,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
