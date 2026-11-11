import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  static const LatLng fallback = LatLng(-12.0463731, -77.042754);

  Future<bool> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  Future<LatLng?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(timeLimit: Duration(seconds: 10)),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }
}
