import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleManager {
  static final BleManager _instance = BleManager._internal();
  factory BleManager() => _instance;
  BleManager._internal();

  final FlutterReactiveBle flutterReactiveBle = FlutterReactiveBle();

  DiscoveredDevice? targetDevice;
  StreamSubscription<DiscoveredDevice>? scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? connection;
  QualifiedCharacteristic? notifyCharacteristic;

  final List<String> alerts = [];
  final List<String> notifs = [];
  String temp = "NO READING";
  QualifiedCharacteristic? writeCharacteristic;

  final StreamController<List<String>> _alertsStreamController = StreamController.broadcast();

  // New: StreamController for connection state updates
  final StreamController<DeviceConnectionState> _connectionStateController = StreamController.broadcast();

  Stream<List<String>> get alertsStream => _alertsStreamController.stream;
  Stream<DeviceConnectionState> get connectionStateStream => _connectionStateController.stream;

  DeviceConnectionState _currentConnectionState = DeviceConnectionState.disconnected;
  DeviceConnectionState get currentConnectionState => _currentConnectionState;

  bool _isConnecting = false;

  void start() {
    if (_isConnecting) return;
    _isConnecting = true;
    startScan();
  }

  void startScan() {
    scanSubscription = flutterReactiveBle
        .scanForDevices(withServices: [], scanMode: ScanMode.lowLatency)
        .listen((device) {
      if (device.name == 'ESP32-SMART') {
        targetDevice = device;
        scanSubscription?.cancel();
        connectToDevice(device);
      }
    }, onError: (error) {
      print('Scan error: $error');
    });
  }

  void connectToDevice(DiscoveredDevice device) {
    connection = flutterReactiveBle.connectToDevice(
      id: device.id,
      connectionTimeout: Duration(seconds: 10),
    ).listen((connectionState) {
      _currentConnectionState = connectionState.connectionState;
      _connectionStateController.add(_currentConnectionState);

      if (_currentConnectionState == DeviceConnectionState.connected) {
        print('Connected to ${device.name}');

        final serviceUuid = Uuid.parse('00001234-0000-1000-8000-00805f9b34fb');
        final characteristicUuid = Uuid.parse('00005678-0000-1000-8000-00805f9b34fb');

        notifyCharacteristic = QualifiedCharacteristic(
          characteristicId: characteristicUuid,
          serviceId: serviceUuid,
          deviceId: device.id,
        );
        final writeCharUuid = Uuid.parse('00007890-0000-1000-8000-00805f9b34fb');
        writeCharacteristic = QualifiedCharacteristic(
          characteristicId: writeCharUuid,
          serviceId: serviceUuid,
          deviceId: device.id,
        );

        flutterReactiveBle.subscribeToCharacteristic(notifyCharacteristic!).listen((data) {
          String Recieved = String.fromCharCodes(data);
          if (Recieved.contains('ALERT'))
          {
            alerts.add(Recieved);
          }else if(Recieved.contains('NOTIFY'))
          {
            notifs.add(Recieved);
          }else if(Recieved.contains('TEMP'))
          {
            temp = Recieved;
          }
          
          _alertsStreamController.add(alerts);
        }, onError: (error) {
          print('Notification error: $error');
        });
      } else if (_currentConnectionState == DeviceConnectionState.disconnected) {
        print('Disconnected from device');
        targetDevice = null;
        notifyCharacteristic = null;
        startScan(); // auto reconnect
      }
    }, onError: (error) {
      print('Connection error: $error');
    });
  }

  void dispose() {
    scanSubscription?.cancel();
    connection?.cancel();
    _alertsStreamController.close();
    _connectionStateController.close();
  }
}
