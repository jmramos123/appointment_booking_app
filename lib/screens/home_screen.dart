import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'book_appointment_screen.dart';
import 'appointment_history_screen.dart';
import '../services/fcm_api_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Booking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test REAL FCM Notification',
            onPressed: () async {
              // Test the REAL FCM API implementation
              print('🧪 Testing REAL FCM API...');
              final success = await FCMApiService.sendTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success 
                        ? '🎉 REAL FCM notification sent successfully!'
                        : '⚠️ Script returned error, but notification may have been sent. Check your device!'
                    ),
                    backgroundColor: success ? Colors.green : Colors.orange,
                  ),
                );
              }
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Logout'),
                onTap: () {
                  FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Reduced from 16.0
                child: Column(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 36, // Reduced from 48
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 6), // Reduced from 8
                    Text(
                      'Welcome back!',
                      style: Theme.of(context).textTheme.titleLarge, // Changed from headlineSmall
                    ),
                    const SizedBox(height: 2), // Reduced from 4
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Reduced from 24
            
            // Upcoming Appointments Section
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action Buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _ActionCard(
                    icon: Icons.add_circle,
                    title: 'Book New\nAppointment',
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookAppointmentScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.history,
                    title: 'Appointment\nHistory',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppointmentHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.upcoming,
                    title: 'Upcoming\nAppointments',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppointmentHistoryScreen(
                            showOnlyUpcoming: true,
                          ),
                        ),
                      );
                    },
                  ),
                  _ActionCard(
                    icon: Icons.notifications,
                    title: 'Notification\nSettings',
                    color: Colors.purple,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifications are enabled by default'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Next Appointment Preview
            const SizedBox(height: 16),
            Text(
              'Next Appointment',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _NextAppointmentCard(),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Please log in to see appointments'),
        ),
      );
    }

    // Debug: First check what appointments exist
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .get(),
      builder: (context, allSnapshot) {
        if (allSnapshot.hasData) {
          print('=== DEBUG: All appointments in database ===');
          print('Total appointments: ${allSnapshot.data!.docs.length}');
          final now = DateTime.now();
          print('Current time: $now');
          
          for (var doc in allSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final appointmentDate = (data['dateTime'] as Timestamp).toDate();
            final status = data['status'];
            final reason = data['reason'];
            final isFuture = appointmentDate.isAfter(now);
            final isUpcoming = status == 'upcoming';
            
            print('Appointment: $reason');
            print('  Date: $appointmentDate');
            print('  Status: $status');
            print('  Is future: $isFuture');
            print('  Is upcoming status: $isUpcoming');
            print('  Days from now: ${appointmentDate.difference(now).inDays}');
            print('---');
          }
        }

        // Now do the actual filtered query - simplified to avoid index issues
        return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .orderBy('dateTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // Debug logging
        print('Next appointment query - Connection state: ${snapshot.connectionState}');
        print('Next appointment query - Has data: ${snapshot.hasData}');
        print('Next appointment query - Document count: ${snapshot.data?.docs.length ?? 0}');
        print('Next appointment query - Current time: ${DateTime.now()}');
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text('No appointments found'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookAppointmentScreen(),
                        ),
                      );
                    },
                    child: const Text('Book Your First Appointment'),
                  ),
                ],
              ),
            ),
          );
        }

        // Filter appointments in Dart to avoid Firestore index issues
        final now = DateTime.now();
        final upcomingAppointments = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String;
          final appointmentDate = (data['dateTime'] as Timestamp).toDate();
          return status == 'upcoming' && appointmentDate.isAfter(now);
        }).toList();

        // Sort by date (since we can't rely on Firestore orderBy with the filter)
        upcomingAppointments.sort((a, b) {
          final aDate = ((a.data() as Map<String, dynamic>)['dateTime'] as Timestamp).toDate();
          final bDate = ((b.data() as Map<String, dynamic>)['dateTime'] as Timestamp).toDate();
          return aDate.compareTo(bDate);
        });

        print('Filtered upcoming appointments: ${upcomingAppointments.length}');
        for (var doc in upcomingAppointments) {
          final data = doc.data() as Map<String, dynamic>;
          final appointmentDate = (data['dateTime'] as Timestamp).toDate();
          print('Upcoming: ${data['reason']} - $appointmentDate');
        }

        if (upcomingAppointments.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.event_available,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text('No upcoming appointments'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookAppointmentScreen(),
                        ),
                      );
                    },
                    child: const Text('Book Your First Appointment'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show just the next appointment
        final nextAppointment = upcomingAppointments.first;
        final data = nextAppointment.data() as Map<String, dynamic>;
        final dateTime = (data['dateTime'] as Timestamp).toDate();
        final reason = data['reason'] as String;

        return Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 40,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
      },
    );
  }
}
