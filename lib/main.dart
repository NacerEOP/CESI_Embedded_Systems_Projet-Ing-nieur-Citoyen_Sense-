import 'package:flutter/material.dart';
import 'notifications.dart';
import 'temperature.dart';
import 'warnings.dart';
import 'settings.dart';
import 'ble_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BleManager().start();
  runApp(SmartDetectorApp());
}

class SmartDetectorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sense+',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFF1E88E5),
        scaffoldBackgroundColor: Color(0xFFF2F4F8),
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
          secondary: Color(0xFF42A5F5),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: DetectorHomePage(),
    );
  }
}

class DetectorHomePage extends StatefulWidget {
  @override
  _DetectorHomePageState createState() => _DetectorHomePageState();
}

class _DetectorHomePageState extends State<DetectorHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    NotificationsScreen(),
    TemperatureScreen(),
    WarningsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield_moon_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Sense+',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 4,
        centerTitle: false,
      ),
      body: Container(
        padding: EdgeInsets.all(12),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _pages[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Notifications'),
            BottomNavigationBarItem(icon: Icon(Icons.thermostat), label: 'Température'),
            BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: 'Alertes'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Options'),
          ],
        ),
      ),
    );
  }
}
