import 'package:flutter/foundation.dart';

import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  double _discount = 0;
  bool _isPercentageDiscount = false; // Discount အမျိုးအစား စစ်ရန်

  // =========================
  // GETTERS
  // =========================

  List<CartItemModel> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);

  double get discount => _discount;

  bool get isPercentageDiscount => _isPercentageDiscount;

  // Real Discount Value ကို တွက်ချက်ခြင်း (Amount သို့မဟုတ် %)
  double get discountAmount {
    if (_isPercentageDiscount) {
      return (subtotal * _discount) / 100;
    }
    return _discount;
  }

  // Final Total Amount
  double get total {
    final calculatedTotal = subtotal - discountAmount;
    return calculatedTotal < 0 ? 0 : calculatedTotal;
  }

  // =========================
  // ADD PRODUCT (With Stock Validation)
  // =========================

  /// Product ကို Cart ထဲ ထည့်ခြင်း (Stock မပြည့်သေးပါက)
  bool addProduct(ProductModel product) {
    if (product.stock <= 0) return false;

    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      // ရှိပြီးသား item ဖြစ်ပါက Stock မကျော်မှ Quantity တိုးမည်
      if (_items[index].quantity < product.stock) {
        _items[index].quantity++;
        notifyListeners();
        return true;
      } else {
        return false; // Stock ပြည့်နေပါက false Return ပြန်မည်
      }
    } else {
      // Item အသစ်ထည့်မည်
      _items.add(CartItemModel(product: product, quantity: 1));
      notifyListeners();
      return true;
    }
  }

  // =========================
  // QUANTITY CONTROL
  // =========================

  bool increaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index == -1) return false;

    final item = _items[index];

    // Stock ထက် quantity မကျော်စေရ
    if (item.quantity >= item.product.stock) {
      return false;
    }

    item.quantity++;
    _validateDiscount(); // Subtotal ပြောင်းသွားပါက Discount ကို ပြန်စစ်ခြင်း
    notifyListeners();
    return true;
  }

  void decreaseQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index == -1) return;

    final item = _items[index];

    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.removeAt(index);
    }

    _validateDiscount();
    notifyListeners();
  }

  void removeProduct(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _validateDiscount();
    notifyListeners();
  }

  // =========================
  // DISCOUNT MANAGEMENT
  // =========================

  /// Discount သတ်မှတ်ခြင်း (Percentage သို့မဟုတ် Fixed Amount)
  void setDiscount(double value, {bool isPercentage = false}) {
    _isPercentageDiscount = isPercentage;

    if (value < 0) {
      _discount = 0;
    } else if (isPercentage) {
      // Percent ဆိုပါက 100% ထက် မပိုစေရ
      _discount = value > 100 ? 100 : value;
    } else {
      // Amount ဆိုပါက Subtotal ထက် မပိုစေရ
      _discount = value > subtotal ? subtotal : value;
    }

    notifyListeners();
  }

  /// Quantity လျှော့သွား၍ Subtotal လျော့သွားပါက Discount ပမာဏကို ပြန်လည်ညှိပေးခြင်း
  void _validateDiscount() {
    if (!_isPercentageDiscount && _discount > subtotal) {
      _discount = subtotal;
    }
  }

  // =========================
  // CLEAR CART
  // =========================

  void clearCart() {
    _items.clear();
    _discount = 0;
    _isPercentageDiscount = false;
    notifyListeners();
  }
}
// import 'package:flutter/foundation.dart';

// import '../models/cart_item_model.dart';
// import '../models/product_model.dart';

// class CartProvider extends ChangeNotifier {
//   final List<CartItemModel> _items = [];

//   // =========================
//   // GETTERS
//   // =========================

//   List<CartItemModel> get items {
//     return List.unmodifiable(_items);
//   }

//   // Cart ထဲမှာ item ဘယ်နှခုရှိလဲ
//   int get itemCount {
//     return _items.length;
//   }

//   // Product အားလုံးရဲ့ quantity စုစုပေါင်း
//   int get totalQuantity {
//     return _items.fold(0, (sum, item) => sum + item.quantity);
//   }

//   // Subtotal
//   double get subtotal {
//     return _items.fold(0, (sum, item) => sum + item.total);
//   }

//   // Discount
//   double _discount = 0;

//   double get discount {
//     return _discount;
//   }

//   // Final Total
//   double get total {
//     return subtotal - discount;
//   }

//   // =========================
//   // ADD PRODUCT
//   // =========================

//   void addProduct(ProductModel product) {
//     final index = _items.indexWhere((item) => item.product.id == product.id);

//     if (index != -1) {
//       // ရှိပြီးသား item ဖြစ်ရင် quantity တိုး
//       _items[index].quantity++;
//     } else {
//       // မရှိသေးရင် item အသစ်ထည့်
//       _items.add(CartItemModel(product: product, quantity: 1));
//     }

//     notifyListeners();
//   }

//   // =========================
//   // INCREASE
//   // =========================

//   void increaseQuantity(String productId) {
//     final index = _items.indexWhere((item) => item.product.id == productId);

//     if (index == -1) {
//       return;
//     }

//     final item = _items[index];

//     // Stock ထက် quantity မကျော်စေ
//     if (item.quantity >= item.product.stock) {
//       return;
//     }

//     item.quantity++;

//     notifyListeners();
//   }

//   // =========================
//   // DECREASE
//   // =========================

//   void decreaseQuantity(String productId) {
//     final index = _items.indexWhere((item) => item.product.id == productId);

//     if (index == -1) {
//       return;
//     }

//     final item = _items[index];

//     if (item.quantity > 1) {
//       item.quantity--;
//     } else {
//       // Quantity 1 ဖြစ်ရင် item ကို remove
//       _items.removeAt(index);
//     }

//     notifyListeners();
//   }

//   // =========================
//   // REMOVE
//   // =========================

//   void removeProduct(String productId) {
//     _items.removeWhere((item) => item.product.id == productId);

//     notifyListeners();
//   }

//   // =========================
//   // DISCOUNT
//   // =========================

//   void setDiscount(double value) {
//     if (value < 0) {
//       _discount = 0;
//     } else if (value > subtotal) {
//       _discount = subtotal;
//     } else {
//       _discount = value;
//     }

//     notifyListeners();
//   }

//   // =========================
//   // CLEAR CART
//   // =========================

//   void clearCart() {
//     _items.clear();
//     _discount = 0;

//     notifyListeners();
//   }
// }
