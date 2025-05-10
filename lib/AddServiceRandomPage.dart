import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class AddServiceRandomPage extends StatefulWidget {
  const AddServiceRandomPage({super.key});

  @override
  _AddServiceRandomPageState createState() => _AddServiceRandomPageState();
}

class _AddServiceRandomPageState extends State<AddServiceRandomPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> categories = [
    "Construction",
    "Renovation",
    "Equipment Rental"
  ];

  final List<Map<String, dynamic>> sampleServices = [
    {
      'name': 'Concrete Pouring',
      'description': 'High-quality concrete pouring for construction projects.',
      'priceValue': 2000.0,
      'priceUnit': ' project',
      'image': 'concrete_pouring.png',
      'isSelected': false,
      'category': 'Construction',
    },
    {
      'name': 'House Painting',
      'description':
          'Professional house painting services with durable finish.',
      'priceValue': 1500.0,
      'priceUnit': ' house',
      'image': 'house_painting.jpg',
      'isSelected': false,
      'category': 'Renovation',
    },
    {
      'name': 'Plumbing Installation',
      'description':
          'Expert plumbing services for homes and commercial properties.',
      'priceValue': 500.0,
      'priceUnit': ' hour',
      'image': 'plumbing.jpg',
      'isSelected': false,
      'category': 'Renovation',
    },
    {
      'name': 'Electric Wiring',
      'description': 'Certified electrical wiring installation and repairs.',
      'priceValue': 700.0,
      'priceUnit': ' service',
      'image': 'electric_wiring.jpg',
      'isSelected': false,
      'category': 'Renovation',
    },
    {
      'name': 'Heavy Equipment Rental',
      'description':
          'Rent heavy-duty construction equipment at affordable rates.',
      'priceValue': 3000.0,
      'priceUnit': ' day',
      'image': 'equipment_rental.png',
      'isSelected': false,
      'category': 'Equipment Rental',
    },
  ];

  Future<String?> _uploadImageToCloudinary(String assetImage) async {
    try {
      ByteData bytes = await rootBundle.load('assets/$assetImage');
      List<int> imageData = bytes.buffer.asUint8List();

      Directory tempDir = await getTemporaryDirectory();
      File tempFile = File('${tempDir.path}/$assetImage');
      await tempFile.writeAsBytes(imageData);

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://api.cloudinary.com/v1_1/dbd9sw3fh/image/upload"),
      );
      request.fields["upload_preset"] = "onusfiles";
      request.files
          .add(await http.MultipartFile.fromPath("file", tempFile.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = jsonDecode(await response.stream.bytesToString());
        return responseData["secure_url"];
      } else {
        return null;
      }
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _addSelectedServices() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    int addedCount = 0;
    for (var service in sampleServices) {
      if (service['isSelected'] == true) {
        final imageName = service['image'];
        String? imageUrl = await _uploadImageToCloudinary(imageName);

        String category = service['category'] ?? categories[0];
        bool hasInventory = category == 'Equipment Rental';
        int stockQuantity = hasInventory
            ? (3 + (DateTime.now().millisecondsSinceEpoch % 18))
            : 0;

        await _firestore.collection('services').add({
          'userId': currentUser.uid,
          'name': service['name'],
          'description': service['description'],
          'priceValue': service['priceValue'],
          'priceUnit': service['priceUnit'],
          'category': category,
          'isAvailable': true,
          'imageUrl': imageUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'hasInventory': hasInventory,
          'stockQuantity': stockQuantity,
        });
        addedCount++;
      }
    }

    setState(() {
      for (var service in sampleServices) {
        service['isSelected'] = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$addedCount services added successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteAllServices() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    var services = await _firestore
        .collection('services')
        .where('userId', isEqualTo: currentUser.uid)
        .get();

    for (var doc in services.docs) {
      await doc.reference.delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("All services deleted!"), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Services'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: sampleServices.length,
              itemBuilder: (context, index) {
                final service = sampleServices[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: CheckboxListTile(
                    value: service['isSelected'] ?? false,
                    onChanged: (bool? value) {
                      setState(() {
                        service['isSelected'] = value;
                      });
                    },
                    title: Text(service['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service['description']),
                        Text(
                          'SAR ${service['priceValue']}${service['priceUnit']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    secondary: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        'assets/${service['image']}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported,
                              size: 60);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _addSelectedServices,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add Selected",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
                ElevatedButton.icon(
                  onPressed: _deleteAllServices,
                  icon: const Icon(Icons.delete, color: Colors.white),
                  label: const Text("Delete All",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('services')
                .where('userId', isEqualTo: _auth.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final services = snapshot.data!.docs;
              if (services.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("No services added yet."),
                );
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final data = services[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: data['imageUrl'].isNotEmpty
                            ? Image.network(
                                data['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image_not_supported, size: 50),
                        title: Text(data['name']),
                        subtitle: Text(
                          "SAR ${data['priceValue']}${data['priceUnit']}",
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
