import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';
import '../theme.dart';
import '../main.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => notifier.clear(),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: cart.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 60),
                SizedBox(height: 16),
                Text('Your cart is empty', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.length,
                  itemBuilder: (ctx, i) {
                    final item = cart[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dark600),
                        color: AppTheme.dark800,
                      ),
                      child: Row(
                        children: [
                          if (item.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: '$kApiBase${item.imageUrl}',
                                width: 60, height: 60, fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: AppTheme.dark700,
                              ),
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w600)),
                                Text('\$${item.priceUsd}', style: const TextStyle(
                                  color: AppTheme.brand, fontSize: 13)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              _QtyBtn(icon: Icons.remove, onTap: () => notifier.decrement(item.id)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('${item.qty}', style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                              _QtyBtn(icon: Icons.add, onTap: () => notifier.increment(item.id)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.dark800,
                  border: Border(top: BorderSide(color: AppTheme.dark600)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(color: Colors.grey)),
                        Text('\$${notifier.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.brand, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _checkout(context, notifier.total),
                        child: const Text('Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  void _checkout(BuildContext context, double total) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dark800,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Payment Method',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _PayOption(
              icon: '💳',
              label: 'PayPal',
              subtitle: 'International — USD',
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('$kApiBase/shop/cart/'),
                    mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 12),
            _PayOption(
              icon: '📱',
              label: 'Mobile Money',
              subtitle: 'Airtel Money / TNM Mpamba — MWK',
              onTap: () {
                Navigator.pop(context);
                launchUrl(Uri.parse('$kApiBase/orders/paychangu/'),
                    mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.dark600),
          color: AppTheme.dark700,
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String icon, label, subtitle;
  final VoidCallback onTap;
  const _PayOption({required this.icon, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dark600),
          color: AppTheme.dark700,
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
