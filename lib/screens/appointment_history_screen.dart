import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  final bool showOnlyUpcoming;
  
  const AppointmentHistoryScreen({
    super.key,
    this.showOnlyUpcoming = false,
  });

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    if (widget.showOnlyUpcoming) {
      _selectedFilter = 'upcoming';
    }
  }

  Query<Map<String, dynamic>> _getQuery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    var query = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('appointments')
        .orderBy('dateTime', descending: true);

    switch (_selectedFilter) {
      case 'upcoming':
        query = query.where('dateTime', isGreaterThan: DateTime.now());
        break;
      case 'past':
        query = query.where('dateTime', isLessThan: DateTime.now());
        break;
      case 'cancelled':
        query = query.where('status', isEqualTo: 'cancelled');
        break;
      default:
        // Show all
        break;
    }

    return query;
  }

  Future<void> _cancelAppointment(String appointmentId, Map<String, dynamic> appointmentData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('appointments')
            .doc(appointmentId)
            .update({
          'status': 'cancelled',
          'cancelReason': 'Cancelled by user',
          'cancelledAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled successfully'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling appointment: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showOnlyUpcoming ? 'Upcoming Appointments' : 'Appointment History'),
        actions: [
          if (!widget.showOnlyUpcoming)
            PopupMenuButton<String>(
              onSelected: (value) {
                setState(() {
                  _selectedFilter = value;
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'all',
                  child: Text('All Appointments'),
                ),
                const PopupMenuItem(
                  value: 'upcoming',
                  child: Text('Upcoming'),
                ),
                const PopupMenuItem(
                  value: 'past',
                  child: Text('Past'),
                ),
                const PopupMenuItem(
                  value: 'cancelled',
                  child: Text('Cancelled'),
                ),
              ],
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getQuery().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.showOnlyUpcoming 
                        ? 'No upcoming appointments'
                        : 'No appointments found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Book your first appointment to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final appointmentId = doc.id;
              
              final dateTime = (data['dateTime'] as Timestamp).toDate();
              final reason = data['reason'] as String;
              final status = data['status'] as String;
              final isUpcoming = dateTime.isAfter(DateTime.now()) && status != 'cancelled';
              final isCancelled = status == 'cancelled';

              Color statusColor;
              IconData statusIcon;
              String statusText;

              if (isCancelled) {
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                statusText = 'Cancelled';
              } else if (isUpcoming) {
                statusColor = Colors.green;
                statusIcon = Icons.schedule;
                statusText = 'Upcoming';
              } else {
                statusColor = Colors.grey;
                statusIcon = Icons.check_circle;
                statusText = 'Completed';
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            statusIcon,
                            color: statusColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          if (isUpcoming && !isCancelled)
                            TextButton(
                              onPressed: () => _cancelAppointment(appointmentId, data),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: const Text('Cancel'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (isUpcoming && !isCancelled) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications,
                                size: 14,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Notification 15 min before',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
