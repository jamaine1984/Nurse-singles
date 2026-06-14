import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

// ── Feature Pages ──────────────────────────────────────────────────────────
import 'package:nightingale_heart/features/auth/pages/splash_page.dart';
import 'package:nightingale_heart/features/auth/pages/welcome_page.dart';
import 'package:nightingale_heart/features/auth/pages/login_page.dart';
import 'package:nightingale_heart/features/auth/pages/signup_page.dart';
import 'package:nightingale_heart/features/auth/pages/onboarding_page.dart';
import 'package:nightingale_heart/features/discover/pages/discover_page.dart';
import 'package:nightingale_heart/features/discover/pages/profile_detail_page.dart';
import 'package:nightingale_heart/features/matches/pages/matches_page.dart';
import 'package:nightingale_heart/features/messages/pages/conversations_page.dart';
import 'package:nightingale_heart/features/messages/pages/chat_page.dart';
import 'package:nightingale_heart/features/video_dating/pages/video_lobby_page.dart';
import 'package:nightingale_heart/features/video_dating/pages/video_call_page.dart';
import 'package:nightingale_heart/features/video_dating/pages/video_minutes_page.dart';
import 'package:nightingale_heart/features/profile/pages/profile_page.dart';
import 'package:nightingale_heart/features/gifts/pages/gift_store_page.dart';
import 'package:nightingale_heart/features/gifts/pages/gift_inventory_page.dart';
import 'package:nightingale_heart/features/night_shift/pages/night_owls_page.dart';
import 'package:nightingale_heart/features/compatibility/pages/compatibility_page.dart';
import 'package:nightingale_heart/features/social/pages/social_feed_page.dart';
import 'package:nightingale_heart/features/nurse_hub/pages/nurse_hub_page.dart';
import 'package:nightingale_heart/features/subscription/pages/paywall_page.dart';
import 'package:nightingale_heart/features/subscription/pages/manage_sub_page.dart';
import 'package:nightingale_heart/features/dashboard/pages/dashboard_page.dart';
import 'package:nightingale_heart/features/settings/pages/settings_page.dart';
import 'package:nightingale_heart/features/settings/pages/language_page.dart';
import 'package:nightingale_heart/features/settings/pages/edit_profile_page.dart';
import 'package:nightingale_heart/features/admin/pages/admin_page.dart';
import 'package:nightingale_heart/features/entertainment/pages/games_hub_page.dart';
import 'package:nightingale_heart/features/profile/pages/verification_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

// ─── Route Names ───────────────────────────────────────────────────────────
abstract class RouteNames {
  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String onboarding = 'onboarding';
  static const String home = 'home';
  static const String discover = 'discover';
  static const String discoverProfile = 'discoverProfile';
  static const String matches = 'matches';
  static const String messages = 'messages';
  static const String chat = 'chat';
  static const String video = 'video';
  static const String videoLobby = 'videoLobby';
  static const String videoCall = 'videoCall';
  static const String videoMinutes = 'videoMinutes';
  static const String profile = 'profile';
  static const String gifts = 'gifts';
  static const String giftInventory = 'giftInventory';
  static const String nightOwls = 'nightOwls';
  static const String compatibility = 'compatibility';
  static const String social = 'social';
  static const String nurseHub = 'nurseHub';
  static const String subscription = 'subscription';
  static const String subscriptionManage = 'subscriptionManage';
  static const String dashboard = 'dashboard';
  static const String settings = 'settings';
  static const String settingsLanguage = 'settingsLanguage';
  static const String settingsEditProfile = 'settingsEditProfile';
  static const String admin = 'admin';
  static const String entertainment = 'entertainment';
  static const String verification = 'verification';
}

// ─── Route Paths ───────────────────────────────────────────────────────────
abstract class RoutePaths {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String discoverProfile = '/discover/profile/:userId';
  static const String matches = '/matches';
  static const String messages = '/messages';
  static const String chat = '/messages/:chatId';
  static const String video = '/video';
  static const String videoLobby = '/video/lobby';
  static const String videoCall = '/video/call/:roomId';
  static const String videoMinutes = '/video/minutes';
  static const String profile = '/profile';
  static const String gifts = '/gifts';
  static const String giftInventory = '/gifts/inventory';
  static const String nightOwls = '/night-owls';
  static const String compatibility = '/compatibility';
  static const String social = '/social';
  static const String nurseHub = '/nurse-hub';
  static const String subscription = '/subscription';
  static const String subscriptionManage = '/subscription/manage';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String settingsLanguage = '/settings/language';
  static const String settingsEditProfile = '/settings/edit-profile';
  static const String admin = '/admin';
  static const String entertainment = '/entertainment';
  static const String verification = '/verification';
}

// ─── Router Notifier ──────────────────────────────────────────────────────
/// Listens to auth and user provider changes without recreating the GoRouter.
/// Instead, it triggers redirect re-evaluation via [refreshListenable].
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

