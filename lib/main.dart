import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'router.dart';
import 'theme.dart';

const String kApiBase = 'http://127.0.0.1:8000'; // change to deployed URL

void main() async {
  await initHiveForFlutter();
  runApp(const ProviderScope(child: StudioApp()));
}

class StudioApp extends StatelessWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final httpLink = HttpLink('$kApiBase/graphql/');
    final client = ValueNotifier(
      GraphQLClient(link: httpLink, cache: GraphQLCache(store: HiveStore())),
    );
    return GraphQLProvider(
      client: client,
      child: MaterialApp.router(
        title: 'Studio',
        theme: AppTheme.darkTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
