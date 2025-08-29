// Web-specific implementation
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class WebNotificationService {
  // DEAD SIMPLE web notification that ACTUALLY WORKS
  static Future<bool> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    bool requireInteraction = false,
  }) async {
    if (!kIsWeb) return false;

    try {
      // Check support
      if (!html.Notification.supported) {
        print('❌ Notifications not supported');
        return false;
      }

      // Get current permission
      print('🔔 Current permission: ${html.Notification.permission}');

      // Request permission if needed
      if (html.Notification.permission != 'granted') {
        print('🔔 Requesting permission...');
        final permission = await html.Notification.requestPermission();
        print('🔔 Permission result: $permission');
        
        if (permission != 'granted') {
          print('❌ Permission denied');
          return false;
        }
      }

      // Create notification - SIMPLE dart:html approach
      print('🔔 Creating notification with dart:html...');
      final notification = html.Notification(title);
      
      // Set body through DOM property (dart:html limitation workaround)
      (notification as dynamic).body = body;
      (notification as dynamic).icon = icon ?? '/icons/Icon-192.png';
      
      print('✅ Notification created and should be visible');
      
      // Auto close
      if (!requireInteraction) {
        Future.delayed(const Duration(seconds: 5), () {
          try {
            notification.close();
          } catch (e) {
            // Already closed
          }
        });
      }
      
      return true;

    } catch (e) {
      print('❌ Error: $e');
      return false;
    }
  }

  // Show test notification
  static Future<bool> showTestNotification() async {
    return await showNotification(
      title: '🧪 TEST NOTIFICATION',
      body: 'If you see this, notifications work!',
      requireInteraction: true,
    );
  }

  // Get permission status
  static String getPermissionStatus() {
    if (!kIsWeb) return 'not_web';
    if (!html.Notification.supported) return 'not_supported';
    return html.Notification.permission ?? 'unknown';
  }
}
