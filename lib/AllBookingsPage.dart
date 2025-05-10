import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AllBookingsPage extends StatelessWidget {
  const AllBookingsPage({super.key});

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "Unknown Date";
    DateTime? date = DateTime.tryParse(dateString);
    if (date == null) return "Unknown Date";
    return DateFormat('dd MMMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Bookings'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }
          final bookings = snapshot.data!.docs;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;
              final serviceName = booking['serviceName'] ?? 'Unknown Service';
              final customerId = booking['userId'] ?? '';
              final companyId = booking['companyId'] ?? '';
              final date =
                  booking['selectedDate'] ?? booking['selectedStartDate'];
              final status = booking['status'] ?? 'Pending';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(serviceName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(customerId)
                            .get(),
                        builder: (context, userSnap) {
                          if (userSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Customer: Loading...');
                          }
                          if (!userSnap.hasData || !userSnap.data!.exists) {
                            return const Text('Customer: Not found');
                          }
                          final user =
                              userSnap.data!.data() as Map<String, dynamic>;
                          return Text(
                              'Customer: ${user['fullName'] ?? 'Unknown'} (${user['email'] ?? ''})');
                        },
                      ),
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(companyId)
                            .get(),
                        builder: (context, companySnap) {
                          if (companySnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Company: Loading...');
                          }
                          if (!companySnap.hasData ||
                              !companySnap.data!.exists) {
                            return const Text('Company: Not found');
                          }
                          final company =
                              companySnap.data!.data() as Map<String, dynamic>;
                          return Text(
                              'Company: ${company['fullName'] ?? 'Unknown'} (${company['email'] ?? ''})');
                        },
                      ),
                      Text('Date: ${_formatDate(date)}'),
                      Text('Status: $status'),
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
