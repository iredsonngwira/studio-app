import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../services/queries.dart';
import '../theme.dart';
import '../main.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PortalScreen extends ConsumerWidget {
  const PortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) return _LoginScreen();
    return _PortalContent(user: auth.user ?? {});
  }
}

// ── Login ─────────────────────────────────────────────────────────────────────

class _LoginScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<_LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Client Portal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Welcome Back', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Sign in to access your galleries and bookings', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey, size: 18),
                hintText: 'your@email.com',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pass,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock_outline, color: Colors.grey, size: 18),
                hintText: '••••••••',
              ),
              onSubmitted: (_) => _doLogin(),
            ),
            const SizedBox(height: 24),
            if (auth.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.red.shade900.withOpacity(0.3),
                  border: Border.all(color: Colors.red.shade800),
                ),
                child: Text(auth.error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _doLogin,
                child: auth.loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Sign In'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doLogin() async {
    await ref.read(authProvider.notifier).login(_email.text.trim(), _pass.text);
  }
}

// ── Portal content ────────────────────────────────────────────────────────────

class _PortalContent extends ConsumerWidget {
  final Map<String, dynamic> user;
  const _PortalContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Portal'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            child: const Text('Sign out', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
      body: Query(
        options: QueryOptions(document: gql(kGetMyGalleries)),
        builder: (galResult, {fetchMore, refetch}) {
          return Query(
            options: QueryOptions(document: gql(kGetMyBookings)),
            builder: (bookResult, {fetchMore, refetch}) {
              final galleries = (galResult.data?['myGalleries'] as List?) ?? [];
              final bookings = (bookResult.data?['myBookings'] as List?) ?? [];

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // User card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dark600),
                      color: AppTheme.dark800,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50, height: 50,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.brand),
                          child: Center(child: Text(
                            (user['name'] as String? ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                          )),
                        ),
                        const SizedBox(width: 14),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Welcome back!', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(user['name'] ?? user['email'] ?? '',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ]),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.timeline, color: AppTheme.brand),
                          onPressed: () => context.go('/timeline'),
                          tooltip: 'My Timeline',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats
                  Row(children: [
                    _Stat(label: 'Galleries', value: '${galleries.length}'),
                    const SizedBox(width: 12),
                    _Stat(label: 'Bookings', value: '${bookings.length}'),
                    const SizedBox(width: 12),
                    _Stat(
                      label: 'Confirmed',
                      value: '${bookings.where((b) => b['status'] == 'confirmed').length}',
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Galleries
                  const Text('My Galleries', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (galResult.isLoading)
                    const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                  else if (galleries.isEmpty)
                    _EmptyState(icon: Icons.photo_library_outlined, text: 'No galleries yet. Your photos will appear here after your session.')
                  else
                    ...galleries.map((g) => GestureDetector(
                      onTap: () => context.go('/gallery/${g['id']}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.dark600),
                          color: AppTheme.dark800,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              child: g['thumbnailUrl'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: '$kApiBase${g['thumbnailUrl']}',
                                      width: 80, height: 80, fit: BoxFit.cover,
                                      placeholder: (c, u) => Container(width: 80, height: 80, color: AppTheme.dark700),
                                    )
                                  : Container(width: 80, height: 80, color: AppTheme.dark700,
                                      child: const Icon(Icons.photo_library, color: Colors.grey)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                Text('${g['fileCount']} photos', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                if ((g['narrative'] as String?)?.isNotEmpty == true)
                                  const Text('📖 Story available', style: TextStyle(color: AppTheme.brand, fontSize: 11)),
                              ],
                            )),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    )),

                  const SizedBox(height: 24),

                  // Bookings
                  const Text('My Bookings', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (bookResult.isLoading)
                    const Center(child: CircularProgressIndicator(color: AppTheme.brand))
                  else if (bookings.isEmpty)
                    _EmptyState(icon: Icons.calendar_today_outlined, text: 'No bookings yet.')
                  else
                    ...bookings.map((b) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.dark600),
                        color: AppTheme.dark800,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b['serviceName'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              Text(b['sessionDate'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          )),
                          _StatusBadge(status: b['status'] ?? ''),
                        ],
                      ),
                    )),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dark600),
        color: AppTheme.dark800,
      ),
      child: Column(children: [
        Text(value, style: const TextStyle(color: AppTheme.brand, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.dark600),
      color: AppTheme.dark800,
    ),
    child: Column(children: [
      Icon(icon, color: AppTheme.brand, size: 40),
      const SizedBox(height: 12),
      Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13), textAlign: TextAlign.center),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final colors = {
      'confirmed': [Colors.green.shade900, Colors.green.shade400],
      'pending': [Colors.yellow.shade900, Colors.yellow.shade400],
      'completed': [AppTheme.brand.withOpacity(0.2), AppTheme.brand],
      'cancelled': [Colors.red.shade900, Colors.red.shade400],
    };
    final c = colors[status] ?? [AppTheme.dark600, Colors.grey];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: c[0],
        border: Border.all(color: c[1]),
      ),
      child: Text(status, style: TextStyle(color: c[1], fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
