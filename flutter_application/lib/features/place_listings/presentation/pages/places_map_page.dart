import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../core/logging/app_logger.dart';
import '../../../../core/monitoring/sentry_monitoring.dart';

class PlacesMapPage extends StatefulWidget {
  const PlacesMapPage({Key? key}) : super(key: key);

  @override
  State<PlacesMapPage> createState() => _PlacesMapPageState();
}

class _PlacesMapPageState extends State<PlacesMapPage> {
  late final Future<PmTilesVectorTileProvider> _baseTileProvider;
  late final Future<PmTilesVectorTileProvider> _overturePlacesTileProvider;
  List<LatLng> boundaryPoints = [];

  @override
  void initState() {
    super.initState();
    // Initialize base map PMTiles provider
    _baseTileProvider = PmTilesVectorTileProvider.fromSource(
      'https://kmisqlvoiofymxicxiwv.supabase.co/storage/v1/object/public/maps/amaravati_base.pmtiles',
    );

    // Initialize Overture places PMTiles provider
    _overturePlacesTileProvider = PmTilesVectorTileProvider.fromSource(
      'https://kmisqlvoiofymxicxiwv.supabase.co/storage/v1/object/public/maps/amaravati_places_2024-11-13.pmtiles',
    );

    _loadGeoJson();
  }

  Future<void> _loadGeoJson() async {
    try {
      AppLogger.info('Loading GeoJSON file');
      final String geoJsonString = await rootBundle
          .loadString('assets/maps/amaravati-outline-polygon.geojson');

      AppLogger.debug(
          'GeoJSON content: ${geoJsonString.substring(0, 100)}...'); // Log first 100 chars

      final Map<String, dynamic> geoJson = json.decode(geoJsonString);

      AppLogger.debug('GeoJSON type: ${geoJson['type']}');
      AppLogger.debug('Geometry type: ${geoJson['geometry']?['type']}');

      if (geoJson['type'] == 'Feature' &&
          geoJson['geometry']['type'] == 'Polygon') {
        final coordinates = geoJson['geometry']['coordinates'][0] as List;
        boundaryPoints = coordinates
            .map((coord) {
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            })
            .toList()
            .cast<LatLng>();

        AppLogger.info(
            'Successfully loaded boundary points: ${boundaryPoints.length} points');
        AppLogger.debug(
            'First point: ${boundaryPoints.first}, Last point: ${boundaryPoints.last}');

        if (mounted) {
          setState(() {});
        }
      } else {
        AppLogger.warning('Unexpected GeoJSON structure');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error loading GeoJSON: $e');
      await SentryMonitoring.captureException(e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<PmTilesVectorTileProvider>>(
        future: Future.wait([_baseTileProvider, _overturePlacesTileProvider]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            AppLogger.error('Error loading tile providers: ${snapshot.error}');
            return const Center(child: Text('Error loading map'));
          }

          if (snapshot.hasData) {
            final providers = snapshot.data!;
            return FlutterMap(
              options: const MapOptions(
                initialCenter: const LatLng(16.393872, 80.512708),
                initialZoom: 10.0,
              ),
              children: [
                // Base map layer
                VectorTileLayer(
                  tileProviders: TileProviders({
                    'protomaps': providers[0],
                  }),
                  theme: ProtomapsThemes.light(),
                ),

                // Overture places layer
                VectorTileLayer(
                  tileProviders: TileProviders({
                    'place': providers[1],
                  }),
                  theme: ProtomapsThemes.light(),
                ),

                if (boundaryPoints.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: boundaryPoints,
                        color: Colors.blue.withOpacity(0.2),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 3,
                        isDotted: true,
                      ),
                    ],
                  ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
