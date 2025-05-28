import 'package:flutter/material.dart';
import '../services/dnd_service.dart';
import '../services/location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  const HomeScreen({super.key, required this.email});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DndService _dndService = DndService();
  final LocationService _locationService = LocationService();

  bool _hasDndPermission = false;
  bool _userDriveMode = false;
  bool _dndActive = false;
  double _currentSpeed = 0.0;
  final double speedThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    _checkDndPermission();
    _updateSpeed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncUiWithDndState(); // sync UI state when returning to this screen
  }

  Future<void> _syncUiWithDndState() async {
    bool isDndActuallyOn = await _dndService.isDndActive();
    final prefs = await SharedPreferences.getInstance();
    bool toggleState = prefs.getBool('driveMode') ?? false;

    setState(() {
      _dndActive = isDndActuallyOn;
      _userDriveMode = toggleState;
    });
  }

  Future<void> _checkDndPermission({bool showDialog = false}) async {
    bool permission = await _dndService.hasDndPermission();
    setState(() {
      _hasDndPermission = permission;
    });

    if (!permission && showDialog) {
      await _dndService.requestPermissions(context);
      _checkDndPermission();
    }
  }

  Future<void> _updateSpeed() async {
    while (mounted) {
      double? speed = await _locationService.getCurrentSpeed();
      if (speed != null) {
        setState(() {
          _currentSpeed = speed;
        });

        _updateDndStatus(speed);
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _updateDndStatus(double speed) async {
    bool shouldEnableDnd = _userDriveMode || speed > speedThreshold;

    if (shouldEnableDnd && !_dndActive) {
      await _dndService.enableDND();
      _logDndEvent("on");
      setState(() {
        _dndActive = true;
      });
    } else if (!shouldEnableDnd && _dndActive) {
      await _dndService.disableDND();
      _logDndEvent("off");
      setState(() {
        _dndActive = false;
      });
    }
  }

  Future<void> _logDndEvent(String action) async {
    final location = await _locationService.getCurrentLocation();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final body = {
      "email": widget.email,
      "action": action,
      "timestamp": timestamp,
      "location": location,
    };

    await http.post(
      Uri.parse("https://msme.mlritcie.in/api/log-dnd"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
  }

  void _toggleDriveMode(bool value) async {
    setState(() {
      _userDriveMode = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('driveMode', value);
    _updateDndStatus(_currentSpeed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('Drive Mode'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _dndActive ? const Color(0xFF007AFF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 48,
                    color: _dndActive ? Colors.white : const Color(0xFF007AFF),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Drive Mode is ${_dndActive ? 'Active' : 'Inactive'}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _dndActive ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Speed: ${_currentSpeed.toStringAsFixed(1)} km/h',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _dndActive ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Switch(
                    value: _userDriveMode,
                    onChanged: _toggleDriveMode,
                    trackColor: MaterialStateProperty.resolveWith(
                      (states) =>
                          _userDriveMode
                              ? const Color(0xFF34C759)
                              : const Color(0xFFE5E5EA),
                    ),
                    activeTrackColor: const Color(0xFF34C759),
                    inactiveTrackColor: const Color(0xFFE5E5EA),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Active Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _buildFeatureCard(
              icon: Icons.call,
              title: 'Call Blocking',
              description: 'Automatically blocks incoming calls while driving',
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              icon: Icons.message,
              title: 'Auto-Reply Messages',
              description: 'Sends automatic replies to incoming messages',
            ),
            if (!_hasDndPermission) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _checkDndPermission(showDialog: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Grant DND Permission",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF007AFF), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
