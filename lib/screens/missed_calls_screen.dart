import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

class MissedCallsScreen extends StatefulWidget {
  const MissedCallsScreen({super.key});

  @override
  State<MissedCallsScreen> createState() => _MissedCallsScreenState();
}

class _MissedCallsScreenState extends State<MissedCallsScreen> {
  final List<Map<String, dynamic>> missedCalls = [];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
    final box = await Hive.openBox('missedCalls');

    final lastSaved = box.get('lastSaved') ?? 0;
    if (DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(lastSaved))
            .inDays >=
        1) {
      await box.clear();
    }

    final calls = box.get('data');
    print('Missed call data from Hive: $calls');
    setState(() {
      missedCalls.clear();
      if (calls != null) {
        missedCalls.addAll(
          (calls as List).map<Map<String, dynamic>>(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
      }
    });
  }

  Future<void> storeMissedCall(Map<String, dynamic> callData) async {
    final box = await Hive.openBox('missedCalls');
    final List data = box.get('data') ?? [];
    data.add(callData);
    await box.put('data', data);
    await box.put('lastSaved', DateTime.now().millisecondsSinceEpoch);
  }

  String formatTimeAgo(int timestamp) {
    final now = DateTime.now();
    final callTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = now.difference(callTime);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: missedCalls.length,
        itemBuilder: (context, index) {
          final item = missedCalls[index];
          return _buildNotificationCard(item);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    final name = (item['name'] ?? item['number'] ?? 'Unknown').toString();
    final number = (item['number'] ?? 'Unknown').toString();
    final isEmergency = item['isEmergency'] == true;
    final rawTimestamp = item['timestamp'];
    final time = rawTimestamp is int ? formatTimeAgo(rawTimestamp) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  isEmergency
                      ? const Color(0xFFFF3B30)
                      : const Color(0xFF007AFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['type'] == 'call' ? Icons.call : Icons.message,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF666666),
                  ),
                ),
                if (isEmergency) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Emergency Contact Attempt',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
