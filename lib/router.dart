import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'di/service_locator.dart';
import 'domain/services/i_supabase_service.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/pandit_listing_screen.dart';
import 'presentation/screens/pandit_details_screen.dart';
import 'presentation/screens/checkout_screen.dart';
import 'presentation/screens/bookings_list_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/admin_dashboard_screen.dart';
import 'models/pandit_model.dart';

class AuthStateRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  AuthStateRefreshNotifier() {
    _subscription = getIt<ISupabaseService>().authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final AuthStateRefreshNotifier _authRefreshNotifier = AuthStateRefreshNotifier();

bool _isAuthenticated() => getIt<ISupabaseService>().currentUser != null;

final goRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: _authRefreshNotifier,
  redirect: (context, state) {
    final bool loggedIn = _isAuthenticated();
    final String path = state.uri.path;
    final bool needsAuth = path == '/pandits' || path == '/checkout' || path == '/bookings' || path == '/profile' || path == '/pandit_details';

    if (!loggedIn && needsAuth) return '/login';
    if (loggedIn && path == '/login') return '/pandits';
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/pandits',
      builder: (context, state) => const PanditListingScreen(),
    ),
    GoRoute(
      path: '/pandit_details',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! PanditModel) {
          return const PanditListingScreen();
        }
        return PanditDetailsScreen(pandit: extra);
      },
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is! PanditModel) {
          return const HomeScreen();
        }
        return CheckoutScreen(pandit: extra);
      },
    ),
    GoRoute(
      path: '/bookings',
      builder: (context, state) => const BookingsListScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
