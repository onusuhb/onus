import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ManageCustomerBookingsPage extends StatelessWidget {
  const ManageCustomerBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("My Bookings")),
        body: Center(child: Text("Please log in to view your bookings.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("My Bookings"), backgroundColor: Colors.teal),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('selectedDate', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var bookings = snapshot.data!.docs;
          if (bookings.isEmpty) {
            return Center(child: Text("No bookings found."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var booking = bookings[index].data() as Map<String, dynamic>;

              String formattedDate = _formatDate(booking['selectedDate']);
              String formattedTime = booking['selectedTime'];

              return ListTile(
                title: Text(booking['serviceName']),
                subtitle: Text("Date: $formattedDate - Time: $formattedTime"),
                trailing: Icon(Icons.arrow_forward, color: Colors.teal),
                onTap: () async {
                  await _showBookingDetails(
                      context, booking, bookings[index].id);
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "Unknown Date";
    DateTime? date = DateTime.tryParse(dateString);
    if (date == null) return "Unknown Date";
    return DateFormat('dd MMMM yyyy').format(date);
  }

  String _formatTime(BuildContext context, String? timeString) {
    if (timeString == null || timeString.isEmpty) return "Unknown Time";

    try {
      if (timeString.contains(":")) {
        List<String> parts = timeString.split(":");
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);

        TimeOfDay time = TimeOfDay(hour: hour, minute: minute);
        return time.format(context);
      }

      DateTime dateTime = DateTime.tryParse(timeString) ?? DateTime.now();
      return DateFormat.jm().format(dateTime);
    } catch (e) {
      return "Unknown Time";
    }
  }

  Future<void> _showBookingDetails(BuildContext context,
      Map<String, dynamic> booking, String bookingId) async {
    String companyId = booking['companyId'] ?? "";
    String companyName = "Loading...";
    String companyEmail = "Not available";
    String companyPhone = "Not available";
    String serviceId = booking['serviceId'] ?? "";
    String serviceDescription = "Fetching description...";

    if (companyId.isNotEmpty) {
      try {
        DocumentSnapshot companyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(companyId)
            .get();
        if (companyDoc.exists && companyDoc.data() != null) {
          var companyData = companyDoc.data() as Map<String, dynamic>;
          companyName =
              companyData['fullName']?.toString() ?? "Unknown Company";
          companyEmail = companyData['email']?.toString() ?? "Not available";
          companyPhone = companyData['phone']?.toString() ?? "Not available";
        } else {
          companyName = "Company not found";
        }
      } catch (e) {
        companyName = "Error fetching company";
      }
    } else {
      companyName = "Unknown Company";
    }

    if (serviceId.isNotEmpty) {
      try {
        DocumentSnapshot serviceDoc = await FirebaseFirestore.instance
            .collection('services')
            .doc(serviceId)
            .get();
        if (serviceDoc.exists && serviceDoc.data() != null) {
          var serviceData = serviceDoc.data() as Map<String, dynamic>;
          serviceDescription = serviceData['description']?.toString() ??
              "No description available";
        }
      } catch (e) {
        serviceDescription = "Error fetching description";
      }
    } else {
      serviceDescription = "No description available";
    }

    String formattedDate = _formatDate(booking['selectedDate']);
    String formattedTime = booking['selectedTime'];

    String serviceName =
        booking['serviceName']?.toString() ?? "Unknown Service";
    String priceValue = booking['price']?.toString() ?? "0";
    String priceUnit = booking['priceUnit']?.toString() ?? "per service";

    DateTime bookingDateTime =
        DateTime.tryParse(booking['selectedDate'] ?? "") ?? DateTime.now();
    DateTime now = DateTime.now();
    bool canCancel =
        now.isBefore(bookingDateTime.subtract(Duration(hours: 24)));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Booking Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.business, "Company:", companyName),
              _detailRow(Icons.email, "Email:", companyEmail),
              _detailRow(Icons.phone, "Phone:", companyPhone),
              Divider(),
              _detailRow(Icons.build, "Service:", serviceName),
              _detailRow(Icons.description, "Description:", serviceDescription),
              _detailRow(
                  Icons.attach_money, "Price:", "SAR $priceValue $priceUnit"),
              _detailRow(Icons.calendar_today, "Date:", formattedDate),
              _detailRow(Icons.access_time, "Time:", formattedTime),
            ],
          ),
          actions: [
            if (canCancel)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelBooking(context, bookingId);
                },
                child:
                    Text("Cancel Booking", style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _cancelBooking(BuildContext context, String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Booking cancelled successfully!"),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to cancel booking."),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal, size: 20),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              "$label $value",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
