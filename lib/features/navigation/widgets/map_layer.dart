import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:parkwise/features/navigation/providers/map_provider.dart';

class MapLayer extends StatefulWidget {
  final bool isDark;
  const MapLayer({super.key, required this.isDark});

  @override
  State<MapLayer> createState() => _MapLayerState();
}

class _MapLayerState extends State<MapLayer> {
  MapboxMap? _mapboxMap;
  bool _isMapLoading = true;

  @override
  void didUpdateWidget(MapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 🎨 Dynamic theme switching without rebuilding the MapWidget
    if (widget.isDark != oldWidget.isDark) {
      _mapboxMap?.loadStyleURI(
        widget.isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS,
      );
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // ⚙️ Configure Ornaments (Premium UI Cleanup)
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    mapboxMap.logo.updateSettings(LogoSettings(
      position: OrnamentPosition.BOTTOM_LEFT,
      marginLeft: 16.0,
      marginBottom: 32.0,
    ));
    mapboxMap.attribution.updateSettings(AttributionSettings(
      position: OrnamentPosition.BOTTOM_LEFT,
      marginLeft: 60.0,
      marginBottom: 32.0,
    ));

    // 📡 Premium Location Puck Configuration
    await mapboxMap.location.updateSettings(LocationComponentSettings(
      enabled: true,
      pulsingEnabled: true,
      pulsingColor: Colors.blue.withValues(alpha: 0.3).toARGB32(),
      showAccuracyRing: true,
    ));

    // 🛡️ Safe initialization in Provider
    if (mounted) {
      final mapProvider = context.read<MapProvider>();

      // Initialize theme correctly on first load
      await mapboxMap.loadStyleURI(
        widget.isDark ? MapboxStyles.DARK : MapboxStyles.MAPBOX_STREETS,
      );

      // Create Managers ONCE in the Provider
      if (mapProvider.mapboxMap == null) {
        final parkingManager =
            await mapboxMap.annotations.createPointAnnotationManager();
        final polyManager =
            await mapboxMap.annotations.createPolylineAnnotationManager();

        await mapProvider.setMapOptions(
          mapboxMap,
          parkingManager,
          polyManager,
        );

        // Add Tap listener (Only once)
        parkingManager.addOnPointAnnotationClickListener(
          _AnnotationClickListener(onAnnotationClick: (annotation) {
            if (mounted) {
              context.read<MapProvider>().onMarkerTapped(annotation);
            }
          }),
        );
      }

      // ✅ Map is ready — hide loading indicator
      if (mounted) {
        setState(() => _isMapLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 🛑 STABILITY: MapWidget must NOT be wrapped in frequently updating widgets
    return Stack(
      children: [
        MapWidget(
          key: const ValueKey("stable_mapbox_map"),
          onMapCreated: _onMapCreated,
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(72.5714, 23.0225)), // Ahmedabad
            zoom: 12.0,
          ),
          // 🔒 ALWAYS use a stable, constant style here to prevent MapWidget rebuilds.
          // Dynamic style changes are handled via loadStyleURI in didUpdateWidget & onMapCreated.
          styleUri: MapboxStyles.MAPBOX_STREETS,
        ),

        // Loading overlay — fades out once map is initialized
        AnimatedOpacity(
          opacity: _isMapLoading ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: IgnorePointer(
            ignoring: !_isMapLoading,
            child: Container(
              color: colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading map…',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final Function(PointAnnotation) onAnnotationClick;
  _AnnotationClickListener({required this.onAnnotationClick});

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}
