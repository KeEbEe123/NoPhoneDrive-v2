import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late MapController controller;

  @override
  void initState() {
    super.initState();
    controller = MapController.withUserPosition(
      trackUserLocation: const UserTrackingOption(
        enableTracking: true,
        unFollowUser: false,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Map"),
        backgroundColor: Colors.blueAccent,
      ),
      body: OSMFlutter(
        controller: controller,
        osmOption: OSMOption(
          enableRotationByGesture: true,
          showZoomController: true,
          userTrackingOption: const UserTrackingOption(
            enableTracking: true,
            unFollowUser: false,
          ),
          zoomOption: const ZoomOption(
            initZoom: 16,
            minZoomLevel: 2,
            maxZoomLevel: 18,
            stepZoom: 1.0,
          ),
          userLocationMarker: UserLocationMaker(
            personMarker: MarkerIcon(
              icon: Icon(Icons.person_pin_circle, color: Colors.red, size: 64),
            ),
            directionArrowMarker: MarkerIcon(
              icon: Icon(Icons.navigation, color: Colors.blue, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
