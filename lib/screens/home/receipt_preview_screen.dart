import 'package:flutter/material.dart';

import '../../models/receipt_model.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final ReceiptModel receipt;

  const ReceiptPreviewScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            onPressed: () {
              // Print later
            },
            icon: const Icon(Icons.print),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SHOP NAME
                Text(
                  receipt.shopName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Thank you for shopping with us',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                const Divider(),

                // INVOICE
                Text('Invoice: ${receipt.invoiceNo}'),

                Text('Date: ${receipt.date}'),

                const Divider(),

                // ITEMS
                ...receipt.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.name)),

                        Text(
                          '${item.quantity} × '
                          '${item.price.toStringAsFixed(0)}',
                        ),

                        const SizedBox(width: 12),

                        Text(item.total.toStringAsFixed(0)),
                      ],
                    ),
                  );
                }),

                const Divider(),

                // SUBTOTAL
                _summaryRow('Subtotal', receipt.subtotal),

                _summaryRow('Discount', receipt.discount),

                const Divider(),

                // TOTAL
                _summaryRow('TOTAL', receipt.total, isTotal: true),

                const SizedBox(height: 8),

                Text(
                  'Payment: ${receipt.paymentMethod}',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Thank You!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String title, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(0)} MMK',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
