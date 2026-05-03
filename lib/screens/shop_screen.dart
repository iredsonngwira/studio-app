import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kGetShop)),
      builder: (result, {fetchMore, refetch}) {
        final products = (result.data?['products'] as List?) ?? [];
        return Scaffold(
          appBar: AppBar(title: const Text('Shop')),
          body: result.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
            : products.isEmpty
              ? const Center(child: Text('No products yet', style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
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
                                    onPressed: () {},
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
