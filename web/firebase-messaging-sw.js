// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here. Other Firebase libraries
// are not available in the service worker.
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker by passing in
// your app's Firebase config object.
firebase.initializeApp({
  apiKey: "AIzaSyC5HfBj9d9LXl7L8v_R0RJ_4X3Q5ZbW3qI",
  authDomain: "appointment-booking-57015.firebaseapp.com",
  projectId: "appointment-booking-57015",
  storageBucket: "appointment-booking-57015.appspot.com",
  messagingSenderId: "1084157892375",
  appId: "1:1084157892375:web:a8d0c7e9f6b4c5d2e3f4g5"
});

// Retrieve an instance of Firebase Messaging so that it can handle background
// messages.
const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification?.title || 'Appointment Booking';
  const notificationOptions = {
    body: payload.notification?.body || 'You have a new notification',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-72.png',
    tag: 'appointment-notification',
    requireInteraction: true,
    data: payload.data || {}
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

// Handle notification click
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] Notification click received.');

  event.notification.close();

  // Open the app
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // If app is already open, focus it
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          return client.focus();
        }
      }
      // If app is not open, open it
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
