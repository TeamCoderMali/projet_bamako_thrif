/// ─── Bamako Thrift — GoRouter Configuration ───────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_names.dart';

// ── Onboarding ─────────────────────────────────────────────────────────────
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/onboarding/presentation/pages/intro_page.dart';

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

// ── Orders ─────────────────────────────────────────────────────────────────
import '../../features/order/presentation/pages/orders_page.dart';
import '../../features/order/presentation/pages/order_tracking_page.dart';

// ── Chat ───────────────────────────────────────────────────────────────────
import '../../features/chat/presentation/pages/chat_list_page.dart';
import '../../features/chat/presentation/pages/chat_page.dart';

// ── Profile ────────────────────────────────────────────────────────────────
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/profile/presentation/pages/wallet_page.dart';
import '../../features/profile/presentation/pages/history_page.dart';

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
  initialLocation: RouteNames.welcome,
  routes: [
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

    // ── Catalog ────────────────────────────────────────────────────────
    GoRoute(
      path: RouteNames.catalog,
      name: 'catalog',
      builder: (context, state) => const CatalogPage(),
      routes: [
        GoRoute(
          path: 'search',
          name: 'search',
          builder: (context, state) => const SearchPage(),
        ),
        GoRoute(
          path: 'filters',
          name: 'filters',
          builder: (context, state) => const FilterPage(),
        ),
      ],
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
      builder: (context, state) => const PaymentPage(),
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
