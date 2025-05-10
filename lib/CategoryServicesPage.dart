import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ServiceDetailsPage.dart';
import 'models/service.dart';

class CategoryServicesPage extends StatelessWidget {
  final String categoryName;

  const CategoryServicesPage({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryName Services'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('category', isEqualTo: categoryName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No services available in $categoryName',
                style: const TextStyle(fontSize: 18),
              ),
            );
          }

          final services = snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;
            return Service(
              id: doc.id,
              userId: data['userId'],
              name: data['name'],
              category: data['category'] ?? 'Not Specified',
              image: data['imageUrl'] ?? '',
              description: data['description'],
              priceValue: (data['priceValue'] as num).toDouble(),
              contact: 'N/A',
              email: 'N/A',
              rating: 0,
              priceUnit: data['priceUnit'],
              hasInventory: data['hasInventory'] ?? false,
              stockQuantity: data['stockQuantity'] ?? 0,
            );
          }).toList();

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: services[index].image.isNotEmpty
                      ? Image.network(
                          services[index].image,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported,
                          size: 50, color: Colors.grey),
                ),
                title: Text(services[index].name),
                subtitle: Text(services[index].priceValue.toString()),
                trailing: const Icon(Icons.arrow_forward, color: Colors.teal),
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
              );
            },
          );
        },
      ),
    );
  }
}
