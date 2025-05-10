import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ServiceDetailsPage.dart';
import 'models/service.dart';

class CompanyServicesPage extends StatefulWidget {
  final String companyId;
  final String companyName;

  const CompanyServicesPage(
      {super.key, required this.companyId, required this.companyName});

  @override
  _CompanyServicesPageState createState() => _CompanyServicesPageState();
}

class _CompanyServicesPageState extends State<CompanyServicesPage> {
  String searchQuery = "";
  String selectedCategory = "All";
  String selectedSort = "None";

  List<String> categories = [
    "All",
    "Construction",
    "Renovation",
    "Equipment Rental"
  ];
  List<String> sortOptions = [
    "None",
    "Price: Low to High",
    "Price: High to Low"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.companyName} Services'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  searchQuery = query.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Filter by Category",
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value as String;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedSort,
                    decoration: const InputDecoration(
                      labelText: "Sort by Price",
                      border: OutlineInputBorder(),
                    ),
                    items: sortOptions.map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text(sort),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedSort = value as String;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .where('userId', isEqualTo: widget.companyId)
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
                    rating: 0,
                    hasInventory: data['hasInventory'] ?? false,
                    stockQuantity: data['stockQuantity'] ?? 0,
                  );
                }).toList();

                if (searchQuery.isNotEmpty) {
                  services = services
                      .where((service) =>
                          service.name.toLowerCase().contains(searchQuery))
                      .toList();
                }

                if (selectedCategory != "All") {
                  services = services
                      .where((service) => service.category == selectedCategory)
                      .toList();
                }

                if (selectedSort == "Price: Low to High") {
                  services.sort((a, b) => double.parse(a.priceValue.toString())
                      .compareTo(double.parse(b.priceValue.toString())));
                } else if (selectedSort == "Price: High to Low") {
                  services.sort((a, b) => double.parse(b.priceValue.toString())
                      .compareTo(double.parse(a.priceValue.toString())));
                }

                return services.isEmpty
                    ? const Center(child: Text("No services found."))
                    : ListView.builder(
                        itemCount: services.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: services[index].image.isNotEmpty
                                  ? Image.network(services[index].image,
                                      width: 50, height: 50, fit: BoxFit.cover)
                                  : const Icon(Icons.image_not_supported,
                                      size: 50, color: Colors.grey),
                            ),
                            title: Text(services[index].name),
                            subtitle: Text(
                                "Price: SAR ${services[index].priceValue}"),
                            trailing: const Icon(Icons.arrow_forward,
                                color: Colors.teal),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServiceDetailsPage(
                                      service: services[index]),
                                ),
                              );
                            },
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
