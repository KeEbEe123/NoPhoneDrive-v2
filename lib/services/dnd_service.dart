import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:flutter/material.dart';

class DndService {
  final _dndPlugin = DoNotDisturbPlugin();

  /// Checks if DND permission is granted
  Future<bool> hasDndPermission() async {
    try {
      return await _dndPlugin.isNotificationPolicyAccessGranted();
    } catch (e) {
      print('Error checking DND permission: $e');
      return false;
    }
  }

  /// Check if DND mode is active
  Future<bool> isDndActive() async {
    try {
      return await _dndPlugin.isDndEnabled();
    } catch (e) {
      print('Error checking DND status: $e');
      return false;
    }
  }

  /// Request DND permission with a dialog
  Future<void> requestPermissions(BuildContext context) async {
    bool hasAccess = await hasDndPermission();
    if (!hasAccess) {
      _showPermissionDialog(context);
    }
  }

  /// Show an explanation popup before opening settings
  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Grant DND Permission"),
          content: const Text(
            "This app needs Do Not Disturb access to block notifications while driving. Please enable it in the next screen.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _dndPlugin
                    .openNotificationPolicyAccessSettings(); // Open settings
              },
              child: const Text("Allow"),
            ),
          ],
        );
      },
    );
  }

  /// Enable DND Mode
  Future<void> enableDND() async {
    bool hasAccess = await hasDndPermission();
    if (hasAccess) {
      await _dndPlugin.setInterruptionFilter(InterruptionFilter.none);
    }
  }

  /// Disable DND Mode
  Future<void> disableDND() async {
    bool hasAccess = await hasDndPermission();
    if (hasAccess) {
      await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
    }
  }
}
