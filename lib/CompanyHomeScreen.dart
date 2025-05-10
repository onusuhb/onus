import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onus/authentication/login_screen.dart';
import 'package:onus/dashboard_page.dart';
import 'package:onus/models/service.dart';
import 'package:onus/ServiceDetailsPage.dart';

class CompanyHomeScreen extends StatefulWidget {
  const CompanyHomeScreen({super.key});

  @override
  _CompanyHomeScreenState createState() => _CompanyHomeScreenState();
}

class _CompanyHomeScreenState extends State<CompanyHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String profilePicture = "";
  String companyId = "";

  @override
  void initState() {
    super.initState();
    print('CompanyHomeScreen initialized');
    _fetchCompanyDetails();
  }

  Future<void> _fetchCompanyDetails() async {
    print('Fetching company details...');
    User? user = _auth.currentUser;
    print('Current user: ${user?.uid}');

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        print('User document exists: ${userDoc.exists}');
        if (userDoc.exists) {
          print('User data: ${userDoc.data()}');
          setState(() {
            profilePicture = userDoc['profilePicture'] ?? '';
            companyId = user.uid;
            print('Company ID set to: $companyId');
          });
        } else {
          print('User document does not exist');
          setState(() {
            companyId = user.uid;
            print('Company ID set to user ID: $companyId');
          });
        }
      } catch (e) {
        print('Error fetching company details: $e');
        setState(() {
          companyId = user.uid;
          print('Company ID set to user ID after error: $companyId');
        });
      }
    } else {
      print('No user logged in');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : null,
                  child: profilePicture.isEmpty
                      ? const Icon(Icons.business, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                const Text(
                  "Welcome Back!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "For a complete overview and full details, head over to your dashboard.",
              style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Your Latest 3 Services'),
            _buildCompanyServices(),
            const SizedBox(height: 20),
            _buildSectionTitle('Booking Requests'),
            _buildBookingRequests(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCompanyServices() {
    print('Building company services for companyId: $companyId');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('userId', isEqualTo: companyId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        print('StreamBuilder state: ${snapshot.connectionState}');
        print('Has data: ${snapshot.hasData}');
        print('Has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          print('Error details: ${snapshot.error}');
        }
        if (snapshot.hasData) {
          print('Number of documents: ${snapshot.data!.docs.length}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Connection state: waiting');
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error in stream: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading services: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No data or empty documents');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.grey, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'No services available yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Company ID: $companyId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        var services = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          print('Service data: $data');
          return Service(
            id: doc.id,
            userId: companyId,
            name: data['name'] ?? 'Unnamed Service',
            category: data['category'] ?? 'Not Specified',
            image: data['imageUrl'] ?? '',
            description: data['description'] ?? 'No description available',
            priceValue: (data['priceValue'] as num?)?.toDouble() ?? 0.0,
            priceUnit: data['priceUnit'] ?? 'Unknown',
            contact: 'N/A',
            email: 'N/A',
            rating: data['rating'] != null
                ? double.tryParse(data['rating'].toString()) ?? 0.0
                : 0.0,
            hasInventory: data['hasInventory'] ?? false,
            stockQuantity: data['stockQuantity'] ?? 0,
          );
        }).toList();

        print('Number of services mapped: ${services.length}');

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: services.length,
            itemBuilder: (context, index) {
              print('Building service item $index: ${services[index].name}');
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 0,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: services[index].image.isNotEmpty
                        ? Image.network(
                            services[index].image,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                  'Image error for ${services[index].name}: $error');
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                  ),
                  title: Text(
                    services[index].name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        services[index].category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SAR ${services[index].priceValue.toStringAsFixed(2)} ${services[index].priceUnit}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      if (services[index].hasInventory) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: services[index].stockQuantity > 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            services[index].stockQuantity > 0
                                ? '${services[index].stockQuantity} in stock'
                                : 'Out of stock',
                            style: TextStyle(
                              fontSize: 12,
                              color: services[index].stockQuantity > 0
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.teal, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ServiceDetailsPage(service: services[index]),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingRequests() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('bookings')
          .where('companyId', isEqualTo: companyId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        var bookings = snapshot.data!.docs.length;

        return Text(
          "You have $bookings new booking requests.",
          style: const TextStyle(fontSize: 16),
        );
      },
    );
  }
}
