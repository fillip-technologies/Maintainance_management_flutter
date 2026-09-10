import 'package:geolocator/geolocator.dart';

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationResult {
  final double? latitude;
  final double? longitude;
  final LocationErrorType? error;
  final String? errorMessage;

  const LocationResult.success(this.latitude, this.longitude)
      : error = null,
        errorMessage = null;

  const LocationResult.failure(this.error, this.errorMessage)
      : latitude = null,
        longitude = null;

  bool get isSuccess => latitude != null && longitude != null;
}

class LocationHelper {
  /// Simple backward-compatible map retrieval.
  Future<Map<String, dynamic>?> getUserLocation() async {
    final res = await getLocation();
    if (res.isSuccess) {
      return {'latitude': res.latitude, 'longitude': res.longitude};
    }
    return null;
  }

  /// Comprehensive location fetch with detailed error reporting.
  Future<LocationResult> getLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.failure(
          LocationErrorType.serviceDisabled,
          'Location (GPS) is turned off on this device.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationResult.failure(
            LocationErrorType.permissionDenied,
            'Location permission was denied.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
          LocationErrorType.permissionDeniedForever,
          'Location permission is permanently denied. Please enable it in Settings.',
        );
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position == null) {
        return const LocationResult.failure(
          LocationErrorType.unknown,
          'Unable to acquire current GPS coordinates. Please ensure GPS is active.',
        );
      }

      return LocationResult.success(position.latitude, position.longitude);
    } catch (e) {
      return LocationResult.failure(
        LocationErrorType.unknown,
        'Could not acquire GPS position: $e',
      );
    }
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
  Future<bool> openAppSettings() => Geolocator.openAppSettings();
}
