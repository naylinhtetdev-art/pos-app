import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String invoiceNo;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final List<Map<String, dynamic>> items;
  final DateTime? createdAt;

  SaleModel({
    required this.id,
    required this.invoiceNo,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.items,
    this.createdAt,
  });

  factory SaleModel.fromFirestore(String id, Map<String, dynamic> data) {
    final createdAtData = data['createdAt'];

    return SaleModel(
      id: id,
      invoiceNo: data['invoiceNo'] ?? '',
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      items: List<Map<String, dynamic>>.from(data['items'] ?? []),
      createdAt: createdAtData is Timestamp ? createdAtData.toDate() : null,
    );
  }
}
