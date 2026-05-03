import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});
  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kGetPortfolio),
        variables: {'category': _selectedCategory},
      ),
      builder: (result, {fetchMore, refetch}) {
        final items = (result.data?['portfolio'] as List?) ?? [];
        final categories = (result.data?['categories'] as List?) ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Portfolio')),
          body: Column(
            children: [
              // Category filter
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _CategoryChip(label: 'All', selected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null)),
                    ...categories.map((c) => _CategoryChip(
                      label: c['name'],
                      selected: _selectedCategory == c['slug'],
                      onTap: () => setState(() => _selectedCategory = c['slug']),
                    )),
                  ],
                ),
              ),
              Expanded(
                child: result.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        final imgUrl = item['imageUrl'];
                        return GestureDetector(
                          onTap: () => _showDetail(context, item),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                imgUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: '$kApiBase$imgUrl', fit: BoxFit.cover,
                                      placeholder: (c, u) => Container(color: AppTheme.dark700),
                                    )
                                  : Container(color: AppTheme.dark700,
                                      child: const Icon(Icons.image, color: Colors.grey)),
                                Positioned(
                                  bottom: 0, left: 0, right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [Colors.black87, Colors.transparent],
                                      ),
                                    ),
                                    child: Text(item['title'] ?? '',
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetail(BuildContext context, Map item) {
    final imgUrl = item['imageUrl'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dark800,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imgUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: '$kApiBase$imgUrl',
                height: 250, width: double.infinity, fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? '', style: const TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if ((item['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(item['description'], style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
                if ((item['location'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on, color: AppTheme.brand, size: 14),
                    const SizedBox(width: 4),
                    Text(item['location'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? AppTheme.brand : AppTheme.dark700,
          border: Border.all(color: selected ? AppTheme.brand : AppTheme.dark600),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.black : Colors.grey,
          fontSize: 12, fontWeight: FontWeight.w500,
        )),
      ),
    );
  }
}
