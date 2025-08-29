import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background FCM message: ${message.notification?.title}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize FCM service
  Future<void> initialize() async {
    print('🚀 Initializing FCM Service...');

    // On web, skip automatic permission request to avoid browser violations
    if (kIsWeb) {
      print('🌐 Web platform detected - FCM ready for user-initiated requests');
      print('✅ FCM Service initialized successfully!');
      return;
    }

    // Request permission for notifications (mobile only)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 FCM Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get and store FCM token
      await _storeFCMToken();
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_storeFCMToken);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      print('✅ FCM Service initialized successfully!');
    } else {
      print('❌ FCM Permission denied');
    }
  }

  // Store FCM token in Firestore
  Future<void> _storeFCMToken([String? token]) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get current token if not provided
      token ??= await _firebaseMessaging.getToken();
      if (token == null) return;

      print('🔑 FCM Token: ${token.substring(0, 20)}...');

      // Store token in user's FCM tokens collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fcm_tokens')
          .doc('current_token')
          .set({
        'token': token,
        'platform': 'web', // or detect platform
        'createdAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
      });

      print('✅ FCM token stored successfully');
    } catch (e) {
      print('❌ Error storing FCM token: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📱 Foreground FCM message: ${message.notification?.title}');
    
    // Show in-app notification or handle as needed
    if (message.notification != null) {
      _showInAppNotification(message.notification!);
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped: ${message.data}');
    
    // Navigate to specific screen based on notification data
    if (message.data['type'] == 'appointment_reminder') {
      // Navigate to appointment details
      print('📅 Opening appointment: ${message.data['appointmentId']}');
    }
  }

  // Show in-app notification
  void _showInAppNotification(RemoteNotification notification) {
    // This would typically show a toast or dialog
    print('📲 In-app notification: ${notification.title} - ${notification.body}');
  }

  // Send test notification (for testing purposes)
  Future<void> sendTestNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create a test notification in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc('test_${DateTime.now().millisecondsSinceEpoch}')
          .set({
        'message': 'FCM Test: Your notification system is working!',
        'status': 'scheduled',
        'scheduledFor': Timestamp.now(),
        'type': 'test',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Test notification scheduled in Firestore');
      print('💡 FCM server will pick this up and send the push notification');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  // Get current FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
