import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Debug screen to test notifications
class NotificationDebugScreen extends ConsumerStatefulWidget {
  const NotificationDebugScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationDebugScreen> createState() => _NotificationDebugScreenState();
}

class _NotificationDebugScreenState extends ConsumerState<NotificationDebugScreen> {
  String? _fcmToken;
  String _status = 'Not tested';
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndToken();
  }

  Future<void> _checkPermissionAndToken() async {
    final notificationService = NotificationService();
    
    // Check permission
    final hasPermission = await notificationService.requestPermission();
    
    // Get token
    final token = notificationService.fcmToken;
    
    setState(() {
      _permissionGranted = hasPermission;
      _fcmToken = token;
    });
  }

  Future<void> _testLocalNotification() async {
    try {
      final notificationService = NotificationService();
      await notificationService.showTestNotification();
      setState(() {
        _status = '✅ Local notification sent';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    }
  }

  Future<void> _refreshToken() async {
    try {
      final newToken = await FirebaseMessaging.instance.getToken();
      setState(() {
        _fcmToken = newToken;
        _status = '✅ Token refreshed';
      });
      
      // Send to backend
      final notificationService = NotificationService();
      await notificationService.syncTokenWithBackend();
      
      setState(() {
        _status = '✅ Token refreshed and synced with backend';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error refreshing token: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Debug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Permission Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _permissionGranted ? Icons.check_circle : Icons.cancel,
                          color: _permissionGranted ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(_permissionGranted ? 'Granted' : 'Denied'),
                      ],
                    ),
                    if (!_permissionGranted) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _checkPermissionAndToken,
                        child: const Text('Request Permission'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // FCM Token
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FCM Token',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_fcmToken != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _fcmToken!,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _refreshToken,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh & Sync'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              // Copy to clipboard
                              // You can add clipboard package here
                            },
                            icon: const Icon(Icons.copy),
                            tooltip: 'Copy Token',
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text('No token available'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _checkPermissionAndToken,
                        child: const Text('Get Token'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Test Notifications',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _testLocalNotification,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Send Test Local Notification'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: $_status',
                      style: TextStyle(
                        color: _status.contains('✅') ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Testing Instructions',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Ensure notification permission is granted'),
                    const SizedBox(height: 4),
                    const Text('2. Test local notification first'),
                    const SizedBox(height: 4),
                    const Text('3. If local works, the app can show notifications'),
                    const SizedBox(height: 4),
                    const Text('4. Copy FCM token and test with backend'),
                    const SizedBox(height: 4),
                    const Text('5. Check device: Settings → Apps → VanYatra → Notifications'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
