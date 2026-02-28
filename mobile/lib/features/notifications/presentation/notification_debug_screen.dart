import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:allapalli_ride/core/services/notification_service.dart';
import 'package:allapalli_ride/core/network/dio_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Debug screen to test notifications end-to-end
class NotificationDebugScreen extends ConsumerStatefulWidget {
  const NotificationDebugScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState
    extends ConsumerState<NotificationDebugScreen> {
  String? _fcmToken;
  String _status = 'Not tested';
  bool _permissionGranted = false;
  bool _isTesting = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndToken();
  }

  Future<void> _checkPermissionAndToken() async {
    final notificationService = NotificationService();
    final hasPermission = await notificationService.requestPermission();
    // Try in-memory token first, then fall back to saved token
    var token = notificationService.fcmToken;
    token ??= await notificationService.getSavedToken();
    // If still null, request fresh from Firebase
    token ??= await FirebaseMessaging.instance.getToken();

    if (mounted) {
      setState(() {
        _permissionGranted = hasPermission;
        _fcmToken = token;
      });
    }
  }

  Future<void> _testLocalNotification() async {
    try {
      final notificationService = NotificationService();
      await notificationService.showTestNotification();
      if (mounted) {
        setState(() {
          _status = '✅ Local notification sent — check if you saw it';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ Local notification error: $e';
        });
      }
    }
  }

  Future<void> _forceSyncToken() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
      _status = '⏳ Syncing token with backend...';
    });

    try {
      // Get a fresh FCM token
      final newToken = await FirebaseMessaging.instance.getToken();
      if (newToken == null) {
        setState(() {
          _status =
              '❌ Could not get FCM token. Check Firebase/Google Play Services.';
          _isSyncing = false;
        });
        return;
      }

      setState(() => _fcmToken = newToken);

      // Send to backend
      final notificationService = NotificationService();
      final success = await notificationService.syncTokenWithBackend();

      if (mounted) {
        setState(() {
          _status = success
              ? '✅ Token synced with backend successfully!'
              : '❌ Token sync failed. Check server logs.';
          _isSyncing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ Error syncing token: $e';
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _testServerPush() async {
    if (_isTesting) return;
    setState(() {
      _isTesting = true;
      _status = '⏳ Asking server to send a push...';
    });

    try {
      final dio = DioClient.instance;
      final response = await dio.post('/notifications/test-push');
      final data = response.data as Map<String, dynamic>?;
      final success = data?['success'] == true;
      final message = data?['message'] ?? data?['error']?['message'] ?? 'Unknown response';

      if (mounted) {
        setState(() {
          _status = success
              ? '✅ Server sent push! $message\n\nIf no notification appeared, check:\n• Notification permission granted\n• App is not killed (use background/foreground)\n• Firebase credential on server is correct'
              : '❌ Server error: $message';
          _isTesting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = '❌ API call failed: $e\n\nIs the server running?';
          _isTesting = false;
        });
      }
    }
  }

  void _copyToken() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ FCM token copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
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
            _buildCard(
              title: 'Permission Status',
              child: Row(
                children: [
                  Icon(
                    _permissionGranted ? Icons.check_circle : Icons.cancel,
                    color: _permissionGranted ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(_permissionGranted ? 'Granted ✅' : 'Denied ❌'),
                  const Spacer(),
                  if (!_permissionGranted)
                    TextButton(
                      onPressed: _checkPermissionAndToken,
                      child: const Text('Request'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // FCM Token
            _buildCard(
              title: 'FCM Token (on this device)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_fcmToken != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _fcmToken!,
                        style: const TextStyle(
                            fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSyncing ? null : _forceSyncToken,
                            icon: _isSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.sync),
                            label: Text(
                                _isSyncing ? 'Syncing...' : 'Force Sync to Server'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _copyToken,
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy Token',
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text('⚠️ No token available — tap Refresh below'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _checkPermissionAndToken,
                      child: const Text('Refresh Token'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Test Buttons
            _buildCard(
              title: 'Test Notifications',
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _testLocalNotification,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Send Local Test Notification'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testServerPush,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cloud_upload),
                    label: Text(
                        _isTesting ? 'Sending...' : 'Test Push from Server'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _status,
                      style: TextStyle(
                        color: _status.startsWith('✅')
                            ? Colors.green[700]
                            : _status.startsWith('❌')
                                ? Colors.red[700]
                                : Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Checklist
            _buildCard(
              color: Colors.blue[50],
              title: '🔍 Troubleshooting Checklist',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _checklistItem('Permission Status above shows ✅ Granted'),
                  _checklistItem('FCM Token shown above (not empty)'),
                  _checklistItem(
                      '"Force Sync to Server" shows ✅ (token is in DB)'),
                  _checklistItem('"Test Push from Server" shows ✅ and you receive the notification'),
                  _checklistItem(
                      'Device: Settings → Apps → VanYatra → Notifications → All enabled'),
                  _checklistItem(
                      'Server: Check logs for "Firebase Admin SDK initialized successfully"'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
      {required String title,
      required Widget child,
      Color? color}) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _checklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 13)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
