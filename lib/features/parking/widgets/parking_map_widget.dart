import 'dart:async';
import 'dart:convert'; // for jsonDecode
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';
import 'package:parkwise/features/parking/services/parking_firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;

class ParkingMapWidget extends StatefulWidget {
  const ParkingMapWidget({super.key});

  @override
  State<ParkingMapWidget> createState() => _ParkingMapWidgetState();
}

class _ParkingMapWidgetState extends State<ParkingMapWidget> {
  // -------------------------------------------------------------------------
  // Access Token
  // -------------------------------------------------------------------------
  final String kMapboxAccessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  // -------------------------------------------------------------------------

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  StreamSubscription<List<ParkingSpot>>? _spotsSubscription;
  final ParkingFirestoreService _parkingService = ParkingFirestoreService();

  // Mapping annotation ID to ParkingSpot for click handling
  final Map<String, ParkingSpot> _annotationIdToSpot = {};

  // Rajkot Coordinates
  static const double kRajkotLat = 22.3039;
  static const double kRajkotLng = 70.8022;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    // Ensure token is set
    MapboxOptions.setAccessToken(kMapboxAccessToken);
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return;
    }

    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        return;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return;
    }
  }

  @override
  void dispose() {
    _spotsSubscription?.cancel();
    super.dispose();
  }

  // 1. Initialize Map
  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Optional: Hide default ornaments if desired
    // _mapboxMap?.scaleBar.updateSettings(ScaleBarSettings(enabled: false));

    // Enable Location Component
    _mapboxMap?.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    // Create Annotation Managers
    _mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
      _pointAnnotationManager = manager;

      // 4. Load & Show Markers
      _loadParkingSpots();

      // 5. Handle Marker Taps
      // ignore: deprecated_member_use
      manager.addOnPointAnnotationClickListener(
        AnnotationClickListener(
          onAnnotationClick: (annotation) {
            final spot = _annotationIdToSpot[annotation.id];
            if (spot != null) {
              _onSpotSelected(spot);
            }
          },
        ),
      );
    });

    _mapboxMap?.annotations.createPolylineAnnotationManager().then((manager) {
      _polylineAnnotationManager = manager;
    });
  }

  // Load spots from Firestore
  void _loadParkingSpots() {
    _spotsSubscription = _parkingService.getParkingSpots().listen(
      (spots) {
        if (kDebugMode) {
          debugPrint("Loaded ${spots.length} parking spots from Firestore.");
        }
        _updateMarkers(spots);
      },
      onError: (e) {
        if (kDebugMode) {
          debugPrint("Error loading parking spots: $e");
        }
      },
    );
  }

  // Add markers to map
  Future<void> _updateMarkers(List<ParkingSpot> spots) async {
    if (_pointAnnotationManager == null) return;

    // Clear existing
    await _pointAnnotationManager?.deleteAll();
    _annotationIdToSpot.clear();

    final List<PointAnnotationOptions> optionsList = [];
    final List<ParkingSpot> orderedSpots = []; // To keep track for ID mapping

    for (var spot in spots) {
      final options = PointAnnotationOptions(
        geometry: Point(coordinates: Position(spot.longitude, spot.latitude)),
        iconImage: 'marker-15', // Changed to standard marker-15
        iconSize: 2.0,
        textField: spot.name,
        textOffset: [0, 1.5],
        textSize: 12.0,
      );

      optionsList.add(options);
      orderedSpots.add(spot);
    }

    try {
      // Batch create
      final annotations = await _pointAnnotationManager?.createMulti(
        optionsList,
      );

      // Map IDs
      if (annotations != null) {
        for (int i = 0; i < annotations.length; i++) {
          final annotation = annotations[i];
          if (annotation != null) {
            _annotationIdToSpot[annotation.id] = orderedSpots[i];
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error creating annotations: $e");
      }
    }
  }

  // 6. Interaction
  void _onSpotSelected(ParkingSpot spot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spot.name,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 18),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      spot.address.isNotEmpty
                          ? spot.address
                          : "No address provided",
                      style: GoogleFonts.outfit(color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoBadge(
                    label: "₹${spot.pricePerHour}/hr",
                    color: Colors.green,
                    icon: Icons.currency_rupee,
                  ),
                  _InfoBadge(
                    label: "${spot.availableSpots} Slots",
                    color: spot.availableSpots > 0 ? Colors.blue : Colors.red,
                    icon: Icons.local_parking,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startNavigation(spot);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Directions",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startNavigation(ParkingSpot spot) async {
    setState(() {
      _isNavigating = true;
    });

    try {
      // 1. Get User Location
      final userPos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      // 2. Fetch Route
      final startLng = userPos.longitude;
      final startLat = userPos.latitude;
      final endLng = spot.longitude;
      final endLat = spot.latitude;

      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/driving/$startLng,$startLat;$endLng,$endLat?access_token=$kMapboxAccessToken&geometries=geojson&overview=full',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // 3. Draw Polyline
          if (_polylineAnnotationManager != null) {
            await _polylineAnnotationManager!.deleteAll();
            final List<Point> points = coordinates
                .map((c) => Point(coordinates: Position(c[0], c[1])))
                .toList();

            await _polylineAnnotationManager!.create(
              PolylineAnnotationOptions(
                geometry: LineString(
                  coordinates: points.map((p) => p.coordinates).toList(),
                ),
                lineColor: Colors.blue.toARGB32(),
                lineWidth: 5.0,
                lineJoin: LineJoin.ROUND,
              ),
            );
          }

          // 4. Fit Camera
          // Calculate Bounds
          double minLat = startLat < endLat ? startLat : endLat;
          double maxLat = startLat > endLat ? startLat : endLat;
          double minLng = startLng < endLng ? startLng : endLng;
          double maxLng = startLng > endLng ? startLng : endLng;

          // Padding
          final cameraOptions = await _mapboxMap?.cameraForCoordinateBounds(
            CoordinateBounds(
              southwest: Point(coordinates: Position(minLng, minLat)),
              northeast: Point(coordinates: Position(maxLng, maxLat)),
              infiniteBounds: false,
            ),
            MbxEdgeInsets(top: 100, left: 50, bottom: 100, right: 50),
            0,
            0,
            null,
            null,
          );

          if (cameraOptions != null) {
            _mapboxMap?.flyTo(
              cameraOptions,
              MapAnimationOptions(duration: 1000),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error starting navigation: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Find Parking", style: GoogleFonts.outfit()),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          if (_isNavigating)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isNavigating = false;
                });
                _polylineAnnotationManager?.deleteAll();
                _mapboxMap?.flyTo(
                  CameraOptions(
                    center: Point(
                      coordinates: Position(kRajkotLng, kRajkotLat),
                    ),
                    zoom: 13.0,
                  ),
                  MapAnimationOptions(duration: 1000),
                );
              },
            ),
        ],
      ),
      body: MapWidget(
        key: const ValueKey("MapboxParkingMap"),
        cameraOptions: CameraOptions(
          center: Point(coordinates: Position(kRajkotLng, kRajkotLat)),
          zoom: 13.0,
        ),
        styleUri: MapboxStyles.MAPBOX_STREETS,
        textureView: true,
        onMapCreated: _onMapCreated,
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _InfoBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: deprecated_member_use
class AnnotationClickListener extends OnPointAnnotationClickListener {
  final Function(PointAnnotation) onAnnotationClick;

  AnnotationClickListener({required this.onAnnotationClick});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}
