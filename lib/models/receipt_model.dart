class ReceiptModel {
  final String shopName;
  final String invoiceNo;
  final DateTime date;
  final List<ReceiptItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;

  ReceiptModel({
    required this.shopName,
    required this.invoiceNo,
    required this.date,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
  });
}

class ReceiptItem {
  final String name;
  final double price;
  final int quantity;

  ReceiptItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total {
    return price * quantity;
  }
}
