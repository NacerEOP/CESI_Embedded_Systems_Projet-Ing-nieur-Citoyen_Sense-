import 'package:flutter/material.dart';
import 'ble_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'dart:async';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;
  bool isMotionEnabled = true;
  DeviceConnectionState connectionState = DeviceConnectionState.disconnected;

  late final StreamSubscription<DeviceConnectionState> _connectionSubscription;

  @override
  void initState() {
    super.initState();
    final bleManager = BleManager();
    connectionState = bleManager.currentConnectionState;

    _connectionSubscription = bleManager.connectionStateStream.listen((state) {
      setState(() {
        connectionState = state;
      });
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  void _toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });

    // NOTE: Ce code ne change pas réellement le thème global.
    // Pour un vrai changement de thème, utilise Provider, Riverpod, etc.
  }

  void _toggleMotion(bool value) async {
    setState(() {
      isMotionEnabled = value;
    });

    final bleManager = BleManager();
    if (bleManager.currentConnectionState == DeviceConnectionState.connected) {
      final command = isMotionEnabled ? "MOTION_ON" : "MOTION_OFF";
      final characteristic = bleManager.writeCharacteristic;

      if (characteristic != null) {
        try {
          await bleManager.flutterReactiveBle.writeCharacteristicWithResponse(
            characteristic,
            value: command.codeUnits,
          );
          debugPrint("✅ Command sent: $command");
        } catch (e) {
          debugPrint("❌ Failed to write characteristic: $e");
        }
      } else {
        debugPrint("⚠️ Write characteristic is null");
      }
    } else {
      debugPrint("❌ Not connected to device");
    }
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
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            getConnectionText(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: connectionState == DeviceConnectionState.connected
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        ),
        SwitchListTile(
          title: const Text("Dark Mode"),
          value: isDarkMode,
          onChanged: _toggleTheme,
        ),
        SwitchListTile(
          title: const Text("Enable Motion Sensor"),
          value: isMotionEnabled,
          onChanged: _toggleMotion,
        ),
      ],
    );
  }
}
