import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/queries.dart';
import '../providers/cart_provider.dart';
import '../theme.dart';
import '../main.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).fold(0, (s, i) => s + i.qty);
    return Query(
      options: QueryOptions(document: gql(kGetShop)),
      builder: (result, {fetchMore, refetch}) {
        final products = (result.data?['products'] as List?) ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shop'),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.go('/cart'),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: AppTheme.brand),
                        child: Center(child: Text('$cartCount',
                          style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold))),
                      ),
                    ),
                ],
              ),
            ],
          ),
          body: result.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
            : products.isEmpty
              ? const Center(child: Text('No products yet', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: products.length,
                  itemBuilder: (ctx, i) {
                    final p = products[i];
                    final imgUrl = p['imageUrl'];
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dark600),
                        color: AppTheme.dark800,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: imgUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: '$kApiBase$imgUrl',
                                  height: 130, width: double.infinity, fit: BoxFit.cover,
                                )
                              : Container(height: 130, color: AppTheme.dark700,
                                  child: const Icon(Icons.image, color: Colors.grey)),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p['name'] ?? '', style: const TextStyle(
                                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 2),
                                const SizedBox(height: 4),
                                Text('\$${p['priceUsd']}', style: const TextStyle(
                                  color: AppTheme.brand, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ref.read(cartProvider.notifier).add(CartItem(
                                        id: p['id'] as int,
                                        name: p['name'] as String,
                                        priceUsd: (p['priceUsd'] as num).toDouble(),
                                        imageUrl: p['imageUrl'] as String?,
                                      ));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${p['name']} added to cart'),
                                          backgroundColor: AppTheme.dark700,
                                          action: SnackBarAction(
                                            label: 'View Cart',
                                            textColor: AppTheme.brand,
                                            onPressed: () => context.go('/cart'),
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8)),
                                    child: const Text('Add to Cart', style: TextStyle(fontSize: 11)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
