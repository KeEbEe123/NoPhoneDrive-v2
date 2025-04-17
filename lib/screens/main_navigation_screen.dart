import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home_screen.dart';
import 'missed_calls_screen.dart';
import 'settings_screen.dart';
import 'maps_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String userEmail;

  const MainNavigationScreen({super.key, required this.userEmail});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(email: widget.userEmail),
      MissedCallsScreen(),
      SettingsScreen(email: widget.userEmail),
      const MapsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        index: _page,
        height: 60,
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        color: Colors.white,
        buttonBackgroundColor: Colors.blueAccent,
        animationDuration: const Duration(milliseconds: 300),
        items: const <Widget>[
          Icon(Icons.speed, size: 30),
          Icon(Icons.call_missed, size: 30),
          Icon(Icons.settings, size: 30),
          Icon(Icons.map, size: 30),
        ],
        onTap: (index) {
          setState(() {
            _page = index;
          });
        },
      ),
      body: SafeArea(child: _screens[_page]),
    );
  }
}
