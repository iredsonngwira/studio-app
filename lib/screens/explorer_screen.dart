import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';

class ExplorerScreen extends StatelessWidget {
  const ExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kGetExplorerFeed), variables: const {'limit': 30}),
      builder: (result, {fetchMore, refetch}) {
        final posts = (result.data?['explorerFeed'] as List?) ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Explore Malawi'),
            actions: [
              IconButton(
                icon: const Icon(Icons.image_search),
                onPressed: () => context.go('/stock'),
                tooltip: 'Stock Photos',
              ),
            ],
          ),
          body: result.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
              : posts.isEmpty
                  ? const Center(child: Text('Explorer content coming soon.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: posts.length,
                      itemBuilder: (ctx, i) => _ExplorerCard(post: posts[i]),
                    ),
        );
      },
    );
  }
}

class _ExplorerCard extends StatelessWidget {
  final Map post;
  const _ExplorerCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final imgUrl = post['imageUrl'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dark600),
        color: AppTheme.dark800,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imgUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: '$kApiBase$imgUrl',
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(height: 240, color: AppTheme.dark700,
                    child: const Center(child: CircularProgressIndicator(color: AppTheme.brand, strokeWidth: 2))),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((post['location'] as String?)?.isNotEmpty == true)
                  Row(children: [
                    const Icon(Icons.location_on, color: AppTheme.brand, size: 14),
                    const SizedBox(width: 4),
                    Text(post['location'], style: const TextStyle(color: AppTheme.brand, fontSize: 12)),
                  ]),
                const SizedBox(height: 6),
                Text(post['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(post['caption'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('${post['views']} views', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    const Spacer(),
                    if (post['isLicensable'] == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.brand),
                          color: AppTheme.brand.withOpacity(0.1),
                        ),
                        child: Text('\$${post['licensePriceUsd']} License',
                            style: const TextStyle(color: AppTheme.brand, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => context.go('/booking'),
                      icon: const Icon(Icons.camera_alt, size: 14),
                      label: const Text('Book Shoot', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.brand,
                        side: const BorderSide(color: AppTheme.brand),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
