import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onus/AllCompaniesPage.dart';
import 'package:onus/AllFeaturedServicesPage.dart';
import 'package:onus/CategoryCard.dart';
import 'package:onus/CompanyServicesPage.dart';
import 'package:onus/PromotionalBanner.dart';
import 'package:onus/dashboard_page.dart';
import 'FeaturedServiceCard.dart';
import 'ServiceDetailsPage.dart';
import 'authentication/login_screen.dart';
import 'models/service.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<Category> categories = [
    Category(name: 'Construction', icon: Icons.business),
    Category(name: 'Renovation', icon: Icons.home_repair_service),
    Category(name: 'Equipment Rental', icon: Icons.build),
  ];

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
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
        title: const Text('Onus'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Notifications coming soon!")));
            },
          ),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Welcome to Onus App!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search services, materials, equipment...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            _buildSectionTitle(context, 'Latest Companies',
                destinationPage: AllCompaniesPage()),
            _buildLatestCompanies(),
            const SizedBox(height: 16.0),
            _buildSectionTitle(context, 'Featured Services',
                destinationPage: AllFeaturedServicesPage()),
            _buildFeaturedServices(),
            const SizedBox(height: 16.0),
            _buildSectionTitle(context, 'Categories'),
            _buildCategoryGrid(context),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: PromotionalBanner(),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title,
      {Widget? destinationPage}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (destinationPage != null)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => destinationPage),
                );
              },
              child: const Text('See All'),
            ),
        ],
      ),
    );
  }

  Widget _buildLatestCompanies() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Company')
          .orderBy('createdAt', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var companies = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return Company(
            id: doc.id,
            name: data['fullName'] ?? 'Unknown Company',
            logo: data['profilePicture'] ?? '',
          );
        }).toList();

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: companies.length,
            itemBuilder: (context, index) {
              return CompanyCard(company: companies[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildFeaturedServices() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .orderBy('createdAt', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var services = snapshot.data!.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return Service(
            id: doc.id,
            userId: data['userId'],
            name: data['name'],
            category: data['category'] ?? 'Not Specified',
            image: data['imageUrl'] ?? '',
            description: data['description'],
            priceValue: (data['priceValue'] as num).toDouble(),
            priceUnit: data['priceUnit'] ?? 'Unknown',
            contact: 'N/A',
            email: 'N/A',
            rating: data['rating'] != null
                ? double.tryParse(data['rating'].toString()) ?? 0.0
                : 0.0,
            hasInventory: data['hasInventory'] ?? false,
            stockQuantity: (data['stockQuantity'] ?? 0).toInt(),
          );
        }).toList();

        return SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsPage(
                        service: services[index],
                      ),
                    ),
                  );
                },
                child: FeaturedServiceCard(service: services[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          return CategoryCard(category: categories[index]);
        },
      ),
    );
  }
}

class Company {
  final String id;
  final String name;
  final String logo;

  Company({required this.id, required this.name, required this.logo});
}

class CompanyCard extends StatelessWidget {
  final Company company;

  const CompanyCard({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompanyServicesPage(
              companyId: company.id,
              companyName: company.name,
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(left: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  company.logo.isNotEmpty ? NetworkImage(company.logo) : null,
              child: company.logo.isEmpty
                  ? const Icon(Icons.business, size: 30, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 8.0),
            SizedBox(
              width: 90,
              child: Text(
                company.name.length > 20
                    ? "${company.name.substring(0, 17)}..."
                    : company.name,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
