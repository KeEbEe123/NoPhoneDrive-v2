import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

TextEditingController _controller = TextEditingController();
String _replyMessage =
    "I'm currently driving. For emergencies, reply with any number.";

class SettingsScreen extends StatefulWidget {
  final String email;

  const SettingsScreen({super.key, required this.email});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? name;
  String? photoUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    _loadCustomReply();
  }

  void _showMessageEditDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    _controller.text = _replyMessage;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Auto-Reply'),
            content: TextField(controller: _controller),
            actions: [
              TextButton(
                onPressed: () async {
                  await prefs.setString('customReply', _controller.text);
                  setState(() => _replyMessage = _controller.text);
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }

  Future<void> _loadCustomReply() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _replyMessage = prefs.getString('customReply') ?? _replyMessage;
    });
  }

  Future<void> fetchUserDetails() async {
    final String backendUrl =
        'https://939b-106-0-37-94.ngrok-free.app/api/users/email/${widget.email}';

    try {
      final response = await http.get(Uri.parse(backendUrl));
      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        setState(() {
          name = user['name'];
          photoUrl = user['photoUrl'];
          isLoading = false;
        });
      } else {
        debugPrint('❌ Failed to load user data: ${response.body}');
      }
    } catch (e) {
      debugPrint('🔥 Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildUserProfileHeader(name ?? '', photoUrl ?? ''),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Message Settings'),
                  GestureDetector(
                    onTap: () => _showMessageEditDialog(context),
                    child: _buildSettingCard(
                      icon: Icons.message,
                      title: 'Auto-Reply Message',
                      value: _replyMessage,
                      isValueLink: true,
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Notifications'),
                  _buildSwitchCard(
                    icon: Icons.notifications_active,
                    title: 'Emergency Notifications',
                    description: 'Allow emergency calls to come through',
                    value: true,
                    onChanged: (val) {},
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Drive Mode'),
                  _buildSwitchCard(
                    icon: Icons.access_time,
                    title: 'Auto-Enable',
                    description:
                        'Automatically enable drive mode when motion is detected',
                    value: false,
                    onChanged: (val) {},
                  ),
                  const SizedBox(height: 16),
                  _buildSwitchCard(
                    icon: Icons.shield,
                    title: 'Strict Mode',
                    description:
                        'Prevent drive mode from being disabled while in motion',
                    value: true,
                    onChanged: (val) {},
                  ),
                ],
              ),
    );
  }

  Widget _buildUserProfileHeader(String name, String photoUrl) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(photoUrl)),
          const SizedBox(width: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String value,
    bool isValueLink = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF007AFF)),
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
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        isValueLink
                            ? const Color(0xFF007AFF)
                            : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF007AFF)),
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
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF34C759),
            inactiveTrackColor: const Color(0xFFE5E5EA),
          ),
        ],
      ),
    );
  }
}
