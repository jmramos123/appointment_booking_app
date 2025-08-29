# appointment_booking_app

A new Flutter project.

# Appointment Booking App

A Flutter application for booking and managing medical appointments with real-time notifications.

## Features

✅ **User Authentication** - Firebase Auth with email/password  
✅ **Appointment Booking** - Schedule appointments with doctors  
✅ **Appointment History** - View past and upcoming appointments  
✅ **Real-time Notifications** - FCM push notifications + local notifications  
✅ **Responsive UI** - Works on mobile, web, and desktop  

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore, Cloud Messaging)
- **Notifications**: Firebase Cloud Messaging + Flutter Local Notifications
- **Database**: Cloud Firestore with real-time sync

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── screens/
│   ├── auth_wrapper.dart       # Authentication state management
│   ├── login_screen.dart       # User login
│   ├── register_screen.dart    # User registration
│   ├── home_screen.dart        # Main dashboard
│   ├── booking_screen.dart     # Appointment booking
│   └── history_screen.dart     # Appointment history
└── services/
    ├── fcm_service.dart        # Firebase Cloud Messaging setup
    ├── fcm_api_service.dart    # FCM notification sending
    └── local_notification_service.dart # Local notifications
```

## Firebase Configuration

### Firestore Collections
- `users/{userId}` - User profiles
- `users/{userId}/appointments/{appointmentId}` - User appointments
- `notifications/{notificationId}` - Notification logs
- `fcm_tokens_ready/{tokenId}` - FCM tokens for production

### Security Rules
Configured for user-specific data access with authentication required.

## FCM Integration

### Real Push Notifications
The app includes a Node.js script for sending real FCM notifications:

```bash
# Test FCM with a specific token
node fcm_sender.js test <fcm_token>

# Send notification to a user
node fcm_sender.js send <userId> "Title" "Body" [type]
```

### Local Notifications
Immediate local notifications work on all platforms as fallback.

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Firebase CLI
- Node.js (for FCM script)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repo-url>
   cd appointment_booking_app
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Install Node.js dependencies**
   ```bash
   npm install
   ```

4. **Configure Firebase**
   - Place your `firebase_options.dart` in `lib/`
   - Place your service account JSON in root directory
   - Deploy Firestore rules: `firebase deploy --only firestore:rules`

5. **Run the app**
   ```bash
   # Web
   flutter run -d edge
   
   # Android
   flutter run -d <device_id>
   
   # All platforms
   flutter run
   ```
   ![Untitled design](https://github.com/user-attachments/assets/a27f3060-59db-4877-87f6-702d1f1f6d5f)


## Testing Notifications

### Local Notifications
Tap the "Test FCM" button in the app - works immediately.

### Real FCM Notifications
1. Run the app and get the FCM token from logs
2. Use the Node.js script:
   ```bash
   node fcm_sender.js test <your_fcm_token>
   ```

## Production Deployment

For production, deploy the `fcm_sender.js` script to a cloud server and make HTTP requests from the Flutter app to send real push notifications.

## Available Scripts

- `npm run migrate` - Run Firestore data migration
- `flutter run` - Run the Flutter app
- `firebase deploy --only firestore:rules` - Deploy Firestore rules

## Firebase Project
- **Project ID**: appointment-booking-57015
- **Authentication**: Email/Password enabled
- **Firestore**: Native mode with security rules
- **FCM**: Configured for all platforms

---

**Status**: ✅ Production Ready  
**Last Updated**: August 29, 2025
