import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _aiMode = false;
  String? _aiSummary;
  List _aiResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Photos')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: _aiMode ? 'Describe what you need...' : 'Search by subject, location...',
                    prefixIcon: Icon(_aiMode ? Icons.auto_awesome : Icons.search, color: Colors.grey, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() { _aiMode = !_aiMode; _aiResults = []; _aiSummary = null; }),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _aiMode ? AppTheme.brand : AppTheme.dark600),
                    color: _aiMode ? AppTheme.brand.withOpacity(0.1) : AppTheme.dark800,
                  ),
                  child: Icon(Icons.auto_awesome, color: _aiMode ? AppTheme.brand : Colors.grey, size: 20),
                ),
              ),
            ]),
          ),

          if (_aiMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Mutation(
                options: MutationOptions(document: gql(kSearchStockAI)),
                builder: (runMutation, result) => ElevatedButton.icon(
                  onPressed: result.isLoading ? null : () async {
                    final q = _searchCtrl.text.trim();
                    if (q.isEmpty) return;
                    final res = await runMutation({'query': q}).networkResult;
                    setState(() {
                      _aiSummary = res?.data?['searchStockPhotosAi']?['aiSummary'];
                      _aiResults = res?.data?['searchStockPhotosAi']?['items'] ?? [];
                    });
                  },
                  icon: result.isLoading
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.search, size: 16),
                  label: const Text('AI Search'),
                ),
              ),
            ),

          if (_aiSummary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(_aiSummary!, style: const TextStyle(color: AppTheme.brand, fontSize: 12)),
            ),

          Expanded(
            child: _aiMode && _aiResults.isNotEmpty
                ? _buildGrid(_aiResults)
                : Query(
                    options: QueryOptions(
                      document: gql(kGetStockPhotos),
                      variables: {'search': _search.isEmpty ? null : _search},
                    ),
                    builder: (result, {fetchMore, refetch}) {
                      final items = (result.data?['stockPhotos'] as List?) ?? [];
                      if (result.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.brand));
                      if (items.isEmpty) return const Center(child: Text('No licensed photos yet.', style: TextStyle(color: Colors.grey)));
                      return _buildGrid(items);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List items) => GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.75),
    itemCount: items.length,
    itemBuilder: (ctx, i) {
      final item = items[i];
      return GestureDetector(
        onTap: () => _showLicenseSheet(ctx, item),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dark600),
            color: AppTheme.dark800,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: item['imageUrl'] != null
                      ? CachedNetworkImage(
                          imageUrl: '$kApiBase${item['imageUrl']}',
                          width: double.infinity, fit: BoxFit.cover,
                          placeholder: (c, u) => Container(color: AppTheme.dark700),
                        )
                      : Container(color: AppTheme.dark700, child: const Icon(Icons.image, color: Colors.grey)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if ((item['location'] as String?)?.isNotEmpty == true)
                    Text('📍 ${item['location']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  Text('\$${item['licensePriceUsd']}', style: const TextStyle(color: AppTheme.brand, fontSize: 12, fontWeight: FontWeight.bold)),
                ]),
              ),
            ],
          ),
        ),
      );
    },
  );

  void _showLicenseSheet(BuildContext context, Map item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dark800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('\$${item['licensePriceUsd']} USD', style: const TextStyle(color: AppTheme.brand, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('To license this image, complete the purchase on our website:', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => launchUrl(Uri.parse('$kApiBase/stock/license/?id=${item['id']}')),
                child: const Text('License on Website →'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
