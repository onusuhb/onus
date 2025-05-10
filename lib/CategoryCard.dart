import 'package:flutter/material.dart';
import 'package:onus/CategoryServicesPage.dart';

class Category {
  final String name;
  final IconData icon;

  Category({required this.name, required this.icon});
}

class CategoryCard extends StatelessWidget {
  final Category category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryServicesPage(categoryName: category.name),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.teal,
            child: Icon(category.icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8.0),
          Text(category.name, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
