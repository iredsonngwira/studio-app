import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kGetServices)),
      builder: (result, {fetchMore, refetch}) {
        final services = (result.data?['services'] as List?) ?? [];
        return Scaffold(
          appBar: AppBar(title: const Text('Services')),
          body: result.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: services.length,
                itemBuilder: (ctx, i) {
                  final s = services[i];
                  final imgUrl = s['coverImageUrl'];
                  return GestureDetector(
                    onTap: () => _showService(context, s),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dark600),
                        color: AppTheme.dark800,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imgUrl != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              child: CachedNetworkImage(
                                imageUrl: '$kApiBase$imgUrl',
                                height: 160, width: double.infinity, fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s['name'] ?? '', style: const TextStyle(
                                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(s['tagline'] ?? '', style: const TextStyle(
                                  color: AppTheme.brand, fontSize: 13)),
                                const SizedBox(height: 8),
                                Text(s['description'] ?? '', style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 12),
                                // Package prices
                                Wrap(
                                  spacing: 8,
                                  children: ((s['packages'] as List?) ?? []).map<Widget>((p) =>
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.dark600),
                                      ),
                                      child: Text('${p['name']} \$${p['priceUsd']}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    )
                                  ).toList(),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => context.go('/booking'),
                                  child: const Text('Book This Service'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        );
      },
    );
  }

  void _showService(BuildContext context, Map s) {
    final packages = (s['packages'] as List?) ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dark800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.95, minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Text(s['name'] ?? '', style: const TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(s['description'] ?? '', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            const Text('Packages', style: TextStyle(
              color: AppTheme.brand, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...packages.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (p['isPopular'] == true) ? AppTheme.brand : AppTheme.dark600,
                  width: (p['isPopular'] == true) ? 2 : 1,
                ),
                color: AppTheme.dark700,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['name'] ?? '', style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('\$${p['priceUsd']}', style: const TextStyle(
                        color: AppTheme.brand, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  if ((p['features'] as List?)?.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    ...((p['features'] as List).map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        const Icon(Icons.check, color: AppTheme.brand, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(f.toString(),
                          style: const TextStyle(color: Colors.white70, fontSize: 12))),
                      ]),
                    ))),
                  ],
                ],
              ),
            )),
            ElevatedButton(
              onPressed: () { Navigator.pop(context); context.go('/booking'); },
              child: const Text('Book Now'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
