const admin = require('firebase-admin');
const serviceAccount = require('./appointment-booking-57015-firebase-adminsdk-fbsvc-aa19cf9a03.json');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'appointment-booking-57015'
  });
}

async function sendTestNotification(fcmToken) {
  try {
    const message = {
      notification: {
        title: '🧪 Real FCM Test from Node.js',
        body: 'This is a real push notification sent via Firebase Admin SDK! 🎉'
      },
      data: {
        type: 'test',
        timestamp: new Date().toISOString(),
        source: 'nodejs_admin_sdk'
      },
      token: fcmToken
    };

    const response = await admin.messaging().send(message);
    console.log('✅ FCM notification sent successfully:', response);
    return { success: true, response };
  } catch (error) {
    console.error('❌ Error sending FCM notification:', error);
    return { success: false, error: error.message };
  }
}

async function sendNotificationToUser(userId, title, body, data = {}) {
  try {
    // Get FCM token from Firestore
    const tokenDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .collection('fcm_tokens')
      .doc('current_token')
      .get();

    if (!tokenDoc.exists) {
      throw new Error('No FCM token found for user');
    }

    const fcmToken = tokenDoc.data().token;
    
    const message = {
      notification: {
        title,
        body
      },
      data: {
        ...data,
        timestamp: new Date().toISOString(),
        source: 'nodejs_admin_sdk'
      },
      token: fcmToken
    };

    const response = await admin.messaging().send(message);
    
    // Log to Firestore
    await admin.firestore().collection('notifications').add({
      userId,
      title,
      body,
      type: data.type || 'general',
      method: 'firebase_admin_sdk',
      status: 'sent',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      fcmResponse: response
    });

    console.log('✅ Notification sent and logged:', response);
    return { success: true, response };
  } catch (error) {
    console.error('❌ Error sending notification:', error);
    return { success: false, error: error.message };
  }
}

// CLI interface
if (require.main === module) {
  const args = process.argv.slice(2);
  
  async function handleCLI() {
    try {
      if (args[0] === 'test' && args[1]) {
        // Usage: node fcm_sender.js test <fcm_token>
        console.log('🧪 Sending test FCM notification...');
        const result = await sendTestNotification(args[1]);
        console.log('📄 Final result:', JSON.stringify(result, null, 2));
        process.exit(result.success ? 0 : 1);
      } else if (args[0] === 'send' && args[1] && args[2] && args[3]) {
        // Usage: node fcm_sender.js send <userId> <title> <body> [type]
        console.log('📤 Sending FCM notification to user...');
        const data = args[4] ? { type: args[4] } : {};
        const result = await sendNotificationToUser(args[1], args[2], args[3], data);
        console.log('📄 Final result:', JSON.stringify(result, null, 2));
        process.exit(result.success ? 0 : 1);
      } else {
        console.log('Usage:');
        console.log('  node fcm_sender.js test <fcm_token>');
        console.log('  node fcm_sender.js send <userId> <title> <body> [type]');
        process.exit(1);
      }
    } catch (error) {
      console.error('💥 CLI Error:', error);
      process.exit(1);
    }
  }
  
  handleCLI();
}

module.exports = { sendTestNotification, sendNotificationToUser };
