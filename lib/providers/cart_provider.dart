import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];

  // =========================
  // GETTERS
  // =========================

  List<CartItemModel> get items {
    return List.unmodifiable(_items);
  }

  // Cart ထဲမှာ item ဘယ်နှခုရှိလဲ
  int get itemCount {
    return _items.length;
  }

  // Product အားလုံးရဲ့ quantity စုစုပေါင်း
  int get totalQuantity {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Subtotal
  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.total);
  }

  // Discount
  double _discount = 0;

  double get discount {
    return _discount;
  }

  // Final Total
  double get total {
    return subtotal - discount;
  }

  // =========================
  // ADD PRODUCT
  // =========================

  void addProduct(ProductModel product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      // ရှိပြီးသား item ဖြစ်ရင် quantity တိုး
      _items[index].quantity++;
    } else {
      // မရှိသေးရင် item အသစ်ထည့်
      _items.add(CartItemModel(product: product, quantity: 1));
    }

    notifyListeners();
  }

  // =========================
  // INCREASE
  // =========================

  void increaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index == -1) {
      return;
    }

    final item = _items[index];

    // Stock ထက် quantity မကျော်စေ
    if (item.quantity >= item.product.stock) {
      return;
    }

    item.quantity++;

    notifyListeners();
  }

  // =========================
  // DECREASE
  // =========================

  void decreaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index == -1) {
      return;
    }

    final item = _items[index];

    if (item.quantity > 1) {
      item.quantity--;
    } else {
      // Quantity 1 ဖြစ်ရင် item ကို remove
      _items.removeAt(index);
    }

    notifyListeners();
  }

  // =========================
  // REMOVE
  // =========================

  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);

    notifyListeners();
  }

  // =========================
  // DISCOUNT
  // =========================

  void setDiscount(double value) {
    if (value < 0) {
      _discount = 0;
    } else if (value > subtotal) {
      _discount = subtotal;
    } else {
      _discount = value;
    }

    notifyListeners();
  }

  // =========================
  // CLEAR CART
  // =========================

  void clearCart() {
    _items.clear();
    _discount = 0;

    notifyListeners();
  }
}
