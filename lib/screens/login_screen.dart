import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/google_auth_service.dart';
import 'home_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatelessWidget {
  final GoogleAuthService authService = GoogleAuthService();

  Future<void> saveUserToDatabase(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('https://939b-106-0-37-94.ngrok-free.app/api/users'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(userData),
      );

      if (response.statusCode == 200) {
        print("✅ User saved successfully");
      } else {
        print("❌ Failed to save user: ${response.body}");
      }
    } catch (e) {
      print("🔥 Error saving user to database: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?q=80&w=1000&auto=format&fit=crop',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue using NoPhoneDrive',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: () async {
                  final user = await authService.signIn();
                  if (user != null) {
                    Map<String, dynamic> userData = {
                      "name": user.displayName,
                      "email": user.email,
                      "photoUrl": user.photoUrl,
                    };
                    print("🔐 Signed in as ${user.email}");
                    await saveUserToDatabase(userData);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                MainNavigationScreen(userEmail: user.email),
                      ),
                    );
                  } else {
                    print("⚠️ Google Sign-in failed or canceled.");
                  }
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Sign in with Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    "Sign Up",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF007AFF),
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
