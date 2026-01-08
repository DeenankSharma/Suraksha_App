import 'dart:developer' as dev;

import 'package:flutter_setup/data/models/auth_data_model.dart';
import 'package:flutter_setup/data/services/apis.dart';
import 'package:flutter_setup/utils/get_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  /// Main entry point to trigger the emergency flow
  Future<void> triggerSOS() async {
    try {
      dev.log("SOS Service: Triggering emergency sequence...");

      // 1. Get User Phone Number from AuthData
      const String prefsKey = 'auth_data';
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? authJson = prefs.getString(prefsKey);

      if (authJson == null) {
        dev.log("SOS Service Error: No user session found");
        return;
      }

      final authData = AuthData.fromJson(authJson);
      final String phoneNumber = authData.phoneNumber;

      // 2. Get Location
      dev.log("SOS Service: Fetching location...");
      Map<String, dynamic>? locationData = await getLocation();
      dev.log("SOS Service: Location fetched: $locationData");

      // 3. Log to Backend API
      ApiService api = ApiService();
      final response = await api.logEmergency(
        phoneNumber: phoneNumber,
        longitude: locationData?['longitude'],
        latitude: locationData?['latitude'],
      );
      dev.log("SOS Service: Backend logged response: ${response.toString()}");

      dev.log("SOS Service: Emergency sequence completed successfully");
    } catch (e) {
      dev.log("SOS Service Error: $e");
    }
  }
}
