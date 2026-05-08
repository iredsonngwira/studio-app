import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'router.dart';
import 'theme.dart';
import 'services/push_notifications.dart';

// Change this to your deployed URL before release
const String kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://10.0.2.2:8000', // Android emulator → localhost
);

// Auth token provider — shared across the app
final authTokenProvider = StateProvider<String?>((ref) => null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initHiveForFlutter();

  // Restore saved auth token
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('auth_token');

  // Init push notifications (non-blocking)
  initPushNotifications(authToken: savedToken).catchError((_) {});

  runApp(ProviderScope(
    overrides: [
      authTokenProvider.overrideWith((ref) => savedToken),
    ],
    child: const StudioApp(),
  ));
}

class StudioApp extends ConsumerWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authTokenProvider);

    final httpLink = HttpLink('$kApiBase/graphql/');
    final authLink = AuthLink(getToken: () => token != null ? 'Bearer $token' : null);
    final link = token != null ? authLink.concat(httpLink) : httpLink;

    final client = ValueNotifier(
      GraphQLClient(link: link, cache: GraphQLCache(store: HiveStore())),
    );

    return GraphQLProvider(
      client: client,
      child: MaterialApp.router(
        title: 'Kamoto HD',
        theme: AppTheme.darkTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
