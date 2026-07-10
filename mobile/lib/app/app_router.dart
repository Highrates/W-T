import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/create_route/presentation/create_route_screen.dart';
import '../features/create_route/presentation/route_template_screen.dart';
import '../features/event/presentation/event_screen.dart';
import '../features/profile/presentation/my_profile_screen.dart';
import '../features/profile/presentation/user_profile_screen.dart';
import '../features/shell/presentation/main_shell_screen.dart';

abstract final class AppRoutes {
  static const shell = '/';
  static const event = '/event/:id';
  static const profile = '/profile/:id';
  static const me = '/me';
  static const createRoute = '/create-route';
  static const routeTemplate = '/event/:id/template';

  static String eventPath(String id) => '/event/$id';
  static String profilePath(String id) => '/profile/$id';
  static String publishedEventPath(String id) => '/event/$id?published=1';
  static String routeTemplatePath(String eventId) => '/event/$eventId/template';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.shell,
    routes: [
      GoRoute(
        path: AppRoutes.shell,
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: AppRoutes.event,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return const _RouteErrorScreen(message: 'Событие не найдено');
          }
          final justPublished = state.uri.queryParameters['published'] == '1';
          return EventScreen(eventId: id, justPublished: justPublished);
        },
        routes: [
          GoRoute(
            path: 'template',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              if (id == null || id.isEmpty) {
                return const _RouteErrorScreen(message: 'Событие не найдено');
              }
              return RouteTemplateScreen(eventId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.me,
        builder: (context, state) => const MyProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return const _RouteErrorScreen(message: 'Профиль не найден');
          }
          return UserProfileScreen(userId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.createRoute,
        builder: (context, state) => const CreateRouteScreen(),
      ),
    ],
  );
});

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(message)),
    );
  }
}
