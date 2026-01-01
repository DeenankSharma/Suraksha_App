import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestBLEPermissions() async {
  try {
    if (Platform.isAndroid) {
      // Request notification permission
      await Permission.notification.request();
      
      // Request Bluetooth permissions
      final bluetoothScanStatus = await Permission.bluetoothScan.request();
      final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      
      // Request location permission
      final locationStatus = await Permission.location.request();
      
      print('BLE Permissions Status:');
      print('  Notification: ${await Permission.notification.status}');
      print('  Bluetooth Scan: $bluetoothScanStatus');
      print('  Bluetooth Connect: $bluetoothConnectStatus');
      print('  Location: $locationStatus');
      
      final isGranted = bluetoothScanStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          locationStatus.isGranted;
      
      return isGranted;
    } else if (Platform.isIOS) {
      final bluetoothStatus = await Permission.bluetooth.request();
      print('BLE Permission Status (iOS): $bluetoothStatus');
      return bluetoothStatus.isGranted;
    }
    return false;
  } catch (e) {
    print('Error requesting BLE permissions: $e');
    return false;
  }
}

Future<bool> checkBLEPermissions() async {
  try {
    if (Platform.isAndroid) {
      final bluetoothScan = await Permission.bluetoothScan.status;
      final bluetoothConnect = await Permission.bluetoothConnect.status;
      final location = await Permission.location.status;
      
      return bluetoothScan.isGranted &&
          bluetoothConnect.isGranted &&
          location.isGranted;
    } else if (Platform.isIOS) {
      final bluetooth = await Permission.bluetooth.status;
      return bluetooth.isGranted;
    }
    return false;
  } catch (e) {
    print('Error checking BLE permissions: $e');
    return false;
  }
}

