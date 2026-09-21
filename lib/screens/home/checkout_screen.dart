import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
      final invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      final items = cart.items.map((item) {
        return {
          'productId': item.product.id,
          'name': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
          'total': item.total,
        };
      }).toList();

      final totalAmount = cart.total;

      await SaleService().createSale(
        uid: user.uid,
        invoiceNo: invoiceNo,
        subtotal: cart.subtotal,
        discount: cart.discount,
        total: totalAmount,
        paymentMethod: paymentMethod,
        items: items,
      );

      cart.clearCart();

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Sale Completed'),
            content: Text(
              'Invoice: $invoiceNo\n'
              'Total: ${totalAmount.toStringAsFixed(0)} MMK',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
