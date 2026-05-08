import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.path;
    final idx = _index(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.dark600)),
        ),
        child: BottomNavigationBar(
          currentIndex: idx,
          onTap: (i) {
            switch (i) {
              case 0: context.go('/'); break;
              case 1: context.go('/portfolio'); break;
              case 2: context.go('/explore'); break;
              case 3: context.go('/booking'); break;
              case 4: context.go('/shop'); break;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.photo_library_outlined), activeIcon: Icon(Icons.photo_library), label: 'Portfolio'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Book'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Shop'),
          ],
        ),
      ),
      floatingActionButton: !loc.startsWith('/chat')
          ? FloatingActionButton(
              mini: true,
              backgroundColor: AppTheme.brand,
              onPressed: () => context.go('/chat'),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.black, size: 20),
            )
          : null,
    );
  }

  int _index(String loc) {
    if (loc.startsWith('/portfolio')) return 1;
    if (loc.startsWith('/explore')) return 2;
    if (loc.startsWith('/booking')) return 3;
    if (loc.startsWith('/shop') || loc.startsWith('/cart')) return 4;
    return 0;
  }
}
