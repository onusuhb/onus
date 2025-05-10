import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ServiceDetailsPage.dart';
import 'models/service.dart';

class AllFeaturedServicesPage extends StatefulWidget {
  const AllFeaturedServicesPage({super.key});

  @override
  _AllFeaturedServicesPageState createState() =>
      _AllFeaturedServicesPageState();
}

class _AllFeaturedServicesPageState extends State<AllFeaturedServicesPage> {
  String searchQuery = '';
  String selectedCategory = 'All';
  double minPrice = 0;
  double maxPrice = 10000;
  bool sortByRating = false;

  final List<String> categories = [
    'All',
    'Construction',
    'Renovation',
    'Equipment Rental',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Featured Services'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search services...',
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
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Min Price'),
                        onChanged: (value) {
                          setState(() {
                            minPrice = double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Max Price'),
                        onChanged: (value) {
                          setState(() {
                            maxPrice = double.tryParse(value) ?? 10000;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sort by Rating',
                        style: TextStyle(fontSize: 16)),
                    Switch(
                      value: sortByRating,
                      onChanged: (value) {
                        setState(() {
                          sortByRating = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('services')
                  .orderBy('createdAt', descending: true)
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
                }).where((service) {
                  return service.name.toLowerCase().contains(searchQuery) &&
                      (selectedCategory == 'All' ||
                          service.category == selectedCategory) &&
                      service.priceValue >= minPrice &&
                      service.priceValue <= maxPrice;
                }).toList();

                if (sortByRating) {
                  services.sort((a, b) => b.rating.compareTo(a.rating));
                }

                return ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Image.network(services[index].image,
                          width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(services[index].name),
                      subtitle: Text("${services[index].priceValue}"),
                      trailing:
                          const Icon(Icons.arrow_forward, color: Colors.teal),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ServiceDetailsPage(service: services[index]),
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

  double _extractPrice(String priceString) {
    if (priceString.isEmpty) return 0.0;
    String priceDigits = priceString.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(priceDigits) ?? 0.0;
  }
}
