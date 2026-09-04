import 'package:equipment_management_system/features/location/location_helper.dart';
import 'package:flutter/material.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final LocationHelper _locationHelper = LocationHelper();
  Map<String, dynamic>? _userLocation;

  Future<void> getLoation() async {
    final location = await _locationHelper.getUserLocation();
    if (location != null) {
      setState(() {
        _userLocation = location;
        debugPrint(
          'User Location: ${location['latitude']}, ${location['longitude']}',
        );
      });
      setState(() {});
    } else {
      debugPrint('Failed to get user location.');
    }
  }

  @override
  void initState() {
    super.initState();
    getLoation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Page')),
      body: Column(
        children: [
          if (_userLocation != null) ...[
            Text('Latitude: ${_userLocation!['latitude']}'),
            Text('Longitude: ${_userLocation!['longitude']}'),
          ] else ...[
            const CircularProgressIndicator(),
          ],
        ],
      ),
    );
  }
}
