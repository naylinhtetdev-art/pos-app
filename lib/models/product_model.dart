import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final double price;
  final double cost;
  final int stock;
  final String category;
  final DateTime? createdAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.cost,
    required this.stock,
    required this.category,
    this.createdAt,
  });

  factory ProductModel.fromFirestore(String id, Map<String, dynamic> data) {
    final createdAtData = data['createdAt'];

    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      cost: (data['cost'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      category: data['category'] ?? '',
      createdAt: createdAtData is Timestamp ? createdAtData.toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'cost': cost,
      'stock': stock,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
