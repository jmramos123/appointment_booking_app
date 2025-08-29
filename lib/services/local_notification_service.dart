import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  // Initialize local notifications
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize timezone
      tz.initializeTimeZones();
      
      // Android initialization
      const AndroidInitializationSettings androidInitSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization  
      const DarwinInitializationSettings iosInitSettings = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInitSettings,
        iOS: iosInitSettings,
      );
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Request permissions
      await _requestPermissions();
      
      _initialized = true;
      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Failed to initialize local notifications: $e');
    }
  }

  // Request notification permissions
  static Future<void> _requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
    
    // For iOS permissions, we'll use the general plugin
    // The iOS permissions are handled in the initialization settings
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notification tapped: ${response.payload}');
    // Add navigation logic here if needed
  }

  // Show immediate notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await initialize();
      
      const AndroidNotificationDetails androidDetails = 
          AndroidNotificationDetails(
        'appointment_channel',
        'Appointment Notifications',
        channelDescription: 'Notifications for appointment bookings',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Appointment',
        icon: '@mipmap/ic_launcher',
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      
      print('✅ Local notification shown: $title');
    } catch (e) {
      print('❌ Failed to show notification: $e');
    }
  }

  // Show test notification
  static Future<void> showTestNotification() async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🧪 FCM Test - Local Notification',
      body: 'This is a working local notification! 🎉',
      payload: 'test_notification',
    );
  }

  // Schedule notification for later
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await initialize();
      
      const AndroidNotificationDetails androidDetails = 
          AndroidNotificationDetails(
        'appointment_channel',
        'Appointment Notifications',
        channelDescription: 'Notifications for appointment bookings',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print('✅ Notification scheduled for: $scheduledDate');
    } catch (e) {
      print('❌ Failed to schedule notification: $e');
    }
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Show appointment reminder
  static Future<void> showAppointmentReminder({
    required String doctorName,
    required DateTime appointmentTime,
    required String location,
  }) async {
    final id = appointmentTime.millisecondsSinceEpoch ~/ 1000;
    
    await showNotification(
      id: id,
      title: '🏥 Appointment Reminder',
      body: 'You have an appointment with Dr. $doctorName in 15 minutes at $location',
      payload: 'appointment_reminder_$id',
    );
  }

  // Schedule appointment reminder (15 minutes before)
  static Future<void> scheduleAppointmentReminder({
    required String doctorName,
    required DateTime appointmentTime,
    required String location,
  }) async {
    final reminderTime = appointmentTime.subtract(const Duration(minutes: 15));
    final id = appointmentTime.millisecondsSinceEpoch ~/ 1000;
    
    // Don't schedule if reminder time is in the past
    if (reminderTime.isBefore(DateTime.now())) {
      print('⚠️ Reminder time is in the past, showing immediate notification');
      await showAppointmentReminder(
        doctorName: doctorName,
        appointmentTime: appointmentTime,
        location: location,
      );
      return;
    }
    
    await scheduleNotification(
      id: id,
      title: '🏥 Appointment Reminder',
      body: 'You have an appointment with Dr. $doctorName in 15 minutes at $location',
      scheduledDate: reminderTime,
      payload: 'appointment_reminder_$id',
    );
  }
}
