import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pos_app/models/receipt_model.dart';
import 'package:pos_app/services/sale_service.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return const Center(
              child: Text('Cart is empty', style: TextStyle(fontSize: 18)),
            );
          }

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return _cartItem(context, cart, item);
                      },
                    ),
                  ),
                  _buildBottomSummary(context, cart),
                ],
              ),
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // CART ITEM
  // =========================

  Widget _cartItem(BuildContext context, CartProvider cart, dynamic item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${item.product.price.toStringAsFixed(0)} MMK'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        cart.decreaseQuantity(item.product.id);
                      },
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        cart.increaseQuantity(item.product.id);
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.total.toStringAsFixed(0)} MMK',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  cart.removeProduct(item.product.id);
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // SUMMARY
  // =========================

  Widget _buildBottomSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Items', '${cart.totalQuantity}'),
          const SizedBox(height: 8),
          _summaryRow('Subtotal', '${cart.subtotal.toStringAsFixed(0)} MMK'),
          const SizedBox(height: 8),
          _summaryRow('Discount', '${cart.discount.toStringAsFixed(0)} MMK'),
          const Divider(height: 24),
          _summaryRow(
            'TOTAL',
            '${cart.total.toStringAsFixed(0)} MMK',
            isTotal: true,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      _showPaymentDialog(context, cart);
                    },
              child: const Text(
                'CHECKOUT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String title, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 18 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================
  // PAYMENT
  // =========================

  void _showPaymentDialog(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: ${cart.total.toStringAsFixed(0)} MMK',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.money),
                title: const Text('Cash'),
                onTap: () {
                  Navigator.pop(context);
                  _completeSale('Cash');
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('Mobile Pay'),
                onTap: () {
                  Navigator.pop(context);
                  _completeSale('Mobile Pay');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // COMPLETE SALE
  // =========================

  // Future<void> _completeSale(String paymentMethod) async {
  //   final user = FirebaseAuth.instance.currentUser;

  //   if (user == null) {
  //     return;
  //   }

  //   final cart = context.read<CartProvider>();

  //   if (cart.items.isEmpty) {
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   try {
  //     final invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch}';

  //     final items = cart.items.map((item) {
  //       return {
  //         'productId': item.product.id,
  //         'name': item.product.name,
  //         'price': item.product.price,
  //         'quantity': item.quantity,
  //         'total': item.total,
  //       };
  //     }).toList();

  //     final totalAmount = cart.total;

  //     await SaleService().createSale(
  //       uid: user.uid,
  //       invoiceNo: invoiceNo,
  //       subtotal: cart.subtotal,
  //       discount: cart.discount,
  //       total: totalAmount,
  //       paymentMethod: paymentMethod,
  //       items: items,
  //     );

  //     cart.clearCart();

  //     if (!mounted) return;

  //     await showDialog(
  //       context: context,
  //       builder: (_) {
  //         return AlertDialog(
  //           title: const Text('Sale Completed'),
  //           content: Text(
  //             'Invoice: $invoiceNo\n'
  //             'Total: ${totalAmount.toStringAsFixed(0)} MMK',
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.pop(context);
  //               },
  //               child: const Text('OK'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     if (!mounted) return;

  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text(e.toString())));
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }
  Future<void> _completeSale(String paymentMethod) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final cart = context.read<CartProvider>();

    if (cart.items.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // =====================================
      // 1. SAVE CART DATA BEFORE CLEAR
      // =====================================

      final subtotal = cart.subtotal;

      final discount = cart.discount;

      final totalAmount = cart.total;

      // =====================================
      // 2. CREATE INVOICE NUMBER
      // =====================================

      final invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      // =====================================
      // 3. CREATE SALE ITEMS
      // =====================================

      final items = cart.items.map((item) {
        return {
          'productId': item.product.id,
          'name': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
          'total': item.total,
        };
      }).toList();

      // =====================================
      // 4. CREATE RECEIPT ITEMS
      // =====================================

      final receiptItems = cart.items.map((item) {
        return ReceiptItem(
          name: item.product.name,
          price: item.product.price,
          quantity: item.quantity,
        );
      }).toList();

      // =====================================
      // 5. SAVE SALE + REDUCE STOCK
      // =====================================

      await SaleService().createSale(
        uid: user.uid,
        invoiceNo: invoiceNo,
        subtotal: subtotal,
        discount: discount,
        total: totalAmount,
        paymentMethod: paymentMethod,
        items: items,
      );

      // =====================================
      // 6. CREATE RECEIPT MODEL
      // =====================================

      final receipt = ReceiptModel(
        shopName: 'Shop Name',
        invoiceNo: invoiceNo,
        date: DateTime.now(),
        items: receiptItems,
        subtotal: subtotal,
        discount: discount,
        total: totalAmount,
        paymentMethod: paymentMethod,
      );

      // =====================================
      // 7. CLEAR CART
      // =====================================

      cart.clearCart();

      if (!mounted) {
        return;
      }

      // =====================================
      // 8. STOP LOADING
      // =====================================

      setState(() {
        _isLoading = false;
      });

      // =====================================
      // 9. SHOW RECEIPT PREVIEW
      // =====================================

      _showReceiptPreview(context, receipt);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sale failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showReceiptPreview(BuildContext context, ReceiptModel receipt) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 700),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // =========================
                  // HEADER
                  // =========================
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Receipt Preview',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // =========================
                  // RECEIPT
                  // =========================
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
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
                              style: TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 12),

                            const Divider(),

                            // INVOICE
                            Text('Invoice: ${receipt.invoiceNo}'),

                            const SizedBox(height: 4),

                            Text('Date: ${_formatDate(receipt.date)}'),

                            const Divider(),

                            const SizedBox(height: 5),

                            // ITEM HEADER
                            Row(
                              children: const [
                                Expanded(
                                  child: Text(
                                    'Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  width: 95,
                                  child: Text(
                                    'Qty × Price',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                SizedBox(
                                  width: 65,
                                  child: Text(
                                    'Total',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // ITEMS
                            ...receipt.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(item.name)),

                                    SizedBox(
                                      width: 95,
                                      child: Text(
                                        '${item.quantity} × '
                                        '${item.price.toStringAsFixed(0)}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    SizedBox(
                                      width: 65,
                                      child: Text(
                                        item.total.toStringAsFixed(0),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const Divider(),

                            // SUBTOTAL
                            _receiptSummaryRow('Subtotal', receipt.subtotal),

                            // DISCOUNT
                            _receiptSummaryRow('Discount', receipt.discount),

                            const Divider(),

                            // TOTAL
                            _receiptSummaryRow(
                              'TOTAL',
                              receipt.total,
                              isTotal: true,
                            ),

                            const SizedBox(height: 12),

                            // PAYMENT
                            Text(
                              'Payment: ${receipt.paymentMethod}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 18),

                            const Text(
                              'Thank You!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =========================
                  // PRINT
                  // =========================
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Printer will be added here
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Print Receipt'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =========================
                  // CLOSE
                  // =========================
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _receiptSummaryRow(
    String title,
    double value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          Text(
            '${value.toStringAsFixed(0)} MMK',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');

    final month = date.month.toString().padLeft(2, '0');

    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
