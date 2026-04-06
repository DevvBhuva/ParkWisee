import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:provider/provider.dart';
import 'package:parkwise/features/navigation/providers/map_provider.dart';
import 'package:parkwise/features/navigation/widgets/map_search_bar.dart';
import 'package:parkwise/features/navigation/widgets/location_details_sheet.dart';
import 'package:parkwise/features/navigation/widgets/map_controls.dart';
import 'package:parkwise/features/navigation/widgets/map_layer.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  StreamSubscription? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) return;
    }

    if (permission == geo.LocationPermission.deniedForever) return;

    _startLocationTracking();
  }

  void _startLocationTracking() {
    _positionSubscription = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (mounted) {
        context.read<MapProvider>().updateCurrentUserPosition(position);
      }
    });

    // Get initial position
    geo.Geolocator.getCurrentPosition().then((position) {
      if (mounted) {
        final mapProvider = context.read<MapProvider>();
        mapProvider.updateCurrentUserPosition(position);
        
        // Use the stored map controller to fly to current position
        mapProvider.mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(position.longitude, position.latitude)),
            zoom: 14.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mapProvider = context.read<MapProvider>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // 🗺️ THE CORE MAP LAYER (Isolated for Stability)
            GestureDetector(
              onTap: () {
                if (mapProvider.isSearchExpanded) {
                  mapProvider.toggleSearch(false);
                }
                FocusScope.of(context).unfocus();
              },
              child: MapLayer(isDark: isDark),
            ),
  
            // 🔎 UI OVERLAYS (Independent Layers)
            const MapSearchBar(),
            const MapControls(),
            const LocationDetailsSheet(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
