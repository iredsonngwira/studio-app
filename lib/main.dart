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

  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('auth_token');
  final savedEmail = prefs.getString('auth_email');

  initPushNotifications(authToken: savedToken).catchError((_) {});

  runApp(ProviderScope(
    overrides: [
      authTokenProvider.overrideWith((ref) => savedToken),
    ],
    child: StudioApp(savedToken: savedToken, savedEmail: savedEmail),
  ));
}

class StudioApp extends ConsumerWidget {
  final String? savedToken;
  final String? savedEmail;
  const StudioApp({super.key, this.savedToken, this.savedEmail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(authTokenProvider);

    // Restore auth state on first build if token exists
    if (savedToken != null && !ref.read(authProvider).isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authProvider.notifier).restoreFromToken(
          savedToken!,
          user: savedEmail != null ? {'name': savedEmail!.split('@')[0], 'email': savedEmail} : null,
        );
      });
    }

    final httpLink = HttpLink('$kApiBase/graphql/');
    final authLink = AuthLink(getToken: () => token != null ? 'Bearer $token' : null);
    final link = token != null ? authLink.concat(httpLink) : httpLink;

    // Key forces GraphQLProvider to rebuild with new client when token changes
    final client = ValueNotifier(
      GraphQLClient(link: link, cache: GraphQLCache(store: HiveStore())),
    );

    return GraphQLProvider(
      key: ValueKey(token),
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
