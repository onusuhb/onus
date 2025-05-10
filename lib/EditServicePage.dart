import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditServicePage extends StatefulWidget {
  final String serviceId;
  final String serviceName;
  final String description;
  final double priceValue;
  final String priceUnit;
  final bool isAvailable;
  final String imageUrl;
  final String imagePublicId;
  final String category;
  final bool hasInventory;
  final int stockQuantity;

  const EditServicePage({
    super.key,
    required this.serviceId,
    required this.serviceName,
    required this.description,
    required this.priceValue,
    required this.priceUnit,
    required this.isAvailable,
    required this.imageUrl,
    required this.imagePublicId,
    required this.category,
    this.hasInventory = false,
    this.stockQuantity = 0,
  });

  @override
  _EditServicePageState createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController serviceNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController stockController = TextEditingController();

  bool isAvailable = true;
  bool hasInventory = false;
  File? _selectedImage;
  String? _uploadedImageUrl;
  String? _uploadedImagePublicId;

  final List<String> categories = [
    "Construction",
    "Renovation",
    "Equipment Rental"
  ];
  String _selectedCategory = "Construction";

  final List<String> priceUnits = [
    "hour",
    "day",
    "project",
    "window",
    "roof",
    "session"
  ];
  String _selectedPriceUnit = "hour";

  final List<String> inventoryCategories = ["Equipment Rental"];

  @override
  void initState() {
    super.initState();
    serviceNameController.text = widget.serviceName;
    descriptionController.text = widget.description;
    priceController.text = widget.priceValue.toString();
    isAvailable = widget.isAvailable;
    _uploadedImageUrl = widget.imageUrl;
    _uploadedImagePublicId = widget.imagePublicId;
    _selectedCategory = widget.category;
    hasInventory = widget.hasInventory;
    stockController.text = widget.stockQuantity.toString();
    _selectedPriceUnit =
        priceUnits.contains(widget.priceUnit) ? widget.priceUnit : "hour";

    print('EditServicePage initialized with:');
    print('Service ID: ${widget.serviceId}');
    print('Has Inventory: ${widget.hasInventory}');
    print('Stock Quantity: ${widget.stockQuantity}');
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<Map<String, String>?> _uploadImageToCloudinary(File imageFile) async {
    const String cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/dbd9sw3fh/image/upload";
    const String uploadPreset = "onusfiles";

    var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl));
    request.fields["upload_preset"] = uploadPreset;
    request.files
        .add(await http.MultipartFile.fromPath("file", imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      final responseData = jsonDecode(await response.stream.bytesToString());
      return {
        "secure_url": responseData["secure_url"],
        "public_id": responseData["public_id"]
      };
    }
    return null;
  }

  Future<void> _deleteOldImageFromCloudinary(String publicId) async {
    const String cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/dbd9sw3fh/image/destroy";

    var response = await http.post(
      Uri.parse(cloudinaryUrl),
      body: {
        "public_id": publicId,
        "api_key": "198878421739112",
        "api_secret": "poDTQw35earR1bD3Ub5vbeK9FFY"
      },
    );

    if (response.statusCode == 200) {
      print("Old image deleted from Cloudinary");
    } else {
      print("Failed to delete old image from Cloudinary: ${response.body}");
    }
  }

  Future<void> _updateService() async {
    if (_formKey.currentState!.validate()) {
      String? imageUrl = _uploadedImageUrl;
      String? imagePublicId = _uploadedImagePublicId;

      if (_selectedImage != null) {
        var uploadResult = await _uploadImageToCloudinary(_selectedImage!);
        if (uploadResult != null) {
          imageUrl = uploadResult["secure_url"];
          imagePublicId = uploadResult["public_id"];

          if (_uploadedImagePublicId != null) {
            await _deleteOldImageFromCloudinary(_uploadedImagePublicId!);
          }
        }
      }

      double? priceValue = double.tryParse(priceController.text.trim());
      if (priceValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Invalid price entered"),
              backgroundColor: Colors.red),
        );
        return;
      }

      int? stockQuantity;
      if (hasInventory) {
        stockQuantity = int.tryParse(stockController.text.trim());
        if (stockQuantity == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Invalid stock quantity entered"),
                backgroundColor: Colors.red),
          );
          return;
        }
      }

      await _firestore.collection('services').doc(widget.serviceId).update({
        'name': serviceNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'priceValue': priceValue,
        'priceUnit': _selectedPriceUnit,
        'category': _selectedCategory,
        'isAvailable': isAvailable,
        'imageUrl': imageUrl ?? '',
        'imagePublicId': imagePublicId ?? '',
        'hasInventory': hasInventory,
        'stockQuantity': stockQuantity ?? 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Service updated successfully"),
            backgroundColor: Colors.green),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Edit Service'), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: serviceNameController,
                decoration: const InputDecoration(
                    labelText: 'Service Name', border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a service name' : null,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Description', border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Price', border: OutlineInputBorder()),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a price' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriceUnit,
                      decoration: const InputDecoration(
                          labelText: 'Per', border: OutlineInputBorder()),
                      items: priceUnits.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPriceUnit = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                    labelText: 'Category', border: OutlineInputBorder()),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                    hasInventory = inventoryCategories.contains(newValue);
                    if (!hasInventory) {
                      stockController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16.0),
              if (hasInventory) ...[
                TextFormField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                    border: OutlineInputBorder(),
                    helperText: 'Enter the number of items available',
                  ),
                  validator: (value) {
                    if (hasInventory && (value == null || value.isEmpty)) {
                      return 'Please enter stock quantity';
                    }
                    if (hasInventory && int.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available', style: TextStyle(fontSize: 16)),
                  Switch(
                      value: isAvailable,
                      onChanged: (value) =>
                          setState(() => isAvailable = value)),
                ],
              ),
              const SizedBox(height: 16.0),
              _selectedImage == null && _uploadedImageUrl == null
                  ? ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload, color: Colors.white),
                      label: const Text('Upload Image',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal),
                    )
                  : Column(
                      children: [
                        if (_selectedImage != null)
                          Image.file(
                            _selectedImage!,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 100,
                                child: Center(
                                  child: Icon(Icons.error_outline, size: 50),
                                ),
                              );
                            },
                          )
                        else if (_uploadedImageUrl != null &&
                            _uploadedImageUrl!.isNotEmpty)
                          Image.network(
                            _uploadedImageUrl!,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(
                                height: 100,
                                child: Center(
                                  child: Icon(Icons.error_outline, size: 50),
                                ),
                              );
                            },
                          )
                        else
                          const SizedBox(
                            height: 100,
                            child: Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          ),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text("Change Image"),
                          onPressed: _pickImage,
                        ),
                      ],
                    ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _updateService,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Update Service',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
