import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_manager.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({Key? key}) : super(key: key);

  @override
  _TemperatureScreenState createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  String temperature = "NO READING";
  DeviceConnectionState connectionState = DeviceConnectionState.disconnected;

  late final StreamSubscription<List<String>> _alertSub;
  late final StreamSubscription<DeviceConnectionState> _connSub;

  @override
  void initState() {
    super.initState();

    final bleManager = BleManager();
    temperature = bleManager.temp;
    connectionState = bleManager.currentConnectionState;

    _alertSub = bleManager.alertsStream.listen((_) {
      setState(() {
        temperature = bleManager.temp;
      });
    });

    _connSub = bleManager.connectionStateStream.listen((state) {
      setState(() {
        connectionState = state;
      });
    });
  }

  @override
  void dispose() {
    _alertSub.cancel();
    _connSub.cancel();
    super.dispose();
  }

  String getConnectionText() {
    switch (connectionState) {
      case DeviceConnectionState.connecting:
        return '🔄 Connecting...';
      case DeviceConnectionState.connected:
        return '✅ Connected';
      case DeviceConnectionState.disconnected:
        return '❌ Disconnected';
      case DeviceConnectionState.disconnecting:
        return 'Disconnecting...';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            getConnectionText(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: connectionState == DeviceConnectionState.connected
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
            temperature,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.blueAccent,
            ),
          ),
          ),
          
        ),
      ],
    );
  }
}
