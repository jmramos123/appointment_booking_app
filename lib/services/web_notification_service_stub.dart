// Stub implementation for non-web platforms
class WebNotificationService {
  static Future<bool> showNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    bool requireInteraction = false,
  }) async {
    // Not supported on non-web platforms
    return false;
  }

  static Future<bool> showTestNotification() async {
    return false;
  }

  static String getPermissionStatus() {
    return 'not_web';
  }
}
