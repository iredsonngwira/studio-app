import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../services/queries.dart';
import '../theme.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kGetBlog)),
      builder: (result, {fetchMore, refetch}) {
        final posts = (result.data?['blogPosts'] as List?) ?? [];
        return Scaffold(
          appBar: AppBar(title: const Text('Blog')),
          body: result.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.brand))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: posts.length,
                itemBuilder: (ctx, i) {
                  final p = posts[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dark600),
                      color: AppTheme.dark800,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p['publishedAt'] != null)
                            Text(p['publishedAt'].toString().substring(0, 10),
                              style: const TextStyle(color: AppTheme.brand, fontSize: 11)),
                          const SizedBox(height: 6),
                          Text(p['title'] ?? '', style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(p['excerpt'] ?? '', style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                            maxLines: 3, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          const Text('Read more →', style: TextStyle(color: AppTheme.brand, fontSize: 12)),
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
}
