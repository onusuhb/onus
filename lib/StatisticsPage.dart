import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  Future<int> _getTotalBookings() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('bookings').get();
    return snapshot.docs.length;
  }

  Future<int> _getBookingsThisMonth() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getBookingsToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    return snapshot.docs.length;
  }

  Future<List<Map<String, dynamic>>> _getTopServices() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('bookings').get();
    final Map<String, int> serviceCounts = {};
    final Map<String, String> serviceNames = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final serviceId = data['serviceId'] ?? '';
      final serviceName = data['serviceName'] ?? 'Unknown';
      if (serviceId.isNotEmpty) {
        serviceCounts[serviceId] = (serviceCounts[serviceId] ?? 0) + 1;
        serviceNames[serviceId] = serviceName;
      }
    }
    final sorted = serviceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(5)
        .map((e) => {
              'serviceId': e.key,
              'serviceName': serviceNames[e.key] ?? 'Unknown',
              'count': e.value,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Booking Statistics',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FutureBuilder<int>(
              future: _getTotalBookings(),
              builder: (context, snapshot) {
                return ListTile(
                  leading: const Icon(Icons.book_online, color: Colors.teal),
                  title: const Text('Total Bookings'),
                  trailing:
                      Text(snapshot.hasData ? snapshot.data.toString() : '...'),
                );
              },
            ),
            FutureBuilder<int>(
              future: _getBookingsThisMonth(),
              builder: (context, snapshot) {
                return ListTile(
                  leading: const Icon(Icons.calendar_month, color: Colors.teal),
                  title: const Text('Bookings This Month'),
                  trailing:
                      Text(snapshot.hasData ? snapshot.data.toString() : '...'),
                );
              },
            ),
            FutureBuilder<int>(
              future: _getBookingsToday(),
              builder: (context, snapshot) {
                return ListTile(
                  leading: const Icon(Icons.today, color: Colors.teal),
                  title: const Text('Bookings Today'),
                  trailing:
                      Text(snapshot.hasData ? snapshot.data.toString() : '...'),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Top 5 Most Booked Services',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _getTopServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final topServices = snapshot.data!;
                if (topServices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No bookings yet.'),
                  );
                }
                return Column(
                  children: topServices
                      .map((service) => ListTile(
                            leading:
                                const Icon(Icons.star, color: Colors.orange),
                            title: Text(service['serviceName']),
                            trailing: Text('${service['count']} bookings'),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
