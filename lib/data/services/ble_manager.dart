import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_setup/data/services/sos_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BLEManager {
  static final BLEManager _instance = BLEManager._internal();
  factory BLEManager() => _instance;
  BLEManager._internal();

  // --- Constants from your ESP32 Code ---
  static const String targetDeviceName = "ESP_SPP_SERVER";
  static const String targetServiceUUID = "ABF0"; // spp_service_uuid
  static const String targetCharUUID = "ABF2"; // ESP_GATT_UUID_SPP_DATA_NOTIFY

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? notifyCharacteristic;
  StreamSubscription<List<int>>? characteristicSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionStateSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _reconnectTimer;

  bool _isAutoConnecting = false;
  bool _shouldAutoConnect = true;

  final ValueNotifier<String> statusNotifier = ValueNotifier('Initializing...');
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);

  Future<bool> initialize() async {
    try {
      statusNotifier.value = 'Requesting permissions...';
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        statusNotifier.value = 'Permissions not granted';
        return false;
      }

      statusNotifier.value = 'Permissions granted';
      await _startBackgroundService();
      return true;
    } catch (e) {
      print('Error initializing BLE Manager: $e');
      statusNotifier.value = 'Initialization failed: $e';
      return false;
    }
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
    service
        .invoke('updateContent', {"message": "Suraksha Band Monitor Active"});
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();
      final location = await Permission.location.request();
      return scan.isGranted && connect.isGranted && location.isGranted;
    } else if (Platform.isIOS) {
      return (await Permission.bluetooth.request()).isGranted;
    }
    return false;
  }

  Future<void> startAutoConnect() async {
    if (_isAutoConnecting || !_shouldAutoConnect) return;
    _isAutoConnecting = true;
    statusNotifier.value = 'Searching for Suraksha Band...';

    try {
      // 1. First try to reconnect to a known device ID (faster)
      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString('ble_device_id');

      if (savedDeviceId != null) {
        // Check if already connected in system cache
        final systemDevices = await FlutterBluePlus.connectedDevices;
        for (var d in systemDevices) {
          if (d.remoteId.toString() == savedDeviceId) {
            await _connect(d);
            _isAutoConnecting = false;
            return;
          }
        }
      }

      // 2. If not found, scan for the specific name
      await _scanAndConnect();
    } catch (e) {
      print('Auto-connect error: $e');
      _scheduleReconnect();
    } finally {
      _isAutoConnecting = false;
    }
  }

  Future<void> _scanAndConnect() async {
    _scanSubscription?.cancel();

    print("BLE Manager: Starting scan..."); // Debug Log

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 10),
    );

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        // --- DEBUG PRINT: What devices are we seeing? ---
        if (r.device.platformName.isNotEmpty) {
          print(
              "Found Device: '${r.device.platformName}' (ID: ${r.device.remoteId})");
        }
        // ------------------------------------------------

        if (r.device.platformName == targetDeviceName ||
            r.advertisementData.localName == targetDeviceName) {
          print("!!! MATCH FOUND: Connecting to ${r.device.platformName} !!!");
          await FlutterBluePlus.stopScan();
          await _connect(r.device);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ble_device_id', r.device.remoteId.toString());
          return;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 10));
    // Check if we connected
    if (connectedDevice == null) {
      print("Scan timeout. Device not found. Retrying in 5s...");
      statusNotifier.value = 'Band not found. Retrying...';
      _scheduleReconnect();
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    if (connectedDevice != null) return;

    try {
      connectionStateSubscription?.cancel();
      connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        } else if (state == BluetoothConnectionState.connected) {
          isConnectedNotifier.value = true;
          statusNotifier.value = 'Suraksha Band Connected';
        }
      });

      await device.connect(autoConnect: false); // autoConnect helps on Android
      connectedDevice = device;

      // Update Notification
      FlutterBackgroundService()
          .invoke('updateContent', {"message": "Suraksha Band Connected"});

      await _discoverServices(device);
    } catch (e) {
      print('Connection failed: $e');
      _handleDisconnection();
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      print("the services are");
      print(services);
      for (var service in services) {
        // Check for Service UUID 0xABF0
        if (service.uuid.toString().toUpperCase().contains(targetServiceUUID)) {
          for (var characteristic in service.characteristics) {
            // Check for Characteristic UUID 0xABF2 (Notification)
            if (characteristic.uuid
                .toString()
                .toUpperCase()
                .contains(targetCharUUID)) {
              await _subscribe(characteristic);
              return;
            }
          }
        }
      }
      statusNotifier.value = 'Error: Service not found on Band';
    } catch (e) {
      print('Discovery failed: $e');
    }
  }

  Future<void> _subscribe(BluetoothCharacteristic characteristic) async {
    try {
      notifyCharacteristic = characteristic;

      // Enable Notifications
      await characteristic.setNotifyValue(true);

      characteristicSubscription?.cancel();
      characteristicSubscription =
          characteristic.lastValueStream.listen((value) {
        // --- THIS IS WHERE THE ESP32 MESSAGE ARRIVES ---
        if (value.isNotEmpty) {
          String message = utf8.decode(value, allowMalformed: true);
          print("Received from Band: $message");

          // Update notification
          FlutterBackgroundService()
              .invoke("updateContent", {"message": "ALERT RECEIVED!"});

          // TRIGGER SOS
          SOSService().triggerSOS();
        }
      });

      statusNotifier.value = 'Band Ready & Listening';
    } catch (e) {
      print('Subscribe failed: $e');
    }
  }

  void _handleDisconnection() {
    isConnectedNotifier.value = false;
    statusNotifier.value = 'Band Disconnected';
    connectedDevice = null;
    notifyCharacteristic = null;

    // Retry connection
    if (_shouldAutoConnect) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_shouldAutoConnect && connectedDevice == null) {
        startAutoConnect();
      }
    });
  }
}
