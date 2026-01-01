import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

///Message data model for BLE messages - subject to change(satoshi)
class BLEMessage {
  final String message;
  final DateTime timestamp;
  BLEMessage({required this.message, required this.timestamp});
}

enum BLEConnectionStatus {
  disconnected,
  connecting,
  connected,
}

class BLEService {
  static final BLEService _instance = BLEService._internal();
  factory BLEService() => _instance;
  BLEService._internal();

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? notifyCharacteristic;
  StreamSubscription<List<int>>? characteristicSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionStateSubscription;

  final ValueNotifier<List<BLEMessage>> messagesNotifier = ValueNotifier([]);
  final ValueNotifier<String> statusNotifier = ValueNotifier('Ready to scan');
  final ValueNotifier<BLEConnectionStatus> connectionStatusNotifier =
      ValueNotifier(BLEConnectionStatus.disconnected);

  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        await Permission.notification.request();
        final bluetoothScanStatus = await Permission.bluetoothScan.request();
        final bluetoothConnectStatus = await Permission.bluetoothConnect.request();
        final locationStatus = await Permission.location.request();
        
        print('BLE Permissions Status:');
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

  /////cnnect to a BLE device
  Future<void> connect(BluetoothDevice device) async {
    final hasPermissions = await _requestPermissions();
    if (!hasPermissions) {
      statusNotifier.value = 'Permissions not granted';
      return;
    }

    statusNotifier.value = 'Connecting...';
    connectionStatusNotifier.value = BLEConnectionStatus.connecting;

    try {
      connectionStateSubscription?.cancel();
      connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      await device.connect(
        timeout: const Duration(seconds: 15),
      );

      connectedDevice = device;
      connectionStatusNotifier.value = BLEConnectionStatus.connected;
      statusNotifier.value = 'Connected';

      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
      }
      service.invoke('setAsForeground');
      service.invoke('updateContent', {"message": "Connected to device"});
      await _discoverServices(device);
    } catch (e) {
      statusNotifier.value = 'Connection failed: ${e.toString()}';
      connectionStatusNotifier.value = BLEConnectionStatus.disconnected;
      connectedDevice = null;
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

      ////Fallback
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.notify ||
              characteristic.properties.indicate) {
            await _subscribe(characteristic);
            return;
          }
        }
      }

      statusNotifier.value = 'No data channel found';
    } catch (e) {
      statusNotifier.value = 'Service discovery failed: ${e.toString()}';
    }
  }

  
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

              final currentMsgs = List<BLEMessage>.from(messagesNotifier.value);
              currentMsgs.insert(
                0,
                BLEMessage(message: message, timestamp: DateTime.now()),
              );

              if (currentMsgs.length > 100) {
                currentMsgs.removeRange(100, currentMsgs.length);
              }

              messagesNotifier.value = currentMsgs;
              FlutterBackgroundService().invoke(
                "updateContent",
                {"message": message},
              );
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

      statusNotifier.value = 'Listening for data';
    } catch (e) {
      statusNotifier.value = 'Subscribe failed: ${e.toString()}';
    }
  }

  void _handleDisconnection() {
    connectionStatusNotifier.value = BLEConnectionStatus.disconnected;
    statusNotifier.value = 'Device disconnected';

    characteristicSubscription?.cancel();
    connectionStateSubscription?.cancel();

    connectedDevice = null;
    notifyCharacteristic = null;

    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }

  Future<void> disconnect() async {
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
      connectionStatusNotifier.value = BLEConnectionStatus.disconnected;
      statusNotifier.value = 'Disconnected';

      final service = FlutterBackgroundService();
      service.invoke("stopService");
    }
  }

  //////Clear messages
  void clearMessages() {
    messagesNotifier.value = [];
  }
}

