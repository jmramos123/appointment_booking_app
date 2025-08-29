import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/fcm_api_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 0),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (!_formKey.currentState!.validate() || _selectedDateTime == null) {
      if (_selectedDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date and time'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Create appointment document
      final appointmentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('appointments')
          .doc();

      final appointmentData = {
        'dateTime': Timestamp.fromDate(_selectedDateTime!),
        'reason': _reasonController.text.trim(),
        'doctorName': 'Smith', // Default doctor for demo
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'confirmed',
      };

      await appointmentRef.set(appointmentData);

      // Send REAL FCM confirmation notification
      await FCMApiService.sendNotificationToUser(
        userId: user.uid,
        title: '✅ Appointment Confirmed',
        body: 'Your appointment with Dr. Smith has been confirmed!',
        data: {
          'type': 'appointment_confirmed',
          'appointmentId': appointmentRef.id,
          'doctorName': 'Dr. Smith',
          'appointmentDateTime': _selectedDateTime!.toIso8601String(),
        },
      );

      // Send REAL FCM reminder notification  
      await FCMApiService.scheduleAppointmentReminder(
        appointmentId: appointmentRef.id,
        userId: user.uid,
        appointmentDateTime: _selectedDateTime!,
        doctorName: 'Dr. Smith',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Appointment booked! REAL FCM notifications sent via Firebase API.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error booking appointment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appointment Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Date and Time Selection
                      InkWell(
                        onTap: _selectDateTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDateTime == null
                                      ? 'Select Date & Time'
                                      : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} at ${_selectedDateTime!.hour.toString().padLeft(2, '0')}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDateTime == null 
                                        ? Colors.grey[600] 
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Reason Input
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Appointment',
                          hintText: 'Enter the purpose of your appointment...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a reason for the appointment';
                          }
                          if (value.trim().length < 5) {
                            return 'Please provide more details (at least 5 characters)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Notification Info Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notifications,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notification Reminder',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'You\'ll receive a notification 15 minutes before your appointment.',
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Book Button
              ElevatedButton(
                onPressed: _isLoading ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
