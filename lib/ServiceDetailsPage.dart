import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onus/BookingConfirmationPage.dart';
import 'package:flutter/material.dart';
import 'models/service.dart';

class ServiceDetailsPage extends StatefulWidget {
  final Service service;

  const ServiceDetailsPage({super.key, required this.service});

  @override
  _ServiceDetailsPageState createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  String _companyName = "Loading...";
  String _userRole = "Customer";

  @override
  void initState() {
    super.initState();
    _fetchCompanyName();
    _fetchUserRole();

     print('=== Service Details Debug Info ===');
    print('Service ID: ${widget.service.id}');
    print('Service Name: ${widget.service.name}');
    print('Service Category: ${widget.service.category}');
    print('Has Inventory: ${widget.service.hasInventory}');
    print('Stock Quantity: ${widget.service.stockQuantity}');
    print(
        'Raw Stock Quantity Type: ${widget.service.stockQuantity.runtimeType}');
    print('================================');
  }

  Future<void> _fetchCompanyName() async {
    if (widget.service.userId.isNotEmpty) {
      try {
        DocumentSnapshot companyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.service.userId)
            .get();

        if (companyDoc.exists) {
          setState(() {
            _companyName = companyDoc['fullName'] ?? "Unknown Company";
          });
        } else {
          setState(() {
            _companyName = "Unknown Company";
          });
        }
      } catch (e) {
        setState(() {
          _companyName = "Error fetching company";
        });
      }
    }
  }

  Future<void> _fetchUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userRole = userDoc['role'] ?? 'Customer';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     print(
        'Building ServiceDetailsPage with stock quantity: ${widget.service.stockQuantity}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: widget.service.image.isNotEmpty
                    ? Image.network(
                        widget.service.image,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported,
                            size: 80, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.business, color: Colors.teal),
                const SizedBox(width: 8.0),
                Flexible(
                  child: Text(
                    "Company: $_companyName",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                const Icon(Icons.work, color: Colors.teal),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    widget.service.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.category, color: Colors.teal),
                const SizedBox(width: 8.0),
                const Text(
                  'Category:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    widget.service.category,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                const Icon(Icons.description, color: Colors.teal),
                const SizedBox(width: 8.0),
                const Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(widget.service.description,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16.0),
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.teal),
                const SizedBox(width: 8.0),
                const Text(
                  'Price:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  'SAR ${widget.service.priceValue.toStringAsFixed(2)} ${widget.service.priceUnit}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            if (widget.service.hasInventory) ...[
              Row(
                children: [
                  const Icon(Icons.inventory_2, color: Colors.teal),
                  const SizedBox(width: 8.0),
                  const Text(
                    'Stock:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Builder(builder: (context) {
                     print(
                        'Building stock container with quantity: ${widget.service.stockQuantity}');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.service.stockQuantity > 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.service.stockQuantity > 0
                            ? '${widget.service.stockQuantity} items available'
                            : 'Out of stock',
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.service.stockQuantity > 0
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16.0),
            ],
            if (widget.service.rating != null && widget.service.rating > 0) ...[
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.teal),
                  const SizedBox(width: 8.0),
                  const Text(
                    'Reviews & Ratings:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(widget.service.rating.toString(),
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16.0),
            ],
            if (_userRole != "Company" &&
                (!widget.service.hasInventory ||
                    widget.service.stockQuantity > 0))
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingConfirmationPage(
                          service: widget.service,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.book_online, color: Colors.white),
                  label: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
