import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:allapalli_ride/core/services/notification_service.dart';

/// Utility to request all required permissions (location + notification)
/// after the user first lands on the home screen.
///
/// Call [requestAllPermissions] once in [initState] of the home screen.
class PermissionManager {
  /// Request location and notification permissions.
  ///
  /// Shows a friendly dialog first, then triggers the OS prompts.
  /// Returns true if both permissions were granted.
  static Future<bool> requestAllPermissions(BuildContext context) async {
    // Slight delay so the home screen is fully rendered first
    await Future.delayed(const Duration(milliseconds: 800));

    if (!context.mounted) return false;

    // 1. Location permission
    final locationGranted = await _requestLocationPermission(context);

    // 2. Notification permission (Android 13+ only)
    if (!context.mounted) return locationGranted;
    final notificationGranted = await _requestNotificationPermission(context);

    return locationGranted && notificationGranted;
  }

  // ---------------------------------------------------------------------------
  // Location
  // ---------------------------------------------------------------------------
  static Future<bool> _requestLocationPermission(BuildContext context) async {
    // Check if service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        await _showPermissionDialog(
          context,
          icon: Icons.location_off_rounded,
          title: 'Location Services Required',
          message:
              'VanYatra needs your location to find rides near you, show your pickup point, and enable live tracking.',
          buttonLabel: 'Enable Location',
          onPressed: () async {
            Navigator.pop(context);
            await Geolocator.openLocationSettings();
          },
        );
      }
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Ask via the system dialog
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever && context.mounted) {
      await _showPermissionDialog(
        context,
        icon: Icons.location_disabled_rounded,
        title: 'Location Permission Needed',
        message:
            'Location permission was denied permanently. Please enable it in app settings to use ride features.',
        buttonLabel: 'Open Settings',
        onPressed: () async {
          Navigator.pop(context);
          await openAppSettings();
        },
      );
      return false;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------
  static Future<bool> _requestNotificationPermission(
      BuildContext context) async {
    // Only Android 13+ needs explicit notification permission
    if (!Platform.isAndroid) {
      // On iOS, the NotificationService.requestPermission handles it
      final service = NotificationService();
      return await service.requestPermission();
    }

    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      // Show the system permission dialog
      final result = await Permission.notification.request();
      if (result.isGranted) return true;
    }

    if (status.isPermanentlyDenied && context.mounted) {
      await _showPermissionDialog(
        context,
        icon: Icons.notifications_off_rounded,
        title: 'Notification Permission Needed',
        message:
            'VanYatra needs notification permission to alert you about ride updates, booking confirmations, and driver arrivals.',
        buttonLabel: 'Open Settings',
        onPressed: () async {
          Navigator.pop(context);
          await openAppSettings();
        },
      );
      return false;
    }

    return false;
  }

  // ---------------------------------------------------------------------------
  // UI Helper
  // ---------------------------------------------------------------------------
  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.amber[700], size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later',
                style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
