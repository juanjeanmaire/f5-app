import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/groups/domain/group.dart';
import '../../features/groups/presentation/create_group_screen.dart';
import '../../features/groups/presentation/elo_config_screen.dart';
import '../../features/groups/presentation/group_detail_screen.dart';
import '../../features/groups/presentation/join_group_screen.dart';
import '../../features/matches/presentation/create_match_screen.dart';
import '../../features/matches/presentation/match_history_screen.dart';
import '../../features/match_calls/presentation/create_match_call_screen.dart';
import '../../features/match_calls/presentation/match_call_detail_screen.dart';
import '../../features/messages/presentation/captain_conversation_screen.dart';
import '../../features/messages/presentation/captain_inbox_screen.dart';
import '../../features/messages/presentation/member_chat_screen.dart';
import '../../features/players/presentation/player_match_history_screen.dart';
import '../../features/players/presentation/players_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/team_generator/presentation/team_generator_screen.dart';
import '../shell/main_shell_screen.dart';

/// Puente entre el estado de sesión (Riverpod) y GoRouter: en vez de que
/// el router entero dependa de `ref.watch(authControllerProvider)` —lo
/// que recreaba TODO el GoRouter (y reseteaba la navegación a /login)
/// cada vez que cambiaba el usuario logueado, incluso por cosas chicas
/// como guardar el apodo— este notifier solo AVISA que algo cambió, y
/// GoRouter vuelve a evaluar el redirect sin perder su estado interno.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

/// A diferencia de `core/api`, el router SÍ conoce a las features — es la
/// capa de composición de la app, tiene sentido que dependa de ellas.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggingIn = state.matchedLocation == '/login';
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.valueOrNull != null;

      if (isLoading) return null;

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const MainShellScreen()),
      GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
        path: '/groups/create',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/groups/:groupId',
        builder: (context, state) => GroupDetailScreen(
          groupId: state.pathParameters['groupId']!,
          initialGroup: state.extra as Group?,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/players',
        builder: (context, state) => PlayersListScreen(
          groupId: state.pathParameters['groupId']!,
          isAdmin: state.extra as bool? ?? false,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/players/:playerId/matches',
        builder: (context, state) => PlayerMatchHistoryScreen(
          groupId: state.pathParameters['groupId']!,
          playerId: state.pathParameters['playerId']!,
          playerName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/matches',
        builder: (context, state) => MatchHistoryScreen(
          groupId: state.pathParameters['groupId']!,
          isAdmin: state.extra as bool? ?? false,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/matches/create',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreateMatchScreen(
            groupId: state.pathParameters['groupId']!,
            initialTeamAIds: (extra?['teamAIds'] as List?)?.cast<String>(),
            initialTeamBIds: (extra?['teamBIds'] as List?)?.cast<String>(),
          );
        },
      ),
      GoRoute(
        path: '/groups/:groupId/team-generator',
        builder: (context, state) => TeamGeneratorScreen(
          groupId: state.pathParameters['groupId']!,
          isAdmin: state.extra as bool? ?? false,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/elo-config',
        builder: (context, state) => EloConfigScreen(
          groupId: state.pathParameters['groupId']!,
          isAdmin: state.extra as bool? ?? false,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/match-calls/create',
        builder: (context, state) => CreateMatchCallScreen(
          groupId: state.pathParameters['groupId']!,
          groupVenueAddress: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/match-calls/:callId',
        builder: (context, state) => MatchCallDetailScreen(
          groupId: state.pathParameters['groupId']!,
          callId: state.pathParameters['callId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/message-captain',
        builder: (context, state) => MemberChatScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/inbox',
        builder: (context, state) => CaptainInboxScreen(
          groupId: state.pathParameters['groupId']!,
        ),
      ),
      GoRoute(
        path: '/groups/:groupId/inbox/:memberId',
        builder: (context, state) => CaptainConversationScreen(
          groupId: state.pathParameters['groupId']!,
          memberId: state.pathParameters['memberId']!,
          memberName: state.extra as String?,
        ),
      ),
    ],
  );
});
