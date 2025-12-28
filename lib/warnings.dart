import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_manager.dart';

class WarningsScreen extends StatefulWidget {
  const WarningsScreen({Key? key}) : super(key: key);

  @override
  _WarningsScreenState createState() => _WarningsScreenState();
}

class _WarningsScreenState extends State<WarningsScreen> {
  List<String> alerts = [];
  DeviceConnectionState connectionState = DeviceConnectionState.disconnected;

  late final StreamSubscription<List<String>> _alertsSubscription;
  late final StreamSubscription<DeviceConnectionState> _connectionSubscription;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _setup(); // kick off async setup
  }

  Future<void> _setup() async {
    await _initializeNotifications();
    await _requestNotificationPermission();

    final bleManager = BleManager();
    alerts = List.from(bleManager.alerts);
    connectionState = bleManager.currentConnectionState;

    _alertsSubscription = bleManager.alertsStream.listen((alertsList) {
      if (alertsList.length > alerts.length) {
        final newAlert = alertsList.last;
        _showNotification(newAlert);
      }

      setState(() {
        alerts = alertsList;
      });
    });

    _connectionSubscription = bleManager.connectionStateStream.listen((state) {
      setState(() {
        connectionState = state;
      });
    });
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    const androidChannel = AndroidNotificationChannel(
      'alert_channel',
      'Alerts',
      description: 'Channel for critical alerts',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alert_channel',
      'Alerts',
      channelDescription: 'Channel for critical alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      '⚠️ New Alert',
      message,
      platformDetails,
    );
  }

  @override
  void dispose() {
    _alertsSubscription.cancel();
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
          padding: const EdgeInsets.all(16),
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
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(alerts[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
