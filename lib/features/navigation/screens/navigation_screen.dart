import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:location/location.dart' as loc;
import 'package:google_fonts/google_fonts.dart';

import 'package:parkwise/features/parking/services/parking_firestore_service.dart';
import 'package:parkwise/features/parking/models/parking_spot.dart';

import 'package:http/http.dart' as http;
import 'dart:convert'; // for jsonEncode
import 'dart:async'; // For Timer

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  // -------------------------------------------------------------------------
  // Access Token from .env
  // -------------------------------------------------------------------------
  final String kMapboxAccessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
  // -------------------------------------------------------------------------

  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  bool _isPermissionGranted = false;

  // Search Expand State
  bool _isSearchExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];
  Timer? _debounce;
  geo.Position? _currentUserPosition;

  // Location Details & Routing
  Map<String, dynamic>? _selectedLocation;
  String? _routeDuration;
  String? _routeDistance;
  bool _isFetchingRoute = false;

  final ParkingFirestoreService _parkingService = ParkingFirestoreService();
  StreamSubscription<List<ParkingSpot>>? _spotsSubscription;
  final Map<String, ParkingSpot> _annotationIdToSpot = {};
  bool _hasInitialCameraFit = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _spotsSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool serviceEnabled;
    geo.LocationPermission permission;
    loc.Location location = loc.Location();

    // 1. Check if location services are enabled.
    serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Try to request service (shows system popup on Android)
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }
    }

    // 2. Check permissions using Geolocator (or Location, but keeping Geolocator for consistency)
    permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: geo.Geolocator.openAppSettings,
            ),
          ),
        );
      }
      return;
    }

    // 3. Permissions granted.
    setState(() {
      _isPermissionGranted = true;
    });

    if (_isPermissionGranted && _mapboxMap != null) {
      _enableLocationComponent();
      _centerCameraOnUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set the access token globally before creating the map
    MapboxOptions.setAccessToken(kMapboxAccessToken);

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            cameraOptions: CameraOptions(zoom: 14.0),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            textureView: true,
            onMapCreated: _onMapCreated,
            onTapListener: (context) =>
                _onMapTap(context.touchPosition), // Use built-in listener
          ),
          Positioned(
            top: 60,
            left: 24,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              width: _isSearchExpanded
                  ? MediaQuery.of(context).size.width - 48
                  : 50,
              height: _isSearchExpanded && _suggestions.isNotEmpty ? 300 : 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  // Search Bar
                  SizedBox(
                    height: 50,
                    child: Stack(
                      children: [
                        // Text Field
                        if (_isSearchExpanded)
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 50,
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: false,
                                  decoration: InputDecoration(
                                    hintText: 'Where to park ??',
                                    hintStyle: GoogleFonts.outfit(
                                      color: Colors.grey,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                  style: GoogleFonts.outfit(
                                    color: Colors.black87,
                                  ),
                                  onChanged: _onSearchChanged,
                                  onSubmitted: (value) {
                                    if (value.isNotEmpty &&
                                        _suggestions.isNotEmpty) {
                                      _selectSuggestion(_suggestions.first);
                                    } else if (value.isNotEmpty) {
                                      _searchLocation(value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),

                        if (_isSearchExpanded &&
                            _searchController.text.isNotEmpty)
                          Positioned(
                            right: 50,
                            top: 0,
                            bottom: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _suggestions = [];
                                  _selectedLocation = null; // Clear selection
                                  _routeDuration = null;
                                  _routeDistance = null;
                                });
                              },
                            ),
                          ),

                        // Search Icon
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          left: _isSearchExpanded
                              ? (MediaQuery.of(context).size.width - 48) - 50
                              : 0,
                          top: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isSearchExpanded = !_isSearchExpanded;
                                if (!_isSearchExpanded) {
                                  _searchController.clear();
                                  FocusScope.of(context).unfocus();
                                  _suggestions = [];
                                }
                              });
                            },
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(
                                begin: 0,
                                end: _isSearchExpanded ? 1 : 0,
                              ),
                              duration: const Duration(milliseconds: 400),
                              builder: (context, double value, child) {
                                return Transform.rotate(
                                  angle: value * 2 * 3.14159,
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.search,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Suggestions List
                  if (_isSearchExpanded && _suggestions.isNotEmpty)
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          final placeName = suggestion['place_name'] as String;
                          return ListTile(
                            dense: true,
                            title: Text(
                              placeName,
                              style: GoogleFonts.outfit(color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: const Icon(
                              Icons.location_on_outlined,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onTap: () => _selectSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: _selectedLocation != null
                ? 360
                : 140, // Adjust position when card is visible (120 bottom + ~240 card height)
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // North Button
                FloatingActionButton(
                  heroTag: "north_btn",
                  onPressed: _resetNorth,
                  backgroundColor: Colors.white,
                  mini:
                      true, // Smaller size for North button? Or consistent? User said "just above"
                  shape: const CircleBorder(), // Circular
                  child: const Icon(
                    Icons.explore_outlined,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Location Button
                FloatingActionButton(
                  heroTag: "loc_btn",
                  onPressed: _centerCameraOnUser,
                  backgroundColor: Colors.white,
                  shape: const CircleBorder(), // Circular
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ],
            ),
          ),

          // Location Details Card (Google Maps Style)
          if (_selectedLocation != null)
            Positioned(
              left: 0,
              right: 0,
              bottom:
                  120, // Moved up to avoid covering navbar (approx 80-100 height)
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Place Name
                    Text(
                      _selectedLocation?['place_name']?.split(',')[0] ??
                          "Unknown Place",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Firestore Data (Price & Availability)
                    if (_selectedLocation?['type'] == 'firestore' &&
                        _selectedLocation?['properties']?['data']
                            is ParkingSpot) ...[
                      Builder(
                        builder: (context) {
                          final spot =
                              _selectedLocation!['properties']['data']
                                  as ParkingSpot;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Price
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.green[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      "₹${spot.pricePerHour}/hr",
                                      style: GoogleFonts.outfit(
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Availability
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: spot.availableSpots > 0
                                          ? Colors.blue[50]
                                          : Colors.red[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: spot.availableSpots > 0
                                            ? Colors.blue[200]!
                                            : Colors.red[200]!,
                                      ),
                                    ),
                                    child: Text(
                                      "${spot.availableSpots} Slots Left",
                                      style: GoogleFonts.outfit(
                                        color: spot.availableSpots > 0
                                            ? Colors.blue[800]
                                            : Colors.red[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Full Address
                    Text(
                      _selectedLocation?['place_name'] ?? "",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Route Info (Time & Distance)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50], // Light blue bg
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isFetchingRoute)
                              Text(
                                "Calculating...",
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange,
                                ),
                              )
                            else if (_routeDuration != null)
                              Row(
                                children: [
                                  Text(
                                    _routeDuration!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700], // Traffic green
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "($_routeDistance)",
                                    style: GoogleFonts.outfit(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                "Route info unavailable",
                                style: GoogleFonts.outfit(color: Colors.grey),
                              ),
                            Text(
                              "Fastest route now due to traffic conditions",
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigation start logic
                              debugPrint("Starting navigation simulation...");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Navigation Started!'),
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Navigation started!"),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _suggestions = [];
                              _selectedLocation = null;
                              _routeDuration = null;
                              _routeDistance = null;
                            });
                            // Reload all spots when clearing search
                            _loadParkingSpots();
                          },
                          style: OutlinedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(14),
                          ),
                          child: const Icon(Icons.close, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10), // Safe area padding simulation
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Hide default ornaments
    _mapboxMap?.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    _mapboxMap?.compass.updateSettings(CompassSettings(enabled: false));
    _mapboxMap?.attribution.updateSettings(AttributionSettings(enabled: false));
    _mapboxMap?.logo.updateSettings(LogoSettings(enabled: false));

    if (_isPermissionGranted) {
      _enableLocationComponent();
      _centerCameraOnUser();
    }

    _mapboxMap?.annotations.createPointAnnotationManager().then((manager) {
      _pointAnnotationManager = manager;

      // Load spots initially
      _loadParkingSpots();

      // Handle Marker Clicks
      // ignore: deprecated_member_use
      _pointAnnotationManager?.addOnPointAnnotationClickListener(
        AnnotationClickListener(
          onAnnotationClick: (annotation) {
            final spot = _annotationIdToSpot[annotation.id];
            if (spot != null) {
              _onSpotSelected(spot, annotation);
            }
          },
        ),
      );
    });

    _mapboxMap?.annotations.createPolylineAnnotationManager().then((manager) {
      _polylineAnnotationManager = manager;
    });
  }

  void _onMapTap(ScreenCoordinate screenCoordinate) async {
    try {
      // Query Rendered Features for POIs
      // 'poi-label' is the standard layer for POIs in Mapbox Streets
      final features = await _mapboxMap?.queryRenderedFeatures(
        RenderedQueryGeometry.fromScreenCoordinate(screenCoordinate),
        RenderedQueryOptions(layerIds: ['poi-label'], filter: null),
      );

      if (features != null && features.isNotEmpty) {
        // Get the first feature
        final feature = features.first;
        final properties =
            feature?.queriedFeature.feature['properties'] as Map?;
        final name = properties?['name'] as String?;

        if (name != null) {
          // We don't have exact Point from ScreenCoordinate easily without conversion,
          // but we can just show the popup.
          // Or convert screenCoordinate to Point if needed for something else.
          _showPlacePopup(name);
        }
      }
    } catch (e) {
      debugPrint("Error handling map click: $e");
    }
  }

  void _showPlacePopup(String name) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Place Details",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // Optional: Add actions like "Navigate" here
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Placeholder for navigate action
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text("Navigate Here"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _enableLocationComponent() async {
    try {
      await _mapboxMap?.location.updateSettings(
        LocationComponentSettings(enabled: true, pulsingEnabled: true),
      );
    } catch (e) {
      debugPrint("Error enabling location component: $e");
    }
  }

  Future<void> _resetNorth() async {
    _mapboxMap?.flyTo(
      CameraOptions(bearing: 0, pitch: 0),
      MapAnimationOptions(duration: 500),
    );
  }

  Future<void> _centerCameraOnUser() async {
    try {
      if (!_isPermissionGranted) {
        await _checkPermission();
        if (!_isPermissionGranted) return;
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      _currentUserPosition = position;

      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 15.0,
          bearing: 0,
        ),
        MapAnimationOptions(duration: 500),
      );
    } catch (e) {
      debugPrint("Error centering camera: $e");
    }
  }

  Future<void> _searchLocation(String query) async {
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$kMapboxAccessToken&bbox=68.16238,20.13715,74.51680,24.70839',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final feature = data['features'][0];
          final center = feature['center']; // [longitude, latitude]
          final double lng = center[0];
          final double lat = center[1];
          // final String placeName = feature['place_name'] ?? query; // Unused

          // Fly to location
          _mapboxMap?.flyTo(
            CameraOptions(
              center: Point(coordinates: Position(lng, lat)),
              zoom: 14.0,
            ),
            MapAnimationOptions(duration: 1000),
          );

          if (mounted) {
            setState(() {
              _selectedLocation = feature;
            });
            if (_currentUserPosition != null) {
              _fetchRoute(_currentUserPosition!, Position(lng, lat));
            }
          }

          // Add Marker
          if (_pointAnnotationManager != null) {
            _pointAnnotationManager?.deleteAll();
            _pointAnnotationManager?.create(
              PointAnnotationOptions(
                geometry: Point(coordinates: Position(lng, lat)),
                iconImage: "marker-15",
                // ignore: deprecated_member_use
                iconColor: Colors.red.value, // User requested RED marker
                iconSize: 2.0, // Make it slightly larger
              ),
            );
          }
        } else {
          // SnackBar block removed as per instruction.
        }
      }
    } catch (e) {
      debugPrint("Error searching location: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _getSuggestions(query);
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  Future<void> _getSuggestions(String query) async {
    List<Map<String, dynamic>> finalSuggestions = [];

    // 1. Fetch from Firestore
    try {
      final firestoreSpots = await _parkingService.searchParkingSpots(query);
      final firestoreSuggestions = firestoreSpots.map((spot) {
        return {
          'type': 'firestore',
          'id': spot.id,
          'place_name': spot.name,
          'center': [spot.longitude, spot.latitude],
          'properties': {'address': spot.address, 'data': spot},
          'geometry': {
            'type': 'Point',
            'coordinates': [spot.longitude, spot.latitude],
          },
        };
      }).toList();
      finalSuggestions.addAll(firestoreSuggestions);
    } catch (e) {
      debugPrint("Error fetching firestore suggestions: $e");
    }

    // 2. Fetch from Mapbox
    String proximity = '';
    if (_currentUserPosition != null) {
      proximity =
          '&proximity=${_currentUserPosition!.longitude},${_currentUserPosition!.latitude}';
    }

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$kMapboxAccessToken&bbox=68.16238,20.13715,74.51680,24.70839&autocomplete=true$proximity',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null) {
          final mapboxSuggestions = List<Map<String, dynamic>>.from(
            data['features'],
          );
          // Tag them?
          for (var s in mapboxSuggestions) {
            s['type'] = 'mapbox';
          }
          finalSuggestions.addAll(mapboxSuggestions);
        }
      }
    } catch (e) {
      debugPrint("Error fetching mapbox suggestions: $e");
    }

    if (mounted) {
      setState(() {
        _suggestions = finalSuggestions;
      });
    }
  }

  void _selectSuggestion(Map<String, dynamic> feature) {
    final center = feature['center']; // [longitude, latitude]
    final double lng = center[0];
    final double lat = center[1];

    _mapboxMap?.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 14.0),
      MapAnimationOptions(duration: 1000),
    );

    if (_pointAnnotationManager != null) {
      _pointAnnotationManager?.deleteAll();
      _pointAnnotationManager?.create(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          iconImage: "marker-15",
          // ignore: deprecated_member_use
          iconColor: Colors.red.value, // User requested RED marker
          iconSize: 2.0, // Make it slightly larger
        ),
      );
    }

    // Clear selections and keyboard
    FocusScope.of(context).unfocus();
    setState(() {
      _suggestions = [];
      _searchController.text = feature['place_name'] ?? '';
      _isSearchExpanded = false;
      _selectedLocation = feature; // Set selected location
    });

    // Fetch Route
    if (_currentUserPosition != null) {
      _fetchRoute(_currentUserPosition!, Position(lng, lat));
    }
  }

  Future<void> _fetchRoute(geo.Position start, Position end) async {
    setState(() {
      _isFetchingRoute = true;
      _routeDuration = null;
      _routeDistance = null;
    });

    // Mapbox Directions API (Driving with Traffic)
    // profile: mapbox/driving-traffic
    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/${start.longitude},${start.latitude};${end.lng},${end.lat}?access_token=$kMapboxAccessToken&overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final durationSeconds = route['duration']; // in seconds
          final distanceMeters = route['distance']; // in meters
          final geometry = route['geometry']; // GeoJSON

          // Draw Route
          _drawRoute(geometry);

          // Format Time

          // Format Time
          String durationText;
          if (durationSeconds < 60) {
            durationText = "${durationSeconds.round()} sec";
          } else if (durationSeconds < 3600) {
            durationText = "${(durationSeconds / 60).round()} min";
          } else {
            final hours = (durationSeconds / 3600).floor();
            final minutes = ((durationSeconds % 3600) / 60).round();
            durationText = "$hours hr $minutes min";
          }

          // Format Distance
          String distanceText;
          if (distanceMeters < 1000) {
            distanceText = "${distanceMeters.round()} m";
          } else {
            distanceText = "${(distanceMeters / 1000).toStringAsFixed(1)} km";
          }

          if (mounted) {
            setState(() {
              _routeDuration = durationText;
              _routeDistance = distanceText;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingRoute = false;
        });
      }
    }
  }

  Future<void> _drawRoute(Map<String, dynamic> geometry) async {
    if (_polylineAnnotationManager == null) return;

    await _polylineAnnotationManager?.deleteAll();

    final coordinates = geometry['coordinates'] as List;
    final List<Point> routePoints = coordinates
        .map((c) => Point(coordinates: Position(c[0], c[1])))
        .toList();

    // Create Polyline
    await _polylineAnnotationManager?.create(
      PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: routePoints.map((p) => p.coordinates).toList(),
        ),
        // ignore: deprecated_member_use
        lineColor: Colors.blue.value, // int value
        lineWidth: 5.0,
        lineOpacity: 0.8,
      ),
    );

    // Fit Camera
    final latLngs = coordinates.map((c) => [c[1], c[0]]).toList(); // lat, lng
    if (latLngs.isEmpty) return;

    // Simple bounding box calculation
    double minLat = latLngs[0][0];
    double maxLat = latLngs[0][0];
    double minLng = latLngs[0][1];
    double maxLng = latLngs[0][1];

    for (var point in latLngs) {
      if (point[0] < minLat) minLat = point[0];
      if (point[0] > maxLat) maxLat = point[0];
      if (point[1] < minLng) minLng = point[1];
      if (point[1] > maxLng) maxLng = point[1];
    }

    // Add padding
    final cameraOptions = await _mapboxMap?.cameraForCoordinateBounds(
      CoordinateBounds(
        southwest: Point(coordinates: Position(minLng, minLat)),
        northeast: Point(coordinates: Position(maxLng, maxLat)),
        infiniteBounds: false,
      ),
      MbxEdgeInsets(
        top: 50,
        left: 50,
        bottom: 350,
        right: 50,
      ), // bottom padding for card
      null,
      null,
      null,
      null,
    );

    if (cameraOptions != null) {
      _mapboxMap?.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
    }
  }

  void _loadParkingSpots() {
    _spotsSubscription?.cancel();
    _spotsSubscription = _parkingService.getParkingSpots().listen((
      spots,
    ) async {
      if (_selectedLocation == null && _pointAnnotationManager != null) {
        // Only auto-refresh if we are not focused on a search result
        await _renderMarkers(spots);
      }
    });
  }

  Future<void> _renderMarkers(List<ParkingSpot> spots) async {
    if (_pointAnnotationManager == null) return;
    await _pointAnnotationManager?.deleteAll();
    _annotationIdToSpot.clear();

    final options = spots
        .map(
          (spot) => PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(spot.longitude, spot.latitude),
            ),
            iconImage: "marker-15",
            // ignore: deprecated_member_use
            iconColor: Colors.blue.value, // Default color for all spots
            iconSize: 1.5,
          ),
        )
        .toList();

    final annotations = await _pointAnnotationManager?.createMulti(options);

    if (annotations != null) {
      for (int i = 0; i < annotations.length; i++) {
        if (annotations[i] != null) {
          _annotationIdToSpot[annotations[i]!.id] = spots[i];
        }
      }
    }

    if (!_hasInitialCameraFit && spots.isNotEmpty) {
      _hasInitialCameraFit = true;
      // Calculate bounds
      double minLat = spots.first.latitude;
      double maxLat = spots.first.latitude;
      double minLng = spots.first.longitude;
      double maxLng = spots.first.longitude;

      for (var spot in spots) {
        if (spot.latitude < minLat) minLat = spot.latitude;
        if (spot.latitude > maxLat) maxLat = spot.latitude;
        if (spot.longitude < minLng) minLng = spot.longitude;
        if (spot.longitude > maxLng) maxLng = spot.longitude;
      }

      // Add some padding
      final cameraOptions = await _mapboxMap?.cameraForCoordinateBounds(
        CoordinateBounds(
          southwest: Point(coordinates: Position(minLng, minLat)),
          northeast: Point(coordinates: Position(maxLng, maxLat)),
          infiniteBounds: false,
        ),
        MbxEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
        0, // bearing
        0, // pitch
        null, // maxZoom
        null, // offset
      );

      if (cameraOptions != null) {
        _mapboxMap?.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
      }
    }
  }

  void _onSpotSelected(ParkingSpot spot, PointAnnotation annotation) {
    // Highlight
    _pointAnnotationManager?.deleteAll();

    _pointAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(spot.longitude, spot.latitude)),
        iconImage: "marker-15",
        // ignore: deprecated_member_use
        iconColor: Colors.red.value,
        iconSize: 2.0,
      ),
    );

    // Fly To
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(spot.longitude, spot.latitude)),
        zoom: 15.0,
      ),
      MapAnimationOptions(duration: 1000),
    );

    // Show Card
    setState(() {
      _selectedLocation = {
        'type': 'firestore',
        'place_name': spot.name,
        'center': [spot.longitude, spot.latitude],
        'properties': {'data': spot, 'address': spot.address},
      };
    });

    // Fetch Route
    _fetchRoute(
      _currentUserPosition != null
          ? _currentUserPosition!
          : geo.Position(
              longitude: 72.5714,
              latitude: 23.0225,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            ),
      Position(spot.longitude, spot.latitude),
    );
  }

  // Seed data method removed. Using real firestore data.
}

// ignore: deprecated_member_use
class AnnotationClickListener implements OnPointAnnotationClickListener {
  final Function(PointAnnotation) onAnnotationClick;
  AnnotationClickListener({required this.onAnnotationClick});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}
