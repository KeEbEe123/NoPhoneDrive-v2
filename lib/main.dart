import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';

const MethodChannel _channel = MethodChannel('com.example.npdf/missed_calls');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestCallPermissions(); // ✅ Request permissions at startup
  await Hive.initFlutter();
  await Hive.openBox('missedCalls');
  setupMissedCallChannel(); // ✅ Setup MethodChannel listener
  runApp(MyApp());
}

Future<void> requestCallPermissions() async {
  await [Permission.phone, Permission.sms].request();
}

/// ✅ Listen for missed call storage from Android service
void setupMissedCallChannel() {
  _channel.setMethodCallHandler((call) async {
    if (call.method == 'storeMissedCall') {
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        call.arguments,
      );
      final box = await Hive.openBox('missedCalls');
      final List list = box.get('data') ?? [];
      debugPrint("📦 Storing call: ${data.toString()}");
      list.add(data);
      await box.put('data', list);
      await box.put('lastSaved', DateTime.now().millisecondsSinceEpoch);
    }
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginScreen());
  }
}
