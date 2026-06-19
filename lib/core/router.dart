import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/app_providers.dart';
import '../features/auth/add_server_screen.dart';
import '../features/auth/servers_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/detail/detail_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/series/series_screen.dart';
import '../features/person/person_screen.dart';
import '../features/watchlist/watchlist_screen.dart';
import '../features/genre/genre_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // NE PAS watch activeServerProvider : sinon le router est recréé à la
  // connexion et repart sur sa route de départ (/login). On lit l'état en
  // direct dans redirect via ref.read.
  final storage = ref.read(serverStorageProvider);

  // Route de connexion par défaut : page de login si un serveur est connu,
  // sinon ajout de serveur.
  String authEntry() =>
      storage.getKnownServers().isEmpty ? '/add-server' : '/login';

  const authRoutes = {'/login', '/add-server', '/servers'};

  return GoRouter(
    initialLocation: authEntry(),
    redirect: (context, state) {
      if (authRoutes.contains(state.matchedLocation)) return null;
      // Routes applicatives : exigent un compte connecté (lu en direct).
      if (ref.read(activeServerProvider) == null) return authEntry();
      return null;
    },
    routes: [
      GoRoute(
        path: '/add-server',
        builder: (_, __) => const AddServerScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/servers',
        builder: (_, __) => const ServersScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: '/library/:id',
        builder: (_, state) => LibraryScreen(
          libraryId: Uri.decodeComponent(state.pathParameters['id']!),
          libraryName: state.uri.queryParameters['name'] ?? 'Bibliothèque',
          collectionType: state.uri.queryParameters['type'],
        ),
      ),
      GoRoute(
        path: '/detail/:id',
        builder: (_, state) => DetailScreen(
          itemId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/series/:id',
        builder: (_, state) => SeriesScreen(
          seriesId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const SearchScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/watchlist',
        builder: (_, __) => const WatchlistScreen(),
      ),
      GoRoute(
        path: '/genre/:name',
        builder: (_, state) => GenreScreen(
          genre: Uri.decodeComponent(state.pathParameters['name']!),
        ),
      ),
      GoRoute(
        path: '/person/:id',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PersonScreen(
            personId: state.pathParameters['id']!,
            personName: extra?['name'] as String? ?? '',
            personRole: extra?['role'] as String?,
          );
        },
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page introuvable : ${state.error}')),
    ),
  );
});
