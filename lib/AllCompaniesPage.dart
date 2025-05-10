import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CompanyServicesPage.dart';

class AllCompaniesPage extends StatefulWidget {
  const AllCompaniesPage({super.key});

  @override
  _AllCompaniesPageState createState() => _AllCompaniesPageState();
}

class _AllCompaniesPageState extends State<AllCompaniesPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Companies'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
           Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

           Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Company')
                  .orderBy('fullName')
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
                    address: data['address'] ?? 'No address provided',
                  );
                }).where((company) {
                  return company.name.toLowerCase().contains(searchQuery);
                }).toList();

                if (companies.isEmpty) {
                  return const Center(child: Text("No matching companies found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    return CompanyCard(company: companies[index]);
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

 class Company {
  final String id;
  final String name;
  final String logo;
  final String address;

  Company({required this.id, required this.name, required this.logo, required this.address});
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
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: company.logo.isNotEmpty
                ? NetworkImage(company.logo)
                : const AssetImage('assets/company_placeholder.png') as ImageProvider,
          ),
          title: Text(
            company.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(company.address),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
        ),
      ),
    );
  }
}
