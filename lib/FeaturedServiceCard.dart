import 'package:flutter/material.dart';

import 'models/service.dart';

class FeaturedServiceCard extends StatelessWidget {
  final Service service;

  const FeaturedServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(left: 16.0),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: service.image.isNotEmpty
                  ? Image.network(
                      service.image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            service.name,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}



 