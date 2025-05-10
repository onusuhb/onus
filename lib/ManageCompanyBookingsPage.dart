import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ManageCompanyBookingsPage extends StatefulWidget {
  const ManageCompanyBookingsPage({super.key});

  @override
  _ManageCompanyBookingsPageState createState() =>
      _ManageCompanyBookingsPageState();
}

class _ManageCompanyBookingsPageState extends State<ManageCompanyBookingsPage> {
  String _selectedFilter = "All";
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _updateExistingBookings();
  }

  Future<void> _updateExistingBookings() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final servicesSnapshot = await FirebaseFirestore.instance
          .collection('services')
          .where('userId', isEqualTo: user.uid)
          .get();

      final serviceIds = servicesSnapshot.docs.map((doc) => doc.id).toSet();
      print('Company service IDs: $serviceIds');

      final bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      for (var doc in bookingsSnapshot.docs) {
        final booking = doc.data();
        if (serviceIds.contains(booking['serviceId'])) {
          print('Updating booking ${doc.id} with companyId: ${user.uid}');
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(doc.id)
              .update({'companyId': user.uid});
        }
      }
    } catch (e) {
      print('Error updating bookings: $e');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Query<Map<String, dynamic>> _getFilteredQuery() {
    final user = FirebaseAuth.instance.currentUser;
    print('Current user ID: ${user?.uid}');  

    if (user == null) return FirebaseFirestore.instance.collection('bookings');

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('bookings')
        .where('companyId', isEqualTo: user.uid);

    print('Base query created with companyId: ${user.uid}');  

    switch (_selectedFilter) {
      case "Pending":
        query = query.where('status', isEqualTo: 'Pending');
        print('Filtered for Pending bookings'); 
        break;
      case "Completed":
        query = query.where('status', isEqualTo: 'Completed');
        print('Filtered for Completed bookings');  
        break;
      case "Today's Bookings":
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        query = query.where('selectedDate',
            isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
            isLessThan: endOfDay.toIso8601String());
        print(
            'Filtered for Today\'s bookings: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');  
        break;
    }

    return query.orderBy('selectedDate', descending: false);
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    print('Building page with user: ${currentUser?.uid}');  

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Bookings")),
        body: const Center(
            child: Text("Please log in to view customer bookings.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bookings"),
        backgroundColor: Colors.teal,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: _selectedFilter,
              underline: Container(), 
              icon: const Icon(Icons.filter_list, color: Colors.white),
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black),
              items: ["All", "Pending", "Completed", "Today's Bookings"]
                  .map((filter) => DropdownMenuItem(
                        value: filter,
                        child: Text(filter),
                      ))
                  .toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedFilter = newValue!;
                });
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getFilteredQuery().snapshots(),
        builder: (context, snapshot) {
          print(
              'StreamBuilder state: ${snapshot.connectionState}');  
          print('StreamBuilder has data: ${snapshot.hasData}');  
          print('StreamBuilder has error: ${snapshot.hasError}');  
          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}');  
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var bookings = snapshot.data!.docs;
          print('Number of bookings found: ${bookings.length}');  

          if (bookings.isEmpty) {
             FirebaseFirestore.instance
                .collection('bookings')
                .where('companyId', isEqualTo: currentUser.uid)
                .get()
                .then((snapshot) {
              print('Raw query results count: ${snapshot.docs.length}');
              if (snapshot.docs.isNotEmpty) {
                print('First booking data: ${snapshot.docs.first.data()}');
              }
               print('All bookings in the collection:');
              FirebaseFirestore.instance
                  .collection('bookings')
                  .get()
                  .then((allBookings) {
                for (var doc in allBookings.docs) {
                  print('Booking ID: ${doc.id}');
                  print('Booking data: ${doc.data()}');
                  print('---');
                }
              });
            });

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "No bookings found for $_selectedFilter",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var booking = bookings[index].data() as Map<String, dynamic>;
              print('Booking $index data: $booking');  
              String formattedDate = _formatDate(booking['selectedDate']);
              String selectedTime = booking['selectedTime'] ?? "Unknown Time";
              String status = booking['status'] ?? 'Pending';
              Color statusColor = _getStatusColor(status);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(booking['userId'])
                    .get(),
                builder: (context, userSnapshot) {
                  String customerName = "Loading...";
                  if (userSnapshot.connectionState == ConnectionState.done) {
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      customerName =
                          userSnapshot.data!['fullName'] ?? "Unknown Customer";
                    } else {
                      customerName = "Customer not found";
                    }
                  }

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: ListTile(
                      title: Text(booking['serviceName']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Customer: $customerName"),
                          if (booking['category'] == 'Equipment Rental')
                            Text("Rental Period: " +
                                (booking['selectedStartDate'] != null &&
                                        booking['selectedEndDate'] != null
                                    ? _formatDate(
                                            booking['selectedStartDate']) +
                                        " - " +
                                        _formatDate(booking['selectedEndDate'])
                                    : "N/A")),
                          if (booking['category'] != 'Equipment Rental')
                            Text("Date: $formattedDate - Time: $selectedTime"),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: statusColor),
                            ),
                          ),
                          if (booking['category'] == 'Equipment Rental')
                            Builder(builder: (context) {
                              if (booking['selectedStartDate'] != null &&
                                  booking['selectedEndDate'] != null) {
                                DateTime start = DateTime.parse(
                                    booking['selectedStartDate']);
                                DateTime end =
                                    DateTime.parse(booking['selectedEndDate']);
                                int days = end.difference(start).inDays + 1;
                                double price =
                                    (booking['price'] ?? 0).toDouble();
                                double total = price * days;
                                return Text(
                                    "Total: SAR ${total.toStringAsFixed(2)}");
                              } else {
                                return Text("Total: N/A");
                              }
                            }),
                          if (booking['category'] != 'Equipment Rental')
                            Text(
                                "Total: SAR ${booking['price']?.toStringAsFixed(2) ?? '0.00'}"),
                        ],
                      ),
                      trailing: status == 'Pending'
                          ? IconButton(
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.teal),
                              onPressed: () =>
                                  _markAsCompleted(bookings[index].id),
                            )
                          : const Icon(Icons.check_circle, color: Colors.green),
                      onTap: () => _showBookingDetails(
                          context, booking, bookings[index].id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
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
    if (dateString == null || dateString.isEmpty) return "Unknown Date";
    DateTime? date = DateTime.tryParse(dateString);
    if (date == null) return "Unknown Date";
    return DateFormat('dd MMMM yyyy').format(date);
  }

  void _markAsCompleted(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'Completed',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Booking marked as completed!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to update booking: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showBookingDetails(BuildContext context,
      Map<String, dynamic> booking, String bookingId) async {
    String userId = booking['userId'] ?? "";
    String userName = "Loading...";
    String userEmail = "Not available";
    String userPhone = "Not available";
    String userAddress = "Not available";

    if (userId.isNotEmpty) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          var userData = userDoc.data() as Map<String, dynamic>;
          userName = userData['fullName']?.toString() ?? "Unknown User";
          userEmail = userData['email']?.toString() ?? "Not available";
          userPhone = userData['phone']?.toString() ?? "Not available";
          userAddress = userData['address']?.toString() ?? "Not available";
        } else {
          userName = "User not found";
        }
      } catch (e) {
        userName = "Error fetching user";
      }
    }

    String formattedDate = _formatDate(booking['selectedDate']);
    String selectedTime = booking['selectedTime'] ?? "Unknown Time";
    String serviceName =
        booking['serviceName']?.toString() ?? "Unknown Service";
    String priceValue = booking['price']?.toString() ?? "0";
    String priceUnit = booking['priceUnit']?.toString() ?? "per service";
    String status = booking['status'] ?? "Pending";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Booking Details"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(Icons.person, "Customer:", userName),
                _detailRow(Icons.email, "Email:", userEmail),
                _detailRow(Icons.phone, "Phone:", userPhone),
                _detailRow(Icons.location_on, "Address:", userAddress),
                const Divider(),
                _detailRow(Icons.build, "Service:", serviceName),
                if (booking['category'] == 'Equipment Rental')
                  _detailRow(
                      Icons.calendar_today,
                      "Rental Period:",
                      (booking['selectedStartDate'] != null &&
                              booking['selectedEndDate'] != null)
                          ? _formatDate(booking['selectedStartDate']) +
                              " - " +
                              _formatDate(booking['selectedEndDate'])
                          : "N/A"),
                if (booking['category'] != 'Equipment Rental')
                  _detailRow(Icons.calendar_today, "Date:", formattedDate),
                if (booking['category'] != 'Equipment Rental')
                  _detailRow(Icons.access_time, "Time:", selectedTime),
                if (booking['category'] == 'Equipment Rental')
                  Builder(builder: (context) {
                    if (booking['selectedStartDate'] != null &&
                        booking['selectedEndDate'] != null) {
                      DateTime start =
                          DateTime.parse(booking['selectedStartDate']);
                      DateTime end = DateTime.parse(booking['selectedEndDate']);
                      int days = end.difference(start).inDays + 1;
                      double price = (booking['price'] ?? 0).toDouble();
                      double total = price * days;
                      return _detailRow(Icons.attach_money, "Total:",
                          "SAR ${total.toStringAsFixed(2)}");
                    } else {
                      return _detailRow(Icons.attach_money, "Total:", "N/A");
                    }
                  }),
                if (booking['category'] != 'Equipment Rental')
                  _detailRow(Icons.attach_money, "Total:",
                      "SAR ${double.tryParse(priceValue)?.toStringAsFixed(2) ?? '0.00'}"),
                _detailRow(Icons.info, "Status:", status),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              "$label $value",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
