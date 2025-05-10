class Service {
  final String id;
  final String name;
  final String category;
  final String image;
  final String description;
  final double priceValue;
  final String priceUnit;
  final String contact;
  final String email;
  final double rating;
  final String userId;
  final bool hasInventory;
  final int stockQuantity;

  Service({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.description,
    required this.priceValue,
    required this.priceUnit,
    required this.contact,
    required this.email,
    required this.rating,
    required this.userId,
    this.hasInventory = false,
    this.stockQuantity = 0,
  });

  factory Service.fromFirestore(Map<String, dynamic> data, String documentId) {
    print('Creating Service from Firestore data:');
    print('hasInventory: ${data['hasInventory']}');
    print('stockQuantity: ${data['stockQuantity']}');

    return Service(
      id: documentId,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      image: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      priceValue: (data['priceValue'] ?? 0.0).toDouble(),
      priceUnit: data['priceUnit'] ?? '',
      contact: data['contact'] ?? '',
      email: data['email'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      userId: data['userId'] ?? '',
      hasInventory: data['hasInventory'] ?? false,
      stockQuantity: (data['stockQuantity'] ?? 0).toInt(),
    );
  }
}
