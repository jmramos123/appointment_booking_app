// Platform-aware notification service using conditional exports
export 'web_notification_service_stub.dart'
    if (dart.library.html) 'web_notification_service_web.dart';
