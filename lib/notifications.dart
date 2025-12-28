import 'package:flutter/material.dart';
import 'dart:async';
import 'ble_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<String> notifications = [];
  DeviceConnectionState connectionState = DeviceConnectionState.disconnected;

  late final StreamSubscription<List<String>> _notifSubscription;
  late final StreamSubscription<DeviceConnectionState> _connectionSubscription;

  @override
  void initState() {
    super.initState();
    final bleManager = BleManager();

    notifications = List.from(bleManager.notifs);
    connectionState = bleManager.currentConnectionState;

    _notifSubscription = bleManager.alertsStream.listen((_) {
      setState(() {
        notifications = List.from(bleManager.notifs);
      });
    });

    _connectionSubscription = bleManager.connectionStateStream.listen((state) {
      setState(() {
        connectionState = state;
      });
    });
  }

  @override
  void dispose() {
    _notifSubscription.cancel();
    _connectionSubscription.cancel();
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
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            getConnectionText(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: connectionState == DeviceConnectionState.connected
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.notifications_active, color: Colors.blue),
                title: Text(notifications[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
