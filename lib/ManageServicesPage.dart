import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:onus/AddServicePage.dart';
import 'package:onus/EditServicePage.dart';

class ManageServicesPage extends StatefulWidget {
  const ManageServicesPage({super.key});

  @override
  _ManageServicesPageState createState() => _ManageServicesPageState();
}

class _ManageServicesPageState extends State<ManageServicesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    if (_currentUser != null) {
      final doc =
          await _firestore.collection('users').doc(_currentUser!.uid).get();
      setState(() {
        _userRole = doc['role'] ?? 'User';
      });
    }
  }

  Stream<QuerySnapshot> _getServicesStream() {
    if (_userRole == 'Admin') {
      return _firestore.collection('services').snapshots();
    } else {
      return _firestore
          .collection('services')
          .where('userId', isEqualTo: _currentUser!.uid)
          .snapshots();
    }
  }

  Future<void> _deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete service: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Services')),
        body: const Center(child: Text('Please log in to manage services')),
      );
    }

    if (_userRole == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getServicesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No services available"));
                }

                final services = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final serviceData = service.data() as Map<String, dynamic>;

                    double priceValue =
                        (serviceData['priceValue'] ?? 0).toDouble();
                    String priceUnit = serviceData['priceUnit'] ?? 'session';
                    bool hasInventory = serviceData['hasInventory'] ?? false;
                    int stockQuantity = serviceData['stockQuantity'] ?? 0;

                    print('Service data: $serviceData');
                    print('Has inventory: $hasInventory');
                    print('Stock quantity: $stockQuantity');

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading: serviceData['imageUrl'] != null &&
                                serviceData['imageUrl'].isNotEmpty
                            ? Image.network(
                                serviceData['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported, size: 50),
                        title: Text(
                          serviceData['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4.0),
                            Text('Price: SAR $priceValue per $priceUnit'),
                            Text(
                                'Category: ${serviceData['category'] ?? 'Not Specified'}'),
                            Text(
                                'Available: ${serviceData['isAvailable'] ? 'Yes' : 'No'}'),
                            if (hasInventory) ...[
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: stockQuantity > 0
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  stockQuantity > 0
                                      ? '$stockQuantity in stock'
                                      : 'Out of stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: stockQuantity > 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                            if (_userRole == 'Admin')
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(serviceData['userId'])
                                    .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text('Loading owner info...');
                                  }
                                  if (!snapshot.hasData ||
                                      !snapshot.data!.exists) {
                                    return const Text('Owner info not found');
                                  }
                                  final user = snapshot.data!.data()
                                      as Map<String, dynamic>;
                                  final name = user['fullName'] ?? 'Unknown';
                                  final email = user['email'] ?? 'Unknown';
                                  return Text('Owner: $name\nEmail: $email');
                                },
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'Edit') {
                              print('Editing service with ID: ${service.id}');
                              print(
                                  'Has inventory: ${serviceData['hasInventory']}');
                              print(
                                  'Stock quantity: ${serviceData['stockQuantity']}');

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditServicePage(
                                    serviceId: service.id,
                                    serviceName: serviceData['name'],
                                    description: serviceData['description'],
                                    priceValue: priceValue,
                                    priceUnit: priceUnit,
                                    isAvailable: serviceData['isAvailable'],
                                    imageUrl: serviceData['imageUrl'] ?? '',
                                    imagePublicId:
                                        serviceData['imagePublicId'] ?? '',
                                    category: serviceData['category'] ??
                                        'Not Specified',
                                    hasInventory:
                                        serviceData['hasInventory'] ?? false,
                                    stockQuantity:
                                        serviceData['stockQuantity'] ?? 0,
                                  ),
                                ),
                              );
                            } else if (value == 'Delete') {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Delete Service'),
                                    content: Text(
                                      'Are you sure you want to delete the service "${serviceData['name']}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteService(service.id);
                                        },
                                        child: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'Edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'Delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
