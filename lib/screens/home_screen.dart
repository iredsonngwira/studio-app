import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kGetHomeData)),
      builder: (result, {fetchMore, refetch}) {
        final info = result.data?['siteInfo'];
        final portfolio = (result.data?['portfolio'] as List?) ?? [];
        final services = (result.data?['services'] as List?) ?? [];
        final testimonials = (result.data?['testimonials'] as List?) ?? [];

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero App Bar
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppTheme.dark800,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    onPressed: () => context.go('/portal'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppTheme.dark700, AppTheme.darkBg],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        const Text('STUDIO', style: TextStyle(
                          color: AppTheme.brand,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        )),
                        const SizedBox(height: 8),
                        Text(
                          info?['tagline'] ?? 'Capturing Moments. Crafting Brands.',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info?['location'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => context.go('/portfolio'),
                              child: const Text('View Work'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () => context.go('/booking'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.brand,
                                side: const BorderSide(color: AppTheme.brand),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              child: const Text('Book Now'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (result.isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.brand)),
                )
              else ...[
                // Services
                _SectionHeader(title: 'Our Services', onSeeAll: () => context.go('/services')),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: services.length,
                      itemBuilder: (ctx, i) {
                        final s = services[i];
                        return GestureDetector(
                          onTap: () => context.go('/services'),
                          child: Container(
                            width: 140,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.dark600),
                              color: AppTheme.dark800,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt, color: AppTheme.brand, size: 28),
                                const SizedBox(height: 8),
                                Text(s['name'] ?? '', style: const TextStyle(
                                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                                Text(s['tagline'] ?? '', style: const TextStyle(
                                  color: Colors.grey, fontSize: 10),
                                  textAlign: TextAlign.center,
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Featured Portfolio
                _SectionHeader(title: 'Featured Work', onSeeAll: () => context.go('/portfolio')),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final item = portfolio[i];
                        final imgUrl = item['imageUrl'];
                        return GestureDetector(
                          onTap: () => context.go('/portfolio'),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imgUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: '$kApiBase$imgUrl',
                                  fit: BoxFit.cover,
                                  placeholder: (c, u) => Container(color: AppTheme.dark700),
                                  errorWidget: (c, u, e) => Container(
                                    color: AppTheme.dark700,
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  ),
                                )
                              : Container(color: AppTheme.dark700,
                                  child: const Icon(Icons.image, color: Colors.grey)),
                          ),
                        );
                      },
                      childCount: portfolio.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
                    ),
                  ),
                ),

                // Testimonials
                if (testimonials.isNotEmpty) ...[
                  const _SectionHeader(title: 'What Clients Say'),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: testimonials.length,
                        itemBuilder: (ctx, i) {
                          final t = testimonials[i];
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.dark600),
                              color: AppTheme.dark800,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: List.generate(t['rating'] ?? 5,
                                  (_) => const Icon(Icons.star, color: AppTheme.brand, size: 14))),
                                const SizedBox(height: 8),
                                Text('"${t['message']}"',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  maxLines: 3, overflow: TextOverflow.ellipsis),
                                const Spacer(),
                                Text(t['name'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // Explorer teaser
                _SectionHeader(title: 'Explore Malawi', onSeeAll: () => context.go('/explore')),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => context.go('/explore'),
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [AppTheme.brand.withOpacity(0.3), AppTheme.dark700],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: AppTheme.brand.withOpacity(0.3)),
                        ),
                        child: const Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('🌍', style: TextStyle(fontSize: 36)),
                            SizedBox(height: 8),
                            Text('Landscapes · Culture · Wildlife', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            SizedBox(height: 4),
                            Text('Tap to explore →', style: TextStyle(color: AppTheme.brand, fontSize: 12)),
                          ],
                        )),
                      ),
                    ),
                  ),
                ),

                // Pre-Shoot Stylist CTA
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: GestureDetector(
                      onTap: () => context.go('/stylist'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.dark600),
                          color: AppTheme.dark800,
                        ),
                        child: const Row(children: [
                          Text('✨', style: TextStyle(fontSize: 28)),
                          SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Pre-Shoot Stylist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Not sure what to wear? Get AI outfit advice before your session.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ])),
                          Icon(Icons.chevron_right, color: AppTheme.brand),
                        ]),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: const Text('See all →',
                  style: TextStyle(color: AppTheme.brand, fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