// ─── Router Provider ───────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    refreshListenable: notifier,

    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);

      final isLoading = authState.isLoading || currentUser.isLoading;
      if (isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.uri.path;

      final publicRoutes = [
        RoutePaths.splash,
        RoutePaths.welcome,
        RoutePaths.login,
        RoutePaths.signup,
      ];

      final isOnPublicRoute = publicRoutes.contains(currentPath);

      if (!isLoggedIn) {
        if (isOnPublicRoute) return null;
        return RoutePaths.welcome;
      }

      if (currentPath == RoutePaths.signup) {
        return null;
      }

      if (isLoggedIn && (isOnPublicRoute || currentPath == RoutePaths.splash)) {
        return RoutePaths.discover;
      }

      return null;
    },

    routes: [
      // ── Splash ──────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // ── Welcome ─────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.welcome,
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomePage(),
      ),

      // ── Auth ────────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      // ── Main Shell (bottom nav) ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => _MainShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.discover,
            name: RouteNames.discover,
            builder: (context, state) => const DiscoverPage(),
            routes: [
              GoRoute(
                path: 'profile/:userId',
                name: RouteNames.discoverProfile,
                builder: (context, state) {
                  final userId = state.pathParameters['userId']!;
                  return ProfileDetailPage(userId: userId);
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.matches,
            name: RouteNames.matches,
            builder: (context, state) => const MatchesPage(),
          ),
          GoRoute(
            path: RoutePaths.social,
            name: RouteNames.social,
            builder: (context, state) => const SocialFeedPage(),
          ),
          GoRoute(
            path: RoutePaths.nurseHub,
            name: RouteNames.nurseHub,
            builder: (context, state) => const NurseHubPage(),
          ),
          GoRoute(
            path: RoutePaths.messages,
            name: RouteNames.messages,
            builder: (context, state) => const ConversationsPage(),
          ),
          GoRoute(
            path: RoutePaths.video,
            name: RouteNames.video,
            builder: (context, state) => const VideoLobbyPage(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // ── Chat ─────────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.chat,
        name: RouteNames.chat,
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatPage(chatId: chatId);
        },
      ),

      // ── Video Sub-routes ─────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.videoLobby,
        name: RouteNames.videoLobby,
        builder: (context, state) => const VideoLobbyPage(),
      ),
      GoRoute(
        path: RoutePaths.videoCall,
        name: RouteNames.videoCall,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          final query = state.uri.queryParameters;
          return VideoCallPage(
            roomId: roomId,
            sessionType: query['type'] ?? 'speedDate',
            targetUserId: query['targetUserId'],
            targetUserName: query['targetUserName'],
            chatId: query['chatId'],
            callNotificationId: query['callNotificationId'],
          );
        },
      ),
      GoRoute(
        path: RoutePaths.videoMinutes,
        name: RouteNames.videoMinutes,
        builder: (context, state) => const VideoMinutesPage(),
      ),

      // ── Gifts ────────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.gifts,
        name: RouteNames.gifts,
        builder: (context, state) => const GiftStorePage(),
        routes: [
          GoRoute(
            path: 'inventory',
            name: RouteNames.giftInventory,
            builder: (context, state) => const GiftInventoryPage(),
          ),
        ],
      ),

      // ── Night Owls ───────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.nightOwls,
        name: RouteNames.nightOwls,
        builder: (context, state) => const NightOwlsPage(),
      ),

      // ── Compatibility ────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.compatibility,
        name: RouteNames.compatibility,
        builder: (context, state) => const CompatibilityPage(),
      ),

      // ── Subscription ─────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.subscription,
        name: RouteNames.subscription,
        builder: (context, state) => const PaywallPage(),
        routes: [
          GoRoute(
            path: 'manage',
            name: RouteNames.subscriptionManage,
            builder: (context, state) => const ManageSubPage(),
          ),
        ],
      ),

      // ── Dashboard ────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        builder: (context, state) => const DashboardPage(),
      ),

      // ── Settings ─────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'language',
            name: RouteNames.settingsLanguage,
            builder: (context, state) => const LanguagePage(),
          ),
          GoRoute(
            path: 'edit-profile',
            name: RouteNames.settingsEditProfile,
            builder: (context, state) => const EditProfilePage(),
          ),
        ],
      ),

      // ── Admin ────────────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.admin,
        name: RouteNames.admin,
        builder: (context, state) => const AdminPage(),
      ),

      // ── Entertainment ────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.entertainment,
        name: RouteNames.entertainment,
        builder: (context, state) => const GamesHubPage(),
      ),

      // ── Verification ──────────────────────────────────────────────────
      GoRoute(
        path: RoutePaths.verification,
        name: RouteNames.verification,
        builder: (context, state) => const VerificationPage(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.translate(
                'page_not_found',
                Localizations.localeOf(context),
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.path),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RoutePaths.discover),
              child: Text(
                AppLocalizations.translate(
                  'go_home',
                  Localizations.localeOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
});

// ─── Main Shell (Bottom Navigation) ────────────────────────────────────────
class _MainShell extends StatelessWidget {
  const _MainShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(body: child);
}
