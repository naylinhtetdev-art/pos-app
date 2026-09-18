import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pos_app/services/product_service.dart';

import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  StreamSubscription<List<ProductModel>>? _subscription;
  bool _isLoading = false;

  String _searchText = '';
  String _selectedCategory = 'All';

  // -------------------------
  // GETTERS
  // -------------------------

  List<ProductModel> get products => _products;

  bool get isLoading => _isLoading;

  String get selectedCategory => _selectedCategory;

  String get searchText => _searchText;

  // -------------------------
  // FILTERED PRODUCTS
  // -------------------------

  List<ProductModel> get filteredProducts {
    return _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        _searchText.toLowerCase(),
      );

      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // -------------------------
  // CATEGORIES
  // -------------------------

  List<String> get categories {
    final categorySet = <String>{
      'All',
      ..._products.map((product) => product.category),
    };

    return categorySet.toList();
  }

  // -------------------------
  // FIRESTORE LISTEN (REAL-TIME DATA)
  // -------------------------

  void start(String uid) {
    _subscription?.cancel();

    _isLoading = true;
    notifyListeners();

    _subscription = _productService
        .productsStream(uid)
        .listen(
          (products) {
            _products = products;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            _isLoading = false;
            notifyListeners();
            debugPrint('Product stream error: $error');
          },
        );
  }

  // -------------------------
  // CREATE
  // -------------------------

  Future<void> addProduct({
    required String uid,
    required String name,
    required double price,
    required double cost,
    required int stock,
    required String category,
  }) async {
    await _productService.addProduct(
      uid: uid,
      name: name,
      price: price,
      cost: cost,
      stock: stock,
      category: category,
    );
  }

  // -------------------------
  // UPDATE
  // -------------------------

  Future<void> updateProduct({
    required String uid,
    required String productId,
    required String name,
    required double price,
    required double cost,
    required int stock,
    required String category,
  }) async {
    await _productService.updateProduct(
      uid: uid,
      productId: productId,
      name: name,
      price: price,
      cost: cost,
      stock: stock,
      category: category,
    );
  }

  // -------------------------
  // DELETE
  // -------------------------

  Future<void> deleteProduct({
    required String uid,
    required String productId,
  }) async {
    await _productService.deleteProduct(uid: uid, productId: productId);
  }

  // -------------------------
  // SEARCH & CATEGORY ACTIONS
  // -------------------------

  void search(String value) {
    _searchText = value;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // -------------------------
  // CLEAR CACHE ON LOGOUT
  // -------------------------
  void clearProducts() {
    _subscription?.cancel(); // Real-time listener ကို ပိတ်မည်
    _subscription = null;
    _products = []; // List ထဲက product များကို ရှင်းထုတ်မည်
    _searchText = ''; // Search Text ကို Reset လုပ်မည်
    _selectedCategory = 'All'; // Selected Category ကို Reset လုပ်မည်
    notifyListeners(); // UI ကို Clean ဖြစ်သွားကြောင်း အသိပေးမည်
  }
}
