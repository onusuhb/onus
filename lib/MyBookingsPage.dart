import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: Text('Please log in to view your bookings.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final bookings = snapshot.data?.docs ?? [];

          if (bookings.isEmpty) {
            return const Center(
              child: Text('No bookings found.'),
            );
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              final bookingId = bookings[index].id;
              final isEquipmentRental =
                  booking['category'] == 'Equipment Rental';
              final status = booking['status'] ?? 'Pending';
              final statusColor = _getStatusColor(status);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: _getCategoryIcon(booking['category']),
                  title: Text(
                    booking['serviceName'] ?? 'Unknown Service',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    isEquipmentRental
                        ? 'Rental Period: ${_formatDate(booking['selectedStartDate'])} - ${_formatDate(booking['selectedEndDate'])}'
                        : 'Date: ${_formatDate(booking['selectedDate'])} at ${booking['selectedTime']}',
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Category:', booking['category']),
                          _buildDetailRow('Price:',
                              'SAR ${booking['price']} ${booking['priceUnit']}'),
                          _buildDetailRow('Status:', status),
                          const SizedBox(height: 16),
                          if (status == 'Pending')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _cancelBooking(context, bookingId),
                                  icon: const Icon(Icons.cancel),
                                  label: const Text('Cancel Booking'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }

  Icon _getCategoryIcon(String? category) {
    switch (category) {
      case 'Equipment Rental':
        return const Icon(Icons.build, color: Colors.teal);
      case 'Construction':
        return const Icon(Icons.construction, color: Colors.orange);
      case 'Renovation':
        return const Icon(Icons.home_repair_service, color: Colors.blue);
      default:
        return const Icon(Icons.category, color: Colors.grey);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not specified';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  Future<void> _cancelBooking(BuildContext context, String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
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

    if (confirmed == true) {
      try {
        final bookingDoc = await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .get();

        if (bookingDoc.exists) {
          final booking = bookingDoc.data() as Map<String, dynamic>;
          final isEquipmentRental = booking['category'] == 'Equipment Rental';
          final serviceId = booking['serviceId'];

          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .update({'status': 'Cancelled'});

          if (isEquipmentRental && serviceId != null) {
            await FirebaseFirestore.instance
                .collection('services')
                .doc(serviceId)
                .update({
              'stockQuantity': FieldValue.increment(1),
            });
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking cancelled successfully'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rescheduleBooking(
      BuildContext context, Map<String, dynamic> booking) async {
    final isEquipmentRental = booking['category'] == 'Equipment Rental';
    DateTime? newDate;
    TimeOfDay? newTime;
    DateTime? newStartDate;
    DateTime? newEndDate;

    if (isEquipmentRental) {
      newStartDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 5)),
      );

      if (newStartDate != null) {
        newEndDate = await showDatePicker(
          context: context,
          initialDate: newStartDate,
          firstDate: newStartDate,
          lastDate: newStartDate.add(const Duration(days: 5)),
        );
      }
    } else {
      newDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 5)),
      );

      if (newDate != null) {
        newTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
      }
    }

    if ((isEquipmentRental && newStartDate != null && newEndDate != null) ||
        (!isEquipmentRental && newDate != null && newTime != null)) {
      try {
        final Map<String, dynamic> updateData = {
          'status': 'Pending',
        };

        if (isEquipmentRental) {
          updateData['selectedStartDate'] = newStartDate!.toIso8601String();
          updateData['selectedEndDate'] = newEndDate!.toIso8601String();
        } else {
          updateData['selectedDate'] = newDate!.toIso8601String();
          updateData['selectedTime'] = newTime!.format(context);
        }

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking['id'])
            .update(updateData);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking rescheduled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rescheduling booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
