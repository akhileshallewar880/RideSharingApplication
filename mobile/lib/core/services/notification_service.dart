import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:allapalli_ride/core/network/dio_client.dart';

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Background message received: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
  // Save notification to database
  try {
    final notification = message.notification;
    if (notification != null) {
      // Convert data map to JSON string
      String? dataJson;
      if (message.data.isNotEmpty) {
        dataJson = message.data.entries
            .map((e) => '"${e.key}":"${e.value}"')
            .join(',');
        dataJson = '{$dataJson}';
      }

      final dio = DioClient.instance;
      await dio.post(
        '/notifications',
        data: {
          'type': message.data['type'] ?? 'general',
          'title': notification.title ?? '',
          'message': notification.body ?? '',
          'data': dataJson,
        },
      );
      print('✅ Background notification saved to database');
    }
  } catch (e) {
    print('⚠️ Failed to save background notification: $e');
  }
}

/// Service for handling Firebase Cloud Messaging notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'allapalli_ride_channel',
    'Ride Notifications',
    description: 'Notifications for ride updates, bookings, and alerts',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  final StreamController<RemoteMessage> _messageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    print('🔔 Initializing Notification Service...');
    
    // Check if Firebase is initialized
    try {
      Firebase.app();
    } catch (e) {
      print('⚠️ Firebase not initialized. Skipping FCM setup.');
      print('   To enable push notifications, add Firebase config files:');
      print('   - google-services.json (Android)');
      print('   - GoogleService-Info.plist (iOS)');
      return;
    }
    
    // Request permission
    final permissionGranted = await requestPermission();
    if (!permissionGranted) {
      print('❌ Notification permission denied');
      return;
    }

    // Initialize local notifications (this can work without FCM)
    try {
      await _initializeLocalNotifications();
      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Failed to initialize local notifications: $e');
    }
    
    // Initialize FCM (may fail if Google Play Services unavailable)
    try {
      await _initializeFCM();
      
      // Set up message handlers only if FCM initialized successfully
      _setupMessageHandlers();
      
      print('✅ FCM initialized and message handlers set up');
    } catch (e) {
      print('⚠️ FCM initialization failed: $e');
      print('   This is usually because:');
      print('   1. Device doesn\'t have Google Play Services');
      print('   2. No internet connection to Firebase');
      print('   3. Firebase project not configured correctly');
      print('   📱 App will continue to work, but push notifications will not be available.');
    }
    
    print('✅ Notification Service initialization complete');
  }

  /// Request notification permissions
  Future<bool> requestPermission() async {
    print('🔐 Requesting notification permission...');
    
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
      print(granted ? '✅ iOS notification permission granted' : '❌ iOS notification permission denied');
      return granted;
    } else {
      // Android 13+ requires explicit permission
      final status = await Permission.notification.request();
      print('Android notification permission status: ${status.toString()}');
      print(status.isGranted ? '✅ Android notification permission granted' : '❌ Android notification permission denied');
      return status.isGranted;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    print('📱 Initializing FCM...');
    
    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('📱 FCM Token: $_fcmToken');
    
    // Save token locally only during initialization
    // Backend sync will happen after user logs in via syncTokenWithBackend()
    if (_fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _fcmToken!);
      print('💾 FCM Token saved locally');
    } else {
      print('⚠️ WARNING: FCM token is NULL! Notifications will NOT work!');
      print('   This usually means:');
      print('   1. Google Services not configured properly');
      print('   2. Firebase not initialized correctly');
      print('   3. No internet connection');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed: $newToken');
      _fcmToken = newToken;
      _saveFCMToken(newToken);
    });

    // Set foreground notification presentation options for iOS
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('✅ FCM initialized successfully');
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    print('📡 Setting up FCM message handlers...');
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received: ${message.messageId}');
      print('   Notification: ${message.notification?.title}');
      print('   Data: ${message.data}');
      _handleForegroundMessage(message);
      _saveNotificationToDatabase(message);
      _messageStreamController.add(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped (background): ${message.messageId}');
      _handleNotificationTap(message);
      _saveNotificationToDatabase(message);
      _messageStreamController.add(message);
    });

    // Handle initial message if app was opened from terminated state
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🔔 Notification tapped (terminated): ${message.messageId}');
        _handleNotificationTap(message);
        _saveNotificationToDatabase(message);
      }
    });
    
    print('✅ FCM message handlers set up successfully');
  }

  /// Handle foreground messages by showing local notification
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔔 _handleForegroundMessage called');
    final notification = message.notification;

    print('📋 Notification data: title="${notification?.title}", body="${notification?.body}"');
    
    if (notification != null) {
      print('✅ Notification is not null, showing local notification...');
      try {
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@drawable/ic_stat_vanyatra',  // VanYatra Y icon
              largeIcon: const DrawableResourceAndroidBitmap('@drawable/notification_large_icon'),  // VanYatra logo
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              styleInformation: const BigTextStyleInformation(''),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: _encodePayload(message.data),
        );
        print('✅ Local notification shown successfully!');
      } catch (e) {
        print('❌ Error showing local notification: $e');
      }
    } else {
      print('⚠️ Notification is null - cannot show local notification');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] ?? '';

    print('🎯 Handling notification tap - Type: $type');
    print('   Data: $data');

    // Route user based on notification type
    switch (type) {
      case 'booking_confirmed':
        // Navigate to booking details
        _navigateToBookingDetails(data['bookingId']);
        break;
      case 'new_booking':
        // Navigate to driver's active rides / bookings list
        _navigateToDriverBookings();
        break;
      case 'ride_started':
        // Navigate to live tracking
        _navigateToLiveTracking(data['rideId'], data['bookingId']);
        break;
      case 'ride_completed':
        // Navigate to ride history / rating screen
        _navigateToRideHistory();
        break;
      case 'booking_cancelled':
        // Navigate to cancellation details
        _navigateToBookingDetails(data['bookingId']);
        break;
      case 'payment_due':
        // Navigate to payment screen
        _navigateToPayment(data['bookingId']);
        break;
      case 'promo_offer':
        // Navigate to offers/promo screen
        _navigateToOffers();
        break;
      default:
        print('⚠️ Unknown notification type: $type');
    }
  }

  /// Called when local notification is tapped
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      final message = RemoteMessage(data: data);
      _handleNotificationTap(message);
    }
  }

  /// Save FCM token to backend
  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      
      // Send token to backend API
      await _sendTokenToBackend(token);
      print('💾 FCM Token saved locally and sent to backend');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final dio = DioClient.instance;
      await dio.post(
        '/notifications/fcm-token',
        data: {'token': token},
      );
      print('✅ FCM Token sent to backend successfully');
    } catch (e) {
      print('⚠️ Failed to send FCM token to backend: $e');
      // Don't throw - allow the app to continue even if backend update fails
    }
  }

  /// Get saved FCM token
  Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  /// Test local notification (for debugging)
  Future<void> showTestNotification() async {
    print('🧪 Showing test notification...');
    try {
      await _localNotifications.show(
        999999,
        '🧪 Test Notification',
        'If you see this, local notifications are working!',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@drawable/ic_stat_vanyatra',  // VanYatra Y icon
            largeIcon: const DrawableResourceAndroidBitmap('@drawable/notification_large_icon'),  // VanYatra logo
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      print('✅ Test notification shown successfully');
    } catch (e) {
      print('❌ Error showing test notification: $e');
      rethrow;
    }
  }

  /// Save notification to database
  Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) {
        print('⚠️ No notification data to save');
        return;
      }

      // Convert data map to JSON string
      String? dataJson;
      if (message.data.isNotEmpty) {
        dataJson = message.data.entries
            .map((e) => '"${e.key}":"${e.value}"')
            .join(',');
        dataJson = '{$dataJson}';
      }

      final dio = DioClient.instance;
      await dio.post(
        '/notifications',
        data: {
          'type': message.data['type'] ?? 'general',
          'title': notification.title ?? '',
          'message': notification.body ?? '',
          'data': dataJson,
        },
      );
      print('✅ Notification saved to database');
    } catch (e) {
      print('⚠️ Failed to save notification to database: $e');
      // Don't throw - notifications should still display even if saving fails
    }
  }

  /// Sync FCM token with backend after user login
  /// Call this method after successful authentication
  Future<bool> syncTokenWithBackend() async {
    try {
      // Check if Firebase is initialized
      try {
        Firebase.app();
      } catch (e) {
        print('⚠️ Firebase not initialized. Cannot sync FCM token.');
        return false;
      }
      
      final token = _fcmToken ?? await getSavedToken();
      if (token == null || token.isEmpty) {
        print('⚠️ No FCM token available to sync');
        return false;
      }

      print('🔄 Syncing FCM token with backend...');
      await _sendTokenToBackend(token);
      return true;
    } catch (e) {
      print('❌ Error syncing FCM token: $e');
      return false;
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('📢 Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('🔇 Unsubscribed from topic: $topic');
  }

  /// Show custom local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@drawable/ic_stat_vanyatra',  // VanYatra Y icon
          largeIcon: const DrawableResourceAndroidBitmap('@drawable/notification_large_icon'),  // VanYatra logo
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: data != null ? _encodePayload(data) : null,
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Navigation helpers (implement with your navigation system)
  void _navigateToBookingDetails(String? bookingId) {
    // TODO: Implement navigation using GoRouter or Navigator
    print('🚀 Navigate to booking details: $bookingId');
  }

  void _navigateToDriverBookings() {
    // TODO: Implement navigation to driver's bookings/active rides screen
    print('🚀 Navigate to driver bookings');
  }

  void _navigateToLiveTracking(String? rideId, String? bookingId) {
    print('🚀 Navigate to live tracking: $rideId / $bookingId');
  }

  void _navigateToRideHistory() {
    print('🚀 Navigate to ride history');
  }

  void _navigateToPayment(String? bookingId) {
    print('🚀 Navigate to payment: $bookingId');
  }

  void _navigateToOffers() {
    print('🚀 Navigate to offers');
  }

  /// Encode payload to string
  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  /// Decode payload from string
  Map<String, dynamic> _decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        map[parts[0]] = parts[1];
      }
    }
    return map;
  }

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
  }
}

/// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// State notifier for notification permission status
class NotificationPermissionNotifier extends StateNotifier<bool> {
  NotificationPermissionNotifier() : super(false) {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (Platform.isIOS) {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      state = settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } else {
      final status = await Permission.notification.status;
      state = status.isGranted;
    }
  }

  Future<void> requestPermission() async {
    final service = NotificationService();
    final granted = await service.requestPermission();
    state = granted;
  }
}

/// Provider for notification permission status
final notificationPermissionProvider = StateNotifierProvider<NotificationPermissionNotifier, bool>((ref) {
  return NotificationPermissionNotifier();
});
