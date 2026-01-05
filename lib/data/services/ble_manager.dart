import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_setup/data/services/sos_service.dart';

class BLEManager {
  static final BLEManager _instance = BLEManager._internal();
  factory BLEManager() => _instance;
  BLEManager._internal();

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
    try {
      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
      }
      service.invoke('setAsForeground');
      service.invoke('updateContent', {"message": "BLE Service Ready - Monitoring for device"});
      print('Background service started with notification');
    } catch (e) {
      print('Error starting background service: $e');
    }
  }

  /////////BLE permissions
  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        await Permission.notification.request();
        final bluetoothScanStatus = await Permission.bluetoothScan.request();
        final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
        final locationStatus = await Permission.location.request();
        
        print('BLE Permissions Status:');
        print('  Notification: ${await Permission.notification.status}');
        print('  Bluetooth Scan: $bluetoothScanStatus');
        print('  Bluetooth Connect: $bluetoothConnectStatus');
        print('  Location: $locationStatus');
        
        return bluetoothScanStatus.isGranted &&
            bluetoothConnectStatus.isGranted &&
            locationStatus.isGranted;
      } else if (Platform.isIOS) {
        final bluetoothStatus = await Permission.bluetooth.request();
        return bluetoothStatus.isGranted;
      }
      return false;
    } catch (e) {
      print('Error requesting BLE permissions: $e');
      return false;
    }
  }

  /// Start auto-connecting to saved device or scan for device
  Future<void> startAutoConnect() async {
    if (_isAutoConnecting || !_shouldAutoConnect) return;
    
    _isAutoConnecting = true;
    statusNotifier.value = 'Starting auto-connect...';

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDeviceId = prefs.getString('ble_device_id');

      if (savedDeviceId != null && savedDeviceId.isNotEmpty) {
        statusNotifier.value = 'Connecting to saved device...';
        await _connectToDeviceById(savedDeviceId);
      } else {
        statusNotifier.value = 'Scanning for device...';
        await _scanAndConnect();
      }
    } catch (e) {
      print('Error in auto-connect: $e');
      statusNotifier.value = 'Auto-connect failed: $e';
      _scheduleReconnect();
    } finally {
      _isAutoConnecting = false;
    }
  }

  /// Connect to device by ID - SATOSHI use this for specific bluetooth device
  Future<void> _connectToDeviceById(String deviceId) async {
    try {
      final devices = await FlutterBluePlus.connectedDevices;
      for (var device in devices) {
        if (device.remoteId.toString() == deviceId) {
          await _connect(device);
          return;
        }
      }

      await _scanAndConnect();
    } catch (e) {
      print('Error connecting to device by ID: $e');
      await _scanAndConnect();
    }
  }

  Future<void> _scanAndConnect() async {
    try {
      _scanSubscription?.cancel();
      
      statusNotifier.value = 'Scanning for BLE device...';
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      final service = FlutterBackgroundService();
      if (await service.isRunning()) {
        service.invoke('updateContent', {"message": "Scanning for BLE device..."});
      }

      if (results.isNotEmpty && connectedDevice == null && _shouldAutoConnect) {
          //////Connect to first device found (you may want to filter by name/UUID)
          final device = results.first.device;
          await FlutterBluePlus.stopScan();
          await _connect(device);
          
          //////Save device ID for future connections
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ble_device_id', device.remoteId.toString());
        }
      });

      /////timeout
      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();

      if (connectedDevice == null) {
        statusNotifier.value = 'Device not found. Retrying...';
        final service = FlutterBackgroundService();
        if (await service.isRunning()) {
          service.invoke('updateContent', {"message": "BLE Service Ready - Monitoring for device"});
        }
        _scheduleReconnect();
      }
    } catch (e) {
      print('Error scanning: $e');
      statusNotifier.value = 'Scan failed: $e';
      _scheduleReconnect();
    }
  }

  //////Connect to a specific device
  Future<void> _connect(BluetoothDevice device) async {
    if (connectedDevice != null) return;

    try {
      statusNotifier.value = 'Connecting...';
      
      connectionStateSubscription?.cancel();
      connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        } else if (state == BluetoothConnectionState.connected) {
          isConnectedNotifier.value = true;
          statusNotifier.value = 'Connected';
        }
      });

      await device.connect(timeout: const Duration(seconds: 15));

      connectedDevice = device;
      isConnectedNotifier.value = true;
      statusNotifier.value = 'Connected';

      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
      }
      service.invoke('setAsForeground');
      service.invoke('updateContent', {"message": "BLE Device Connected - Monitoring"});

      await _discoverServices(device);
    } catch (e) {
      print('Connection error: $e');
      statusNotifier.value = 'Connection failed: $e';
      isConnectedNotifier.value = false;
      _scheduleReconnect();
    }
  }

  Future<void> _discoverServices(BluetoothDevice device) async {
    try {
      List<BluetoothService> services = await device.discoverServices();
      
      for (var service in services) {
        String serviceUuid = service.uuid.toString().toUpperCase();
        if (serviceUuid.contains('ABF0') || serviceUuid.contains('0000ABF0')) {
          for (var characteristic in service.characteristics) {
            String charUuid = characteristic.uuid.toString().toUpperCase();
            if (charUuid.contains('ABF2') || charUuid.contains('0000ABF2')) {
              await _subscribe(characteristic);
              return;
            }
          }
        }
      }

      /////Fallback
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify || characteristic.properties.indicate) {
            await _subscribe(characteristic);
            return;
          }
        }
      }

      statusNotifier.value = 'No data channel found';
    } catch (e) {
      print('Service discovery error: $e');
      statusNotifier.value = 'Service discovery failed: $e';
    }
  }

  ///bluetooth device messages recieve
  Future<void> _subscribe(BluetoothCharacteristic characteristic) async {
    try {
      notifyCharacteristic = characteristic;
      await characteristic.setNotifyValue(true);

      characteristicSubscription?.cancel();
      characteristicSubscription = characteristic.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            try {
              String message = utf8.decode(value, allowMalformed: true).trim();
              print('BLE Received: $message');

              FlutterBackgroundService().invoke(
                "updateContent",
                {"message": "Received: $message"},
              );

              ////Trigger SOS when message is received from BLE device
              // Satoshi, you can modify this to check for specific message content (e.g., "SOS", "EMERGENCY", etc.)
              print('Triggering SOS from BLE device');
              SOSService().triggerSOS();
            } catch (e) {
              print('Error decoding message: $e');
            }
          }
        },
        onError: (error) {
          print('Characteristic stream error: $error');
          statusNotifier.value = 'Data stream error';
        },
      );

      statusNotifier.value = 'Listening for SOS signals';
    } catch (e) {
      print('Subscribe error: $e');
      statusNotifier.value = 'Subscribe failed: $e';
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    isConnectedNotifier.value = false;
    statusNotifier.value = 'Device disconnected';

    characteristicSubscription?.cancel();
    connectionStateSubscription?.cancel();
    connectedDevice = null;
    notifyCharacteristic = null;

    final service = FlutterBackgroundService();
    service.invoke('updateContent', {"message": "BLE Service Ready - Monitoring for device"});

    if (_shouldAutoConnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_shouldAutoConnect && connectedDevice == null) {
        startAutoConnect();
      }
    });
  }

  Future<void> stop() async {
    _shouldAutoConnect = false;
    _reconnectTimer?.cancel();
    _scanSubscription?.cancel();
    
    if (connectedDevice != null) {
      await characteristicSubscription?.cancel();
      await connectionStateSubscription?.cancel();
      
      try {
        await connectedDevice!.disconnect();
      } catch (e) {
        print('Disconnect error: $e');
      }
      
      connectedDevice = null;
      notifyCharacteristic = null;
      isConnectedNotifier.value = false;
      
      final service = FlutterBackgroundService();
      service.invoke('updateContent', {"message": "BLE Service Ready - Monitoring for device"});
    }
  }
}

