import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Story')),
      body: Query(
        options: QueryOptions(document: gql(kGetMyTimeline)),
        builder: (result, {fetchMore, refetch}) {
          final entries = (result.data?['myTimeline'] as List?) ?? [];
          if (result.isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.brand));
          if (entries.isEmpty) return const Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.timeline, color: Colors.grey, size: 60),
              SizedBox(height: 16),
              Text('Your story starts with your first booking.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
            ]),
          );
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: entries.length,
            itemBuilder: (ctx, i) {
              final e = entries[i];
              final isGallery = e['entryType'] == 'gallery';
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline line
                  Column(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isGallery ? AppTheme.brand.withOpacity(0.2) : AppTheme.dark700,
                        border: Border.all(color: AppTheme.brand),
                      ),
                      child: Icon(
                        isGallery ? Icons.photo_library : Icons.calendar_today,
                        color: AppTheme.brand, size: 16,
                      ),
                    ),
                    if (i < entries.length - 1)
                      Container(width: 2, height: 60, color: AppTheme.dark600),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: isGallery ? () => context.go('/gallery/${e['refId']}') : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.dark600),
                          color: AppTheme.dark800,
                        ),
                        child: Row(
                          children: [
                            if (e['thumbnailUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: '$kApiBase${e['thumbnailUrl']}',
                                  width: 50, height: 50, fit: BoxFit.cover,
                                ),
                              ),
                            if (e['thumbnailUrl'] != null) const SizedBox(width: 12),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                Text(e['subtitle'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(e['date'] ?? '', style: const TextStyle(color: AppTheme.brand, fontSize: 11)),
                              ],
                            )),
                            if (isGallery) const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
