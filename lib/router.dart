import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/services_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/create_screen.dart';
import 'screens/blog_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/portal_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/explorer_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/stylist_screen.dart';
import 'screens/stock_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/gift_session_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
        GoRoute(path: '/portfolio', builder: (c, s) => const PortfolioScreen()),
        GoRoute(path: '/services', builder: (c, s) => const ServicesScreen()),
        GoRoute(path: '/booking', builder: (c, s) => const BookingScreen()),
        GoRoute(path: '/shop', builder: (c, s) => const ShopScreen()),
        GoRoute(path: '/cart', builder: (c, s) => const CartScreen()),
        GoRoute(path: '/create', builder: (c, s) => const CreateScreen()),
        GoRoute(path: '/blog', builder: (c, s) => const BlogScreen()),
        GoRoute(path: '/chat', builder: (c, s) => const ChatScreen()),
        GoRoute(path: '/portal', builder: (c, s) => const PortalScreen()),
        GoRoute(path: '/explore', builder: (c, s) => const ExplorerScreen()),
        GoRoute(
          path: '/gallery/:id',
          builder: (c, s) => GalleryScreen(galleryId: int.parse(s.pathParameters['id']!)),
        ),
        GoRoute(path: '/stylist', builder: (c, s) => const StylistScreen()),
        GoRoute(path: '/stock', builder: (c, s) => const StockScreen()),
        GoRoute(path: '/timeline', builder: (c, s) => const TimelineScreen()),
        GoRoute(path: '/gift', builder: (c, s) => const GiftSessionScreen()),
      ],
    ),
  ],
);
