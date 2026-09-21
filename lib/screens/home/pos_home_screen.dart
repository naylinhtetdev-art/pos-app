import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pos_app/models/product_model.dart';
import 'package:pos_app/models/user_model.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/providers/product_provider.dart';
import 'package:pos_app/screens/home/cart_icon_button_widget.dart';
import 'package:pos_app/screens/home/checkout_screen.dart';
import 'package:pos_app/screens/home/floating_checkout_bar_widget.dart';
import 'package:pos_app/screens/products/product_list_screen.dart';
import 'package:pos_app/screens/sale/sale_history_screen.dart';
import 'package:pos_app/services/profile_service.dart';
import 'package:pos_app/services/sale_service.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class PosHomeScreen extends StatefulWidget {
  const PosHomeScreen({super.key});

  @override
  State<PosHomeScreen> createState() => _PosHomeScreenState();
}

class _PosHomeScreenState extends State<PosHomeScreen> {
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  final TextEditingController _searchController = TextEditingController();

  UserModel? _profile;
  bool _isLoading = true;
  String _selectedSummaryFilter = 'Today';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<ProductProvider>().start(user.uid);
      }
    });
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final profile = await _profileService.getProfile(user.uid);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Profile error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    //final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text(
          _profile?.shopName ?? 'POS Home',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [CartIconButtonWidget()],
        //actions: [_buildCartIconButton(cartProvider)],
      ),
      drawer: _buildDrawer(context),
      // Bottom Bar ကို Selector သုံးပြီး Cart Quantity ပြောင်းမှပဲ Rebuild ဖြစ်အောင် လုပ်မည်
      bottomNavigationBar: Selector<CartProvider, int>(
        selector: (_, cart) => cart.totalQuantity,
        builder: (context, totalQuantity, child) {
          if (totalQuantity == 0) return const SizedBox.shrink();

          // Quantity > 0 မှသာ အောက်ခြေ ဘားတန်း ပေါ်မည်
          return const FloatingCheckoutBarWidget();
        },
      ),

      // Cart ထဲတွင် ပစ္စည်းရှိပါက အောက်ခြေ၌ တန်းပေါ်လာမည့် Floating Checkout Bar
      // bottomNavigationBar: cartProvider.totalQuantity > 0
      //     ? Container(
      //         padding: const EdgeInsets.all(16),
      //         decoration: BoxDecoration(
      //           color: Colors.white,
      //           boxShadow: [
      //             BoxShadow(
      //               color: Colors.black.withValues(alpha: 0.08),
      //               blurRadius: 10,
      //               offset: const Offset(0, -4),
      //             ),
      //           ],
      //         ),
      //         child: ElevatedButton(
      //           style: ElevatedButton.styleFrom(
      //             backgroundColor: Theme.of(context).primaryColor,
      //             padding: const EdgeInsets.symmetric(vertical: 14),
      //             shape: RoundedRectangleBorder(
      //               borderRadius: BorderRadius.circular(12),
      //             ),
      //           ),
      //           onPressed: () {
      //             Navigator.push(
      //               context,
      //               MaterialPageRoute(builder: (_) => const CheckoutScreen()),
      //             );
      //           },
      //           child: Row(
      //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //             children: [
      //               Padding(
      //                 padding: const EdgeInsets.only(left: 12),
      //                 child: Text(
      //                   '${cartProvider.totalQuantity} Items | ${cartProvider.total.toStringAsFixed(0)} MMK',
      //                   style: const TextStyle(
      //                     fontSize: 15,
      //                     fontWeight: FontWeight.bold,
      //                     color: Colors.white,
      //                   ),
      //                 ),
      //               ),
      //               const Padding(
      //                 padding: EdgeInsets.only(right: 12),
      //                 child: Row(
      //                   children: [
      //                     Text(
      //                       'Checkout',
      //                       style: TextStyle(
      //                         fontSize: 15,
      //                         fontWeight: FontWeight.bold,
      //                         color: Colors.white,
      //                       ),
      //                     ),
      //                     SizedBox(width: 4),
      //                     Icon(
      //                       Icons.arrow_forward_rounded,
      //                       size: 18,
      //                       color: Colors.white,
      //                     ),
      //                   ],
      //                 ),
      //               ),
      //             ],
      //           ),
      //         ),
      //       )
      //     : null,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummary(),
                      const SizedBox(height: 16),
                      _buildSearch(productProvider),
                      const SizedBox(height: 16),
                      _buildCategories(productProvider),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${productProvider.filteredProducts.length} Items',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildProductGrid(productProvider),
          ),
        ),
      ),
    );
  }

  // =========================
  // APP BAR CART BUTTON
  // =========================

  Widget _buildCartIconButton(CartProvider cart) {
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
        if (cart.totalQuantity > 0)
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
                '${cart.totalQuantity}',
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
  }

  // =========================
  // SUMMARY SECTION
  // =========================

  Widget _buildSummary() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SaleService().salesStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSummaryCardContainer(
            salesText: 'Loading...',
            ordersText: 'Loading...',
          );
        }

        if (snapshot.hasError) {
          return _buildSummaryCardContainer(
            salesText: '0 MMK',
            ordersText: '0',
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final now = DateTime.now();

        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          final timestamp = data['createdAt'] as Timestamp?;
          if (timestamp == null) return false;

          final date = timestamp.toDate();

          if (_selectedSummaryFilter == 'Today') {
            return date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
          } else if (_selectedSummaryFilter == 'Yesterday') {
            final yesterday = now.subtract(const Duration(days: 1));
            return date.year == yesterday.year &&
                date.month == yesterday.month &&
                date.day == yesterday.day;
          } else if (_selectedSummaryFilter == 'This Week') {
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final startOfDay = DateTime(
              startOfWeek.year,
              startOfWeek.month,
              startOfWeek.day,
            );
            return date.isAfter(startOfDay) ||
                date.isAtSameMomentAs(startOfDay);
          }
          return true;
        }).toList();

        double totalSales = 0;
        for (final doc in filteredDocs) {
          totalSales += (doc.data()['total'] ?? 0).toDouble();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sales Overview',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: _selectedSummaryFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Today', child: Text('Today')),
                      DropdownMenuItem(
                        value: 'Yesterday',
                        child: Text('Yesterday'),
                      ),
                      DropdownMenuItem(
                        value: 'This Week',
                        child: Text('This Week'),
                      ),
                      DropdownMenuItem(
                        value: 'All Sales',
                        child: Text('All Sales'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedSummaryFilter = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildSummaryCardContainer(
                salesTitle: 'Sales ($_selectedSummaryFilter)',
                salesText: '${totalSales.toStringAsFixed(0)} MMK',
                ordersText: '${filteredDocs.length}',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCardContainer({
    String salesTitle = 'Total Sales',
    required String salesText,
    required String ordersText,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: salesTitle,
            value: salesText,
            icon: Icons.payments_outlined,
            color: Colors.blue.shade50,
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            title: 'Orders',
            value: ordersText,
            icon: Icons.receipt_long_outlined,
            color: Colors.orange.shade50,
            iconColor: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // =========================
  // SEARCH
  // =========================

  Widget _buildSearch(ProductProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        provider.search(value);
      },
      decoration: InputDecoration(
        hintText: 'Search product...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  // =========================
  // CATEGORIES
  // =========================

  Widget _buildCategories(ProductProvider provider) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: provider.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = provider.categories[index];
          final selected = provider.selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: selected,
            selectedColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (_) {
              provider.selectCategory(category);
            },
          );
        },
      ),
    );
  }

  // =========================
  // PRODUCT GRID
  // =========================

  Widget _buildProductGrid(ProductProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final products = provider.filteredProducts;

    if (products.isEmpty) {
      return const Center(
        child: Text('No products found', style: TextStyle(color: Colors.grey)),
      );
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return _productCard(product);
      },
    );
  }

  // =========================
  // PRODUCT CARD
  // =========================

  Widget _productCard(ProductModel product) {
    final isOutOfStock = product.stock <= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 40,
                    color: isOutOfStock ? Colors.grey : Colors.blue.shade700,
                  ),
                ),
                if (isOutOfStock)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '${product.price.toStringAsFixed(0)} MMK',
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Stock: ${product.stock}',
            style: TextStyle(
              fontSize: 11,
              color: isOutOfStock ? Colors.red : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isOutOfStock
                  ? null
                  : () {
                      //context.read<CartProvider>().addProduct(product);
                      // ✅ context.read ကို သုံးထားသည့်အတွက် Screen ကို Rebuild မလုပ်ပါ
                      final success = context.read<CartProvider>().addProduct(
                        product,
                      );

                      if (!success) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stock ထက် ပိုထည့်၍ မရပါ'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // DRAWER WIDGET
  // =========================

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.store, size: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile?.shopName ?? 'Shop Name',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _profile?.email ?? '',
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Trial Version',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.black87,
                  ),
                  title: Text(
                    _profile?.shopAddress.isNotEmpty == true
                        ? _profile!.shopAddress
                        : 'No Address Set',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.black87,
                  ),
                  title: const Text('Products Management'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductListScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.black87),
                  title: const Text('Sale History'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SaleHistoryScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.light_mode_outlined,
                    color: Colors.black87,
                  ),
                  title: const Text('Display Setting'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.language, color: Colors.black87),
                  title: const Text('Language'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.black87,
                  ),
                  title: const Text('Terms & Privacy'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () async {
                Navigator.pop(context);

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text(
                      'Are you sure you want to logout? All local cache will be cleared.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  if (!mounted) return;
                  context.read<CartProvider>().clearCart();
                  context.read<ProductProvider>().clearProducts();
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // App Version
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'POS for Android v1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:pos_app/models/product_model.dart';
// import 'package:pos_app/models/user_model.dart';
// import 'package:pos_app/providers/cart_provider.dart';
// import 'package:pos_app/providers/product_provider.dart';
// import 'package:pos_app/screens/home/checkout_screen.dart';
// import 'package:pos_app/screens/products/add_product_screen.dart';
// import 'package:pos_app/screens/products/product_list_screen.dart';
// import 'package:pos_app/screens/sale/sale_history_screen.dart';
// import 'package:pos_app/screens/splash/splash_screen.dart';
// import 'package:pos_app/services/profile_service.dart';
// import 'package:pos_app/services/sale_service.dart';
// import 'package:provider/provider.dart';

// import '../../services/auth_service.dart';
// import '../auth/login_screen.dart';

// class PosHomeScreen extends StatefulWidget {
//   const PosHomeScreen({super.key});

//   @override
//   State<PosHomeScreen> createState() => _PosHomeScreenState();
// }

// class _PosHomeScreenState extends State<PosHomeScreen> {
//   final AuthService _authService = AuthService();

//   final ProfileService _profileService = ProfileService();

//   UserModel? _profile;

//   bool _isLoading = true;
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final user = FirebaseAuth.instance.currentUser;

//       if (user != null) {
//         context.read<ProductProvider>().start(user.uid);
//       }
//     });
//     _loadProfile();
//   }

//   Future<void> _loadProfile() async {
//     final user = _authService.currentUser;

//     if (user == null) {
//       return;
//     }

//     try {
//       final profile = await _profileService.getProfile(user.uid);

//       if (!mounted) return;

//       setState(() {
//         _profile = profile;
//         _isLoading = false;
//       });
//     } catch (e) {
//       debugPrint('Profile error: $e');

//       if (!mounted) return;

//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _logout() async {
//     await _authService.logout();

//     if (!mounted) return;

//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//       (route) => false,
//     );
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();

//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final productProvider = context.watch<ProductProvider>();

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_profile?.shopName ?? 'POS Home'),
//         actions: [
//           Consumer<CartProvider>(
//             builder: (context, cart, child) {
//               return Stack(
//                 children: [
//                   IconButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const CheckoutScreen(),
//                         ),
//                       );
//                     },
//                     icon: const Icon(Icons.shopping_cart_outlined),
//                   ),

//                   if (cart.totalQuantity > 0)
//                     Positioned(
//                       right: 6,
//                       top: 6,
//                       child: Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: const BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Text(
//                           '${cart.totalQuantity}',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         width: MediaQuery.of(context).size.width * 0.8,
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView(
//                 padding: EdgeInsets.zero,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(16, 50, 16, 10),
//                     color: Colors.white,
//                     child: Row(
//                       children: [
//                         CircleAvatar(
//                           radius: 35,
//                           child: Icon(Icons.store, size: 40),
//                         ),
//                         SizedBox(width: 10),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               SizedBox(height: 10),
//                               Text(
//                                 _profile?.shopName ?? 'Shop Name',
//                                 style: TextStyle(
//                                   color: Colors.blue,
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               SizedBox(height: 3),
//                               Text(
//                                 _profile?.email ?? '',
//                                 style: TextStyle(
//                                   color: Colors.black,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                               SizedBox(height: 0),
//                               Text(
//                                 'Trial',
//                                 style: TextStyle(
//                                   color: Colors.amber,
//                                   fontSize: 12,
//                                 ),
//                               ),
//                               SizedBox(height: 6),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.person_outline, color: Colors.black),
//                     title: Text(
//                       'Profile',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     onTap: () => Navigator.pop(context),
//                   ),
//                   ListTile(
//                     leading: Icon(Icons.location_on_sharp, color: Colors.black),
//                     title: Text(
//                       //'Following',
//                       _profile?.shopAddress ?? '',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     onTap: () {},
//                   ),
//                   ListTile(
//                     leading: const Icon(
//                       Icons.inventory_2_outlined,
//                       color: Colors.black,
//                     ),
//                     title: const Text(
//                       'Products Management',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     onTap: () {
//                       Navigator.pop(context); // Drawer ပိတ်မည်
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const ProductListScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   // ListTile(
//                   //   leading: const Icon(
//                   //     Icons.inventory_2_outlined,
//                   //     color: Colors.black,
//                   //   ),
//                   //   title: const Text(
//                   //     'Add Product',
//                   //     style: TextStyle(color: Colors.black),
//                   //   ),
//                   //   onTap: () {
//                   //     Navigator.pop(context); // Drawer ပိတ်မည်
//                   //     Navigator.push(
//                   //       context,
//                   //       MaterialPageRoute(
//                   //         builder: (_) => const AddProductScreen(),
//                   //       ),
//                   //     );
//                   //   },
//                   // ),
//                   ListTile(
//                     leading: const Icon(Icons.history, color: Colors.black),
//                     title: const Text(
//                       'Sale History',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     onTap: () {
//                       Navigator.pop(context); // Drawer ကို အရင်ပိတ်မည်
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (_) => const SaleHistoryScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   ListTile(
//                     leading: const Icon(
//                       Icons.light_mode_outlined,
//                       color: Colors.black,
//                     ),
//                     title: const Text(
//                       'Displat Setting',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     onTap: () {
//                       Navigator.pop(context);
//                     },
//                   ),
//                   ListTile(
//                     leading: const Icon(Icons.language, color: Colors.black),
//                     title: const Text(
//                       'Languange',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     onTap: () {
//                       Navigator.pop(context);
//                     },
//                   ),
//                   ListTile(
//                     leading: const Icon(
//                       Icons.privacy_tip_outlined,
//                       color: Colors.black,
//                     ),
//                     title: const Text(
//                       'Terms & Privacy',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     onTap: () {
//                       Navigator.pop(context);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(16),
//               child: InkWell(
//                 onTap: () async {
//                   Navigator.pop(context); // Drawer ပိတ်မည်

//                   final confirm = await showDialog<bool>(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: const Text('Logout'),
//                       content: const Text(
//                         'Are you sure you want to logout? All local cache will be cleared.',
//                       ),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context, false),
//                           child: const Text('Cancel'),
//                         ),
//                         TextButton(
//                           onPressed: () => Navigator.pop(context, true),
//                           child: const Text(
//                             'Logout',
//                             style: TextStyle(color: Colors.red),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );

//                   if (confirm == true) {
//                     if (!mounted) return;

//                     // 1. Providers Cache များ ရှင်းထုတ်ခြင်း
//                     context.read<CartProvider>().clearCart();
//                     context.read<ProductProvider>().clearProducts();

//                     // 2. Firebase Session Logout ပြုလုပ်ခြင်း
//                     await FirebaseAuth.instance.signOut();

//                     if (!mounted) return;

//                     // 3. LoginScreen သို့ ရွှေ့ပြီး Stack များကို ရှင်းထုတ်ခြင်း
//                     Navigator.pushAndRemoveUntil(
//                       context,
//                       MaterialPageRoute(builder: (_) => const LoginScreen()),
//                       (route) => false,
//                     );
//                   }
//                 },
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(vertical: 14),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade600,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.logout_rounded,
//                         color: Colors.redAccent,
//                         size: 20,
//                       ),
//                       SizedBox(width: 8),
//                       Text(
//                         'Logout',
//                         style: TextStyle(
//                           color: Colors.redAccent,
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(2),
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(vertical: 10),
//                   // decoration: BoxDecoration(
//                   //   color: Colors.grey.shade600,
//                   //   borderRadius: BorderRadius.circular(12),
//                   // ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       // Icon(
//                       //   Icons.logout_rounded,
//                       //   color: Colors.redAccent,
//                       //   size: 20,
//                       // ),
//                       // SizedBox(width: 8),
//                       Text(
//                         'POS for Android v1.0.0',
//                         style: TextStyle(
//                           color: Colors.black,
//                           fontSize: 15,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),

//       // body: SafeArea(
//       //   child: Padding(
//       //     padding: const EdgeInsets.all(16),

//       //     child: Column(
//       //       crossAxisAlignment: CrossAxisAlignment.start,

//       //       children: [
//       //         _buildSummary(),

//       //         const SizedBox(height: 20),

//       //         _buildSearch(productProvider),

//       //         const SizedBox(height: 16),

//       //         _buildCategories(productProvider),

//       //         const SizedBox(height: 16),

//       //         const Text(
//       //           'Products',
//       //           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//       //         ),

//       //         const SizedBox(height: 12),

//       //         Expanded(child: _buildProductGrid(productProvider)),
//       //       ],
//       //     ),
//       //   ),
//       // ),
//       body: SafeArea(
//         child: NestedScrollView(
//           headerSliverBuilder: (context, innerBoxIsScrolled) {
//             return [
//               SliverToBoxAdapter(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // 1. Scroll ဆွဲလျှင် ပျောက်သွားမည့် Summary Card
//                       _buildSummary(),

//                       const SizedBox(height: 20),

//                       // 2. Search Box
//                       _buildSearch(productProvider),

//                       const SizedBox(height: 16),

//                       // 3. Category Chips
//                       _buildCategories(productProvider),

//                       const SizedBox(height: 16),

//                       const Text(
//                         'Products',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ];
//           },
//           body: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: _buildProductGrid(productProvider),
//           ),
//         ),
//       ),
//     );
//   }

//   // 1. State Class ၏ အပေါ်ပိုင်းတွင် Variable တစ်ခု ကြေညာပေးပါ
//   String _selectedSummaryFilter = 'Today'; // Default အဖြစ် 'Today' ကို ထားမည်

//   Widget _buildSummary() {
//     final user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       return const SizedBox();
//     }

//     return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//       stream: SaleService().salesStream(user.uid),
//       builder: (context, snapshot) {
//         // Loading State
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return _buildSummaryCardContainer(
//             salesText: 'Loading...',
//             ordersText: 'Loading...',
//           );
//         }

//         // Error State
//         if (snapshot.hasError) {
//           return _buildSummaryCardContainer(
//             salesText: '0 MMK',
//             ordersText: '0',
//           );
//         }

//         final docs = snapshot.data?.docs ?? [];
//         final now = DateTime.now();

//         // Today, Yesterday, This Week စသည်ဖြင့် Filter စစ်ထုတ်ခြင်း
//         final filteredDocs = docs.where((doc) {
//           final data = doc.data();
//           final timestamp = data['createdAt'] as Timestamp?;
//           if (timestamp == null) return false;

//           final date = timestamp.toDate();

//           if (_selectedSummaryFilter == 'Today') {
//             return date.year == now.year &&
//                 date.month == now.month &&
//                 date.day == now.day;
//           } else if (_selectedSummaryFilter == 'Yesterday') {
//             final yesterday = now.subtract(const Duration(days: 1));
//             return date.year == yesterday.year &&
//                 date.month == yesterday.month &&
//                 date.day == yesterday.day;
//           } else if (_selectedSummaryFilter == 'This Week') {
//             // ယခုအပတ် (Monday မှ စတင်တွက်ချက်ခြင်း)
//             final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
//             final startOfDay = DateTime(
//               startOfWeek.year,
//               startOfWeek.month,
//               startOfWeek.day,
//             );
//             return date.isAfter(startOfDay) ||
//                 date.isAtSameMomentAs(startOfDay);
//           }

//           // 'All Sales' သို့မဟုတ် အခြား Filter မရှိပါက အားလုံးကို ပြမည်
//           return true;
//         }).toList();

//         // စုစုပေါင်း ရောင်းရငွေ နှင့် Order အရေအတွက် တွက်ချက်ခြင်း
//         double totalSales = 0;
//         for (final doc in filteredDocs) {
//           final data = doc.data();
//           totalSales += (data['total'] ?? 0).toDouble();
//         }

//         final orders = filteredDocs.length;

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Filter ရွေးချယ်ရန် Dropdown & Title
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Summary',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 DropdownButton<String>(
//                   value: _selectedSummaryFilter,
//                   underline: const SizedBox(), // Dropdown အောက်လိုင်း ဖျောက်ရန်
//                   items: const [
//                     DropdownMenuItem(value: 'Today', child: Text('Today')),
//                     DropdownMenuItem(
//                       value: 'Yesterday',
//                       child: Text('Yesterday'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'This Week',
//                       child: Text('This Week'),
//                     ),
//                     DropdownMenuItem(
//                       value: 'All Sales',
//                       child: Text('All Sales'),
//                     ),
//                   ],
//                   onChanged: (value) {
//                     if (value != null) {
//                       setState(() {
//                         _selectedSummaryFilter = value;
//                       });
//                     }
//                   },
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),

//             // Summary Cards ပြသသည့်နေရာ
//             _buildSummaryCardContainer(
//               salesTitle: 'Sales ($_selectedSummaryFilter)',
//               salesText: '${totalSales.toStringAsFixed(0)} MMK',
//               ordersText: '$orders',
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // Summary Card UI အတွက် Helper Widget
//   Widget _buildSummaryCardContainer({
//     String salesTitle = 'Total Sales',
//     required String salesText,
//     required String ordersText,
//   }) {
//     return Row(
//       children: [
//         Expanded(
//           child: _summaryCard(
//             title: salesTitle,
//             value: salesText,
//             icon: Icons.payments_outlined,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _summaryCard(
//             title: 'Orders',
//             value: ordersText,
//             icon: Icons.receipt_long_outlined,
//           ),
//         ),
//       ],
//     );
//   }
//   // Widget _buildSummary() {
//   //   final user = FirebaseAuth.instance.currentUser;

//   //   // if (user == null) {
//   //   //   return const SizedBox();
//   //   // }

//   //   return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//   //     stream: SaleService().salesStream(user!.uid),
//   //     builder: (context, snapshot) {
//   //       // Loading
//   //       if (snapshot.connectionState == ConnectionState.waiting) {
//   //         return Row(
//   //           children: [
//   //             Expanded(
//   //               child: _summaryCard(
//   //                 title: 'Today Sales',
//   //                 value: 'Loading...',
//   //                 icon: Icons.payments_outlined,
//   //               ),
//   //             ),
//   //             const SizedBox(width: 12),
//   //             Expanded(
//   //               child: _summaryCard(
//   //                 title: 'Orders',
//   //                 value: 'Loading...',
//   //                 icon: Icons.receipt_long_outlined,
//   //               ),
//   //             ),
//   //           ],
//   //         );
//   //       }

//   //       // Error
//   //       if (snapshot.hasError) {
//   //         return Row(
//   //           children: [
//   //             Expanded(
//   //               child: _summaryCard(
//   //                 title: 'Today Sales',
//   //                 value: '0 MMK',
//   //                 icon: Icons.payments_outlined,
//   //               ),
//   //             ),
//   //             const SizedBox(width: 12),
//   //             Expanded(
//   //               child: _summaryCard(
//   //                 title: 'Orders',
//   //                 value: '0',
//   //                 icon: Icons.receipt_long_outlined,
//   //               ),
//   //             ),
//   //           ],
//   //         );
//   //       }

//   //       // Firestore documents
//   //       final docs = snapshot.data?.docs ?? [];

//   //       double totalSales = 0;

//   //       for (final doc in docs) {
//   //         final data = doc.data();

//   //         totalSales += (data['total'] ?? 0).toDouble();
//   //       }

//   //       final orders = docs.length;

//   //       // UI
//   //       return Row(
//   //         children: [
//   //           Expanded(
//   //             child: _summaryCard(
//   //               title: 'Total Sales',
//   //               value: '${totalSales.toStringAsFixed(0)} MMK',
//   //               icon: Icons.payments_outlined,
//   //             ),
//   //           ),

//   //           const SizedBox(width: 12),

//   //           Expanded(
//   //             child: _summaryCard(
//   //               title: 'Orders',
//   //               value: '$orders',
//   //               icon: Icons.receipt_long_outlined,
//   //             ),
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }

//   Widget _summaryCard({
//     required String title,
//     required String value,
//     required IconData icon,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(16),

//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),

//         border: Border.all(color: Colors.grey.shade300),
//       ),

//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,

//         children: [
//           Icon(icon),

//           const SizedBox(height: 10),

//           Text(title, style: const TextStyle(color: Colors.grey)),

//           const SizedBox(height: 4),

//           Text(
//             value,
//             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================
//   // SEARCH
//   // =========================

//   Widget _buildSearch(ProductProvider provider) {
//     return TextField(
//       controller: _searchController,

//       onChanged: (value) {
//         provider.search(value);
//       },

//       decoration: InputDecoration(
//         hintText: 'Search product...',

//         prefixIcon: const Icon(Icons.search),

//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   // =========================
//   // CATEGORY
//   // =========================

//   Widget _buildCategories(ProductProvider provider) {
//     return SizedBox(
//       height: 42,

//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,

//         itemCount: provider.categories.length,

//         separatorBuilder: (_, _) => const SizedBox(width: 8),

//         itemBuilder: (context, index) {
//           final category = provider.categories[index];

//           final selected = provider.selectedCategory == category;

//           return ChoiceChip(
//             label: Text(category),

//             selected: selected,

//             onSelected: (_) {
//               provider.selectCategory(category);
//             },
//           );
//         },
//       ),
//     );
//   }

//   // =========================
//   // PRODUCT GRID
//   // =========================

//   Widget _buildProductGrid(ProductProvider provider) {
//     if (provider.isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     final products = provider.filteredProducts;

//     if (products.isEmpty) {
//       return const Center(child: Text('No products found'));
//     }

//     return GridView.builder(
//       physics: const BouncingScrollPhysics(),
//       padding: const EdgeInsets.only(bottom: 16),
//       itemCount: products.length,

//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 12,
//         mainAxisSpacing: 12,
//         childAspectRatio: 0.78,
//       ),

//       itemBuilder: (context, index) {
//         final product = products[index];

//         return _productCard(product);
//       },
//     );
//   }

//   // =========================
//   // PRODUCT CARD
//   // =========================

//   Widget _productCard(ProductModel product) {
//     return Container(
//       padding: const EdgeInsets.all(12),

//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),

//         border: Border.all(color: Colors.grey.shade300),
//       ),

//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,

//         children: [
//           Expanded(
//             child: Container(
//               width: double.infinity,

//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,

//                 borderRadius: BorderRadius.circular(12),
//               ),

//               child: const Icon(Icons.shopping_bag_outlined, size: 40),
//             ),
//           ),

//           const SizedBox(height: 10),

//           Text(
//             product.name,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,

//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),

//           const SizedBox(height: 4),

//           Text('${product.price.toStringAsFixed(0)} MMK'),

//           const SizedBox(height: 8),

//           SizedBox(
//             width: double.infinity,

//             child: ElevatedButton(
//               // onPressed: () {
//               //   // Cart ထဲထည့်မယ်
//               //   context.read<CartProvider>().addProduct(product);
//               // },
//               onPressed: product.stock <= 0
//                   ? null
//                   : () {
//                       context.read<CartProvider>().addProduct(product);
//                     },
//               child: const Text('Add'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
