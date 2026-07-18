/// ─── Bamako Thrift — GoRouter Configuration ───────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';

// ── Onboarding ────────────────────────────────────────────────────────────────────
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/onboarding/presentation/pages/intro_page.dart';
import '../../features/onboarding/presentation/pages/splash_page.dart';

// ── Auth ───────────────────────────────────────────────────────────────────
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';

// ── Home ───────────────────────────────────────────────────────────────────
import '../../features/home/presentation/pages/home_page.dart';

// ── Catalog ────────────────────────────────────────────────────────────────
import '../../features/catalog/presentation/pages/catalog_page.dart';
import '../../features/catalog/presentation/pages/search_page.dart';
import '../../features/catalog/presentation/pages/filter_page.dart';

// ── Product ────────────────────────────────────────────────────────────────
import '../../features/product/presentation/pages/product_detail_page.dart';

// ── Publish ────────────────────────────────────────────────────────────────
import '../../features/publish/presentation/pages/publish_product_page.dart';

// ── Payment ────────────────────────────────────────────────────────────────
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/payment/presentation/pages/payment_success_page.dart';
import '../../features/payment/presentation/pages/payment_failed_page.dart';
import '../../features/product/domain/entities/product_entity.dart';

// ── Orders ─────────────────────────────────────────────────────────────────
import '../../features/order/presentation/pages/orders_page.dart';
import '../../features/order/presentation/pages/order_tracking_page.dart';

// ── Chat ────────────────────────────────────────────────────────────────────────────────
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';
import '../../features/chat/presentation/pages/new_chat_page.dart';

// ── Profile ────────────────────────────────────────────────────────────────
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/wallet_page.dart';
import '../../features/profile/presentation/pages/history_page.dart';
import '../../features/profile/presentation/pages/my_listings_page.dart';
import '../../features/profile/presentation/pages/favorites_page.dart';
import '../../features/profile/presentation/pages/support_page.dart';

// ── Notifications ──────────────────────────────────────────────────────────
import '../../features/notification/presentation/pages/notifications_page.dart';

// ── Settings ───────────────────────────────────────────────────────────────
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/privacy_page.dart';
import '../../features/settings/presentation/pages/about_page.dart';

// ── Admin ──────────────────────────────────────────────────────────────────
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';

final GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: RouteNames.splash,
  redirect: (context, state) {
    // Routes publiques (pas de redirection)
    final publicRoutes = [
      RouteNames.splash,
      RouteNames.login,
      RouteNames.register,
      RouteNames.forgotPassword,
      RouteNames.verifyEmail,
      RouteNames.welcome,
      RouteNames.intro,
    ];

    final isPublicRoute = publicRoutes.any((r) =>
        state.matchedLocation == r || state.matchedLocation.startsWith('$r/'));

    // Le splash gère lui-même la redirection, on ne l'intercepte pas
    if (state.matchedLocation == RouteNames.splash) return null;

    try {
      final authState = context.read<AuthCubit>().state;
      final isAuthenticated = authState is AuthAuthenticated;

      // Utilisateur connecté qui essaie d'aller sur login/register → home
      if (isAuthenticated && isPublicRoute) {
        return RouteNames.home;
      }

      // Utilisateur non connecté sur une route protégée → login
      if (!isAuthenticated && !isPublicRoute) {
        return RouteNames.login;
      }
    } catch (_) {
      // BuildContext sans BlocProvider → pas de redirection
    }

    return null;
  },
  routes: [
    // ── Splash ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.splash,
      name: 'splash',
      builder: (context, state) => const SplashPage(),
    ),

    // ── Onboarding ─────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.welcome,
      name: 'welcome',
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: RouteNames.intro,
      name: 'intro',
      builder: (context, state) => const IntroPage(),
    ),

    // ── Auth ───────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.login,
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: RouteNames.register,
      name: 'register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: RouteNames.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: RouteNames.verifyEmail,
      name: 'verifyEmail',
      builder: (context, state) => const VerifyEmailPage(),
    ),

    // ── Main ───────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),

    // ── Catalog ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.catalog,
      name: 'catalog',
      builder: (context, state) => const CatalogPage(),
    ),

    // ── Search ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.search,
      name: 'search',
      builder: (context, state) => const SearchPage(),
    ),

    // ── Filters ──────────────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.filters,
      name: 'filters',
      builder: (context, state) {
        final filters = state.extra as CatalogFilters?;
        return FilterPage(currentFilters: filters);
      },
    ),

    // ── Product detail ─────────────────────────────────────────────────
    GoRoute(
      path: '/product/:id',
      name: 'productDetail',
      builder: (context, state) {
        final productId = state.pathParameters['id']!;
        return ProductDetailPage(productId: productId);
      },
    ),

    // ── Publish ────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.publish,
      name: 'publish',
      builder: (context, state) => const PublishProductPage(),
    ),

    // ── Payment ────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.payment,
      name: 'payment',
      builder: (context, state) {
        final product = state.extra as ProductEntity?;
        return PaymentPage(product: product);
      },
      routes: [
        GoRoute(
          path: 'success',
          name: 'paymentSuccess',
          builder: (context, state) => const PaymentSuccessPage(),
        ),
        GoRoute(
          path: 'failed',
          name: 'paymentFailed',
          builder: (context, state) => const PaymentFailedPage(),
        ),
      ],
    ),

    // ── Orders ─────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.orders,
      name: 'orders',
      builder: (context, state) => const OrdersPage(),
      routes: [
        GoRoute(
          path: ':id/track',
          name: 'orderTracking',
          builder: (context, state) {
            final orderId = state.pathParameters['id']!;
            return OrderTrackingPage(orderId: orderId);
          },
        ),
      ],
    ),

    // ── Chat ───────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.messages,
      name: 'chatList',
      builder: (context, state) => const ChatListPage(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'newChat',
          builder: (context, state) => const NewChatPage(),
        ),
        GoRoute(
          path: ':id',
          name: 'chat',
          builder: (context, state) {
            final chatId = state.pathParameters['id']!;
            return ChatPage(chatId: chatId);
          },
        ),
      ],
    ),

    // ── Profile ────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.profile,
      name: 'profile',
      builder: (context, state) => const ProfilePage(),
      routes: [
        GoRoute(
          path: 'favorites',
          name: 'favorites',
          builder: (context, state) => const FavoritesPage(),
        ),
        GoRoute(
          path: 'support',
          name: 'support',
          builder: (context, state) => const SupportPage(),
        ),
        GoRoute(
          path: 'edit',
          name: 'editProfile',
          builder: (context, state) => const EditProfilePage(),
        ),
        GoRoute(
          path: 'wallet',
          name: 'wallet',
          builder: (context, state) => const WalletPage(),
        ),
        GoRoute(
          path: 'listings',
          name: 'myListings',
          builder: (context, state) => const MyListingsPage(),
        ),
        GoRoute(
          path: 'history',
          name: 'history',
          builder: (context, state) => const HistoryPage(),
        ),
      ],
    ),

    // ── Notifications ──────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.notifications,
      name: 'notifications',
      builder: (context, state) => const NotificationsPage(),
    ),

    // ── Settings ───────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.settings,
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
      routes: [
        GoRoute(
          path: 'privacy',
          name: 'privacy',
          builder: (context, state) => const PrivacyPage(),
        ),
        GoRoute(
          path: 'about',
          name: 'about',
          builder: (context, state) => const AboutPage(),
        ),
      ],
    ),

    // ── Admin ──────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.adminDashboard,
      name: 'adminDashboard',
      builder: (context, state) => const AdminDashboardPage(),
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
            'Page introuvable',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            state.error?.message ?? 'Route inconnue : ${state.uri}',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go(RouteNames.home),
            child: const Text('Retour à l\'accueil'),
          ),
        ],
      ),
    ),
  ),
);
