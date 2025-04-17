import 'package:location/location.dart';
import 'dnd_service.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  Location location = Location();
  final DndService _dndService = DndService();
  Future<Map<String, double>> getCurrentLocation() async {
    final data = await location.getLocation();
    return {"latitude": data.latitude ?? 0, "longitude": data.longitude ?? 0};
  }

  Future<double?> getCurrentSpeed() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          debugPrint("Location service is disabled.");
          return null;
        }
      }

      PermissionStatus permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
        if (permission != PermissionStatus.granted) {
          debugPrint("Location permission denied.");
          return null;
        }
      }

      LocationData data = await location.getLocation();
      double? speedKmph = (data.speed ?? 0) * 3.6; // Convert m/s to km/h

      return speedKmph;
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    }
  }
}
