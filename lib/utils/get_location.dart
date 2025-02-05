import 'dart:async';
import 'dart:developer';

import 'package:location/location.dart';

Future<Map<String, double>?> getLocation() async {
  try {
    log("Getting location");
    Location location = Location();
    log("Location object created");

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    log("Service enabled status: $serviceEnabled");
    if (!serviceEnabled) {
      log("Service not enabled, requesting service");
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        log("Service still not enabled, returning null");
        return null;
      }
    }
    log("Service enabled");

    permissionGranted = await location.hasPermission();
    log("Current permission status: $permissionGranted");
    if (permissionGranted == PermissionStatus.denied) {
      log("Permission denied, requesting permission");
      permissionGranted = await location.requestPermission();
      log("New permission status after request: $permissionGranted");
      if (permissionGranted != PermissionStatus.granted) {
        log("Permission still denied, returning null");
        return null;
      }
    }
    log("Permission granted");

    log("About to get location data");
    log("Inside try block");
    locationData = await location.getLocation().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        log("Location fetch timed out");
        throw TimeoutException('Location fetch timed out');
      },
    );
    log("After location.getLocation()"); // New log to debug
    log("Location data retrieved successfully");
    log("Location data - Latitude: ${locationData.latitude}");
    log("Location data - Longitude: ${locationData.longitude}");

    return {
      'latitude': locationData.latitude ?? 0.0,
      'longitude': locationData.longitude ?? 0.0,
    };
  } catch (e, stackTrace) {
    log("Error in getLocation: $e");
    log("Stack trace: $stackTrace");
    return null;
  }
}
