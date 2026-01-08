import 'dart:async';
import 'dart:developer';

import 'package:location/location.dart';

Future<Map<String, double>?> getLocation() async {
  try {
    log("Getting location");
    Location location = Location();

    // --- CRITICAL FIX FOR BACKGROUND ---
    // 1. Enable background mode to allow fetching while locked/minimized
    try {
      await location.enableBackgroundMode(enable: true);
      log("Background mode enabled");
    } catch (e) {
      log("Could not enable background mode: $e");
    }

    // 2. Change Settings for faster lock (High Accuracy)
    await location.changeSettings(
        accuracy: LocationAccuracy.high, // Force GPS
        interval: 1000, // Update every 1s
        distanceFilter: 0 // Update on any movement
        );
    // ----------------------------------

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return null;
    }

    log("Fetching location...");
    // Increased timeout to 15s because GPS cold lock takes time
    locationData = await location.getLocation().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException('Location fetch timed out');
      },
    );

    log("Location: ${locationData.latitude}, ${locationData.longitude}");

    return {
      'latitude': locationData.latitude ?? 0.0,
      'longitude': locationData.longitude ?? 0.0,
    };
  } catch (e) {
    log("Error in getLocation: $e");
    return null;
  }
}
