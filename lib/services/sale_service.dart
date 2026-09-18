import 'package:cloud_firestore/cloud_firestore.dart';

class SaleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> salesStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sales')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createSale({
    required String uid,
    required String invoiceNo,
    required double subtotal,
    required double discount,
    required double total,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final saleRef = userRef.collection('sales').doc();

    await _firestore.runTransaction((transaction) async {
      // Stock ပြင်ဆင်ရန် Reference နဲ့ Quantity ကို ယာယီသိမ်းမည့် List
      final List<Map<String, dynamic>> stockUpdates = [];

      // =========================
      // 1. READ ALL STOCKS FIRST (အချက်အလက်အားလုံး အရင်ဖတ်မည်)
      // =========================
      for (final item in items) {
        final productId = item['productId'] as String;
        final quantity = item['quantity'] as int;
        final productRef = userRef.collection('products').doc(productId);

        final productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception('Product not found.');
        }

        final data = productSnapshot.data();

        if (data == null) {
          throw Exception('Product data not found.');
        }

        final currentStock = (data['stock'] ?? 0) as int;

        if (currentStock < quantity) {
          throw Exception('${data['name']} stock is not enough.');
        }

        // Write ပြန်လုပ်ရန်အတွက် Reference နဲ့ newStock ကို သိမ်းဆည်းထားမည်
        stockUpdates.add({
          'ref': productRef,
          'newStock': currentStock - quantity,
        });
      }

      // =========================
      // 2. WRITE ALL DATA (အချက်အလက်အားလုံးကို နောက်မှ သိမ်းမည်)
      // =========================

      //Stock များကို လျှော့ချခြင်း (Update Product Stock)
      for (final update in stockUpdates) {
        final ref = update['ref'] as DocumentReference<Map<String, dynamic>>;
        final newStock = update['newStock'] as int;

        transaction.update(ref, {'stock': newStock});
      }

      //Sale Data ကို သိမ်းဆည်းခြင်း (Create Sale Document)
      transaction.set(saleRef, {
        'invoiceNo': invoiceNo,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'paymentMethod': paymentMethod,
        'items': items,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
