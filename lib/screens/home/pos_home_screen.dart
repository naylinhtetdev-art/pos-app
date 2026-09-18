import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pos_app/models/product_model.dart';
import 'package:pos_app/models/user_model.dart';
import 'package:pos_app/providers/cart_provider.dart';
import 'package:pos_app/providers/product_provider.dart';
import 'package:pos_app/screens/home/checkout_screen.dart';
import 'package:pos_app/screens/products/add_product_screen.dart';
import 'package:pos_app/screens/products/product_list_screen.dart';
import 'package:pos_app/screens/sale/sale_history_screen.dart';
import 'package:pos_app/screens/splash/splash_screen.dart';
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

  UserModel? _profile;

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

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

    if (user == null) {
      return;
    }

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

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_profile?.shopName ?? 'POS Home'),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckoutScreen(),
                        ),
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
            },
          ),
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 10),
                    color: Colors.white,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          child: Icon(Icons.store, size: 40),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),
                              Text(
                                _profile?.shopName ?? 'Shop Name',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                _profile?.email ?? '',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 0),
                              Text(
                                'Trial',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.person_outline, color: Colors.black),
                    title: Text(
                      'Profile',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: Icon(Icons.location_on_sharp, color: Colors.black),
                    title: Text(
                      //'Following',
                      _profile?.shopAddress ?? '',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.black,
                    ),
                    title: const Text(
                      'Products',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Drawer ပိတ်မည်
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(),
                        ),
                      );
                    },
                  ),
                  // ListTile(
                  //   leading: const Icon(
                  //     Icons.inventory_2_outlined,
                  //     color: Colors.black,
                  //   ),
                  //   title: const Text(
                  //     'Add Product',
                  //     style: TextStyle(color: Colors.black),
                  //   ),
                  //   onTap: () {
                  //     Navigator.pop(context); // Drawer ပိတ်မည်
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (_) => const AddProductScreen(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.black),
                    title: const Text(
                      'Sale History',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.pop(context); // Drawer ကို အရင်ပိတ်မည်
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
                      color: Colors.black,
                    ),
                    title: const Text(
                      'Displat Setting',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.black),
                    title: const Text(
                      'Languange',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.privacy_tip_outlined,
                      color: Colors.black,
                    ),
                    title: const Text(
                      'Terms & Privacy',
                      style: TextStyle(color: Colors.black),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: InkWell(
                onTap: () async {
                  Navigator.pop(context); // Drawer ပိတ်မည်

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

                    // 1. Providers Cache များ ရှင်းထုတ်ခြင်း
                    context.read<CartProvider>().clearCart();
                    context.read<ProductProvider>().clearProducts();

                    // 2. Firebase Session Logout ပြုလုပ်ခြင်း
                    await FirebaseAuth.instance.signOut();

                    if (!mounted) return;

                    // 3. LoginScreen သို့ ရွှေ့ပြီး Stack များကို ရှင်းထုတ်ခြင်း
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
                  padding: EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(2),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  // decoration: BoxDecoration(
                  //   color: Colors.grey.shade600,
                  //   borderRadius: BorderRadius.circular(12),
                  // ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon(
                      //   Icons.logout_rounded,
                      //   color: Colors.redAccent,
                      //   size: 20,
                      // ),
                      // SizedBox(width: 8),
                      Text(
                        'POS for Android v1.0.0',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // body: SafeArea(
      //   child: Padding(
      //     padding: const EdgeInsets.all(16),

      //     child: Column(
      //       crossAxisAlignment: CrossAxisAlignment.start,

      //       children: [
      //         _buildSummary(),

      //         const SizedBox(height: 20),

      //         _buildSearch(productProvider),

      //         const SizedBox(height: 16),

      //         _buildCategories(productProvider),

      //         const SizedBox(height: 16),

      //         const Text(
      //           'Products',
      //           style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      //         ),

      //         const SizedBox(height: 12),

      //         Expanded(child: _buildProductGrid(productProvider)),
      //       ],
      //     ),
      //   ),
      // ),
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
                      // 1. Scroll ဆွဲလျှင် ပျောက်သွားမည့် Summary Card
                      _buildSummary(),

                      const SizedBox(height: 20),

                      // 2. Search Box
                      _buildSearch(productProvider),

                      const SizedBox(height: 16),

                      // 3. Category Chips
                      _buildCategories(productProvider),

                      const SizedBox(height: 16),

                      const Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildSummary() {
    final user = FirebaseAuth.instance.currentUser;

    // if (user == null) {
    //   return const SizedBox();
    // }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: SaleService().salesStream(user!.uid),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              Expanded(
                child: _summaryCard(
                  title: 'Today Sales',
                  value: 'Loading...',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  title: 'Orders',
                  value: 'Loading...',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          );
        }

        // Error
        if (snapshot.hasError) {
          return Row(
            children: [
              Expanded(
                child: _summaryCard(
                  title: 'Today Sales',
                  value: '0 MMK',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _summaryCard(
                  title: 'Orders',
                  value: '0',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          );
        }

        // Firestore documents
        final docs = snapshot.data?.docs ?? [];

        double totalSales = 0;

        for (final doc in docs) {
          final data = doc.data();

          totalSales += (data['total'] ?? 0).toDouble();
        }

        final orders = docs.length;

        // UI
        return Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Total Sales',
                value: '${totalSales.toStringAsFixed(0)} MMK',
                icon: Icons.payments_outlined,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _summaryCard(
                title: 'Orders',
                value: '$orders',
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon),

          const SizedBox(height: 10),

          Text(title, style: const TextStyle(color: Colors.grey)),

          const SizedBox(height: 4),

          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // =========================
  // CATEGORY
  // =========================

  Widget _buildCategories(ProductProvider provider) {
    return SizedBox(
      height: 42,

      child: ListView.separated(
        scrollDirection: Axis.horizontal,

        itemCount: provider.categories.length,

        separatorBuilder: (_, __) => const SizedBox(width: 8),

        itemBuilder: (context, index) {
          final category = provider.categories[index];

          final selected = provider.selectedCategory == category;

          return ChoiceChip(
            label: Text(category),

            selected: selected,

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
      return const Center(child: Text('No products found'));
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: products.length,

      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
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
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Expanded(
            child: Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.grey.shade100,

                borderRadius: BorderRadius.circular(12),
              ),

              child: const Icon(Icons.shopping_bag_outlined, size: 40),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text('${product.price.toStringAsFixed(0)} MMK'),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              // onPressed: () {
              //   // Cart ထဲထည့်မယ်
              //   context.read<CartProvider>().addProduct(product);
              // },
              onPressed: product.stock <= 0
                  ? null
                  : () {
                      context.read<CartProvider>().addProduct(product);
                    },
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}
