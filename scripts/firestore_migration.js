// firestore_migration.js
// Run this script after setting FIREBASE_TOKEN environment variable
// Uses Firebase CLI authentication via environment

const admin = require('firebase-admin');

// Initialize without explicit credentials - relies on environment
try {
  admin.initializeApp({
    projectId: 'appointment-booking-57015'
  });
} catch (error) {
  // App may already be initialized
  console.log('Firebase Admin already initialized or initializing...');
}

const db = admin.firestore();

async function migrate() {
  console.log('🚀 Starting Firestore migration...');
  
  try {
    // Example user
    const userId = 'user_001';
    console.log(`📝 Creating user: ${userId}`);
    const userRef = db.collection('users').doc(userId);
    await userRef.set({
      name: 'John Doe',
      email: 'johndoe@example.com',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      fcmToken: 'fcm_abc123',
      timezone: 'America/La_Paz',
      photoURL: '',
      phoneNumber: ''
    });

    // Example appointment
    const appointmentId = 'appt_001';
    console.log(`📅 Creating appointment: ${appointmentId}`);
    const appointmentRef = userRef.collection('appointments').doc(appointmentId);
    await appointmentRef.set({
      dateTime: new Date('2025-09-01T14:30:00Z'),
      reason: 'Dental Checkup',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'upcoming',
      notifyAt: new Date('2025-09-01T14:15:00Z'),
      notificationScheduled: true,
      notificationId: 'job_xyz'
    });

    // Example notification
    const notificationId = 'notif_001';
    console.log(`🔔 Creating notification: ${notificationId}`);
    const notificationRef = userRef.collection('notifications').doc(notificationId);
    await notificationRef.set({
      appointmentId: appointmentId,
      message: 'Your appointment is in 15 minutes',
      sentAt: new Date('2025-09-01T14:15:00Z'),
      status: 'sent',
      apptDateTime: new Date('2025-09-01T14:30:00Z')
    });

    console.log('✅ Migration completed successfully!');
    console.log('\n📊 Created:');
    console.log(`   - User: users/${userId}`);
    console.log(`   - Appointment: users/${userId}/appointments/${appointmentId}`);
    console.log(`   - Notification: users/${userId}/notifications/${notificationId}`);
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
  }
}

migrate().then(() => process.exit(0)).catch(console.error);
