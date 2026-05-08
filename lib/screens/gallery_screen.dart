import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  final int galleryId;
  const GalleryScreen({super.key, required this.galleryId});
  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final Set<int> _favorites = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kGetMyGalleries)),
      builder: (result, {fetchMore, refetch}) {
        final galleries = (result.data?['myGalleries'] as List?) ?? [];
        final gallery = galleries.cast<Map?>().firstWhere(
          (g) => g?['id'] == widget.galleryId, orElse: () => null);

        if (result.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.brand)));
        }
        if (gallery == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Gallery not found', style: TextStyle(color: Colors.grey))));
        }

        final files = (gallery['files'] as List?) ?? [];
        final narrative = gallery['narrative'] as String? ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text(gallery['title'] ?? ''),
            bottom: TabBar(
              controller: _tabs,
              indicatorColor: AppTheme.brand,
              labelColor: AppTheme.brand,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Photos'),
                Tab(text: 'Story'),
                Tab(text: 'Favorites'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              // Photos tab
              _PhotosGrid(files: files, favorites: _favorites, onFavorite: _toggleFavorite, galleryId: widget.galleryId),
              // Story tab
              _StoryTab(narrative: narrative, title: gallery['title'] ?? ''),
              // Favorites tab
              _FavoritesTab(files: files.where((f) => _favorites.contains(f['id'])).toList()),
            ],
          ),
        );
      },
    );
  }

  void _toggleFavorite(int photoId) {
    setState(() {
      if (_favorites.contains(photoId)) {
        _favorites.remove(photoId);
      } else {
        _favorites.add(photoId);
      }
    });
    // Fire GraphQL mutation
    GraphQLProvider.of(context).value.mutate(MutationOptions(
      document: gql(kToggleFavorite),
      variables: {'photoId': photoId},
    ));
  }
}

class _PhotosGrid extends StatelessWidget {
  final List files;
  final Set<int> favorites;
  final void Function(int) onFavorite;
  final int galleryId;
  const _PhotosGrid({required this.files, required this.favorites, required this.onFavorite, required this.galleryId});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const Center(child: Text('No photos yet.', style: TextStyle(color: Colors.grey)));
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 6, mainAxisSpacing: 6),
      itemCount: files.length,
      itemBuilder: (ctx, i) {
        final f = files[i];
        final isFav = favorites.contains(f['id'] as int);
        return GestureDetector(
          onTap: () => _showPhotoDetail(context, f, galleryId),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: '$kApiBase${f['thumbnailUrl'] ?? f['url']}',
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: AppTheme.dark700,
                      child: const Center(child: CircularProgressIndicator(color: AppTheme.brand, strokeWidth: 2))),
                ),
              ),
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: () => onFavorite(f['id'] as int),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhotoDetail(BuildContext context, Map f, int galleryId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.dark800,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (_, ctrl) => Column(
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: '$kApiBase${f['url']}',
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => launchUrl(Uri.parse('$kApiBase${f['url']}')),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => Share.share('$kApiBase${f['url']}', subject: 'Photo from KamotoHD'),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.brand,
                      side: const BorderSide(color: AppTheme.brand),
                      shape: const StadiumBorder(),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryTab extends StatelessWidget {
  final String narrative, title;
  const _StoryTab({required this.narrative, required this.title});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📖 The Story of This Session',
              style: TextStyle(color: AppTheme.brand, fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: 16),
          if (narrative.isNotEmpty)
            Text(narrative, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.8))
          else
            const Text('The story of this session is being written...', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Share.share(narrative.isNotEmpty ? narrative : title),
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share This Story'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.brand,
              side: const BorderSide(color: AppTheme.brand),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  final List files;
  const _FavoritesTab({required this.files});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.favorite_border, color: Colors.grey, size: 48),
          SizedBox(height: 12),
          Text('Tap ♥ on photos to add favorites', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 6, mainAxisSpacing: 6),
      itemCount: files.length,
      itemBuilder: (ctx, i) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: '$kApiBase${files[i]['thumbnailUrl'] ?? files[i]['url']}',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
