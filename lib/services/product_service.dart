import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _productsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('products');
  }

  // CREATE
  Future<void> addProduct({
    required String uid,
    required String name,
    required double price,
    required double cost,
    required int stock,
    required String category,
  }) async {
    await _productsCollection(uid).add({
      'name': name,
      'price': price,
      'cost': cost,
      'stock': stock,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // READ
  Stream<List<ProductModel>> productsStream(String uid) {
    return _productsCollection(
      uid,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductModel.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  // UPDATE
  Future<void> updateProduct({
    required String uid,
    required String productId,
    required String name,
    required double price,
    required double cost,
    required int stock,
    required String category,
  }) async {
    await _productsCollection(uid).doc(productId).update({
      'name': name,
      'price': price,
      'cost': cost,
      'stock': stock,
      'category': category,
    });
  }

  // DELETE
  Future<void> deleteProduct({
    required String uid,
    required String productId,
  }) async {
    await _productsCollection(uid).doc(productId).delete();
  }
}
