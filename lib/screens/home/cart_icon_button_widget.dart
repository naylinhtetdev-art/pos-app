import 'package:flutter/material.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/screens/home/checkout_screen.dart';
import 'package:provider/provider.dart';

class CartIconButtonWidget extends StatelessWidget {
  const CartIconButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Selector သုံးပြီး totalQuantity ပြောင်းမှပဲ ဒီ Icon လေး Rebuild ဖြစ်မည်
    return Selector<CartProvider, int>(
      selector: (_, cart) => cart.totalQuantity,
      builder: (context, totalQuantity, child) {
        return Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
            if (totalQuantity > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$totalQuantity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
