import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../features/auth/services/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/password_success_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/home/screens/search_screen.dart';
import '../features/home/screens/product_screen.dart';
import '../features/listing/screens/listing_detail_screen.dart';
import '../features/listing/screens/create_listing_screen.dart';
import '../features/listing/screens/edit_listing_screen.dart';
import '../features/chat/screens/conversations_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/favorites_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/home/screens/main_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/notification/notification_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/home/screens/category_listing_screen.dart';
import '../features/listing/screens/camera_picker_screen.dart';
import '../features/listing/screens/listing_shipping_screen.dart';
import '../features/listing/screens/address_screen.dart';
import '../features/listing/screens/add_address_screen.dart';
import '../features/listing/screens/listing_success_screen.dart';
import '../features/profile/screens/partner_profile_screen.dart';
import '../features/orders/screens/purchases_screen.dart';
import '../features/orders/screens/sales_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../features/wallet/transaction_history_screen.dart';
import '../features/support/terms_screen.dart';
import '../features/support/buyer_protection_screen.dart';
import '../features/support/feedback_screen.dart';
import '../features/support/contact_screen.dart';
import '../features/support/support_chat_screen.dart';
import '../features/profile/screens/identity_verification_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/listing/screens/my_listings_screen.dart';
import '../features/orders/screens/checkout_screen.dart';
import '../features/orders/screens/order_success_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/admin/admin_shell.dart';

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider auth) => GoRouter(
      navigatorKey: _rootKey,
      initialLocation: '/splash',
      redirect: (context, state) {
        final loc = state.matchedLocation;
        if (loc == '/splash' || loc == '/onboarding') return null;
        final loggedIn = auth.isLoggedIn;
        final isAdmin = auth.user?.isAdmin ?? false;
        final onAuth = loc.startsWith('/login') || loc.startsWith('/register');
        // Redirect admin sang /admin — nhưng cho phép xem các public route
        final adminExempt = loc.startsWith('/listing/') ||
            loc.startsWith('/partner/') ||
            loc.startsWith('/profile/');
        if (loggedIn && isAdmin && !loc.startsWith('/admin') && !adminExempt) return '/admin';
        // Các route công khai — không cần đăng nhập
        final publicRoutes = [
          '/',
          '/search',
          '/products',
          '/category',
          '/otp',
          '/forgot-password',
          '/reset-password',
          '/password-success',
          '/register-success',
        ];
        final isPublic = publicRoutes.any((r) => loc == r || loc.startsWith(r)) ||
            (loc.startsWith('/listing/') && !loc.endsWith('/edit'));
        if (!loggedIn && !onAuth && !isPublic) return '/onboarding';
        if (loggedIn && onAuth) return isAdmin ? '/admin' : '/';
        return null;
      },
      refreshListenable: auth,
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(
          path: '/otp',
          builder: (_, state) {
            // Nhận từ extra (register flow) hoặc query params (forgot flow)
            final extra = state.extra as Map<String, dynamic>?;
            final email = extra?['email'] as String?
                ?? state.uri.queryParameters['email'] ?? '';
            final mode = extra?['mode'] as String?
                ?? state.uri.queryParameters['mode'] ?? 'forgot';
            return OtpScreen(
              email: email,
              mode: mode,
              registerData: extra,
            );
          },
        ),
        GoRoute(path: '/reset-password', builder: (_, state) {
          final email = (state.extra as Map<String, dynamic>?)?['email'] as String? ?? '';
          return ResetPasswordScreen(email: email);
        }),
        GoRoute(path: '/password-success', builder: (_, __) => const PasswordSuccessScreen()),
        GoRoute(path: '/register-success', builder: (_, __) => const PasswordSuccessScreen(mode: 'register')),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        ShellRoute(
          builder: (context, state, child) => MainScreen(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/search', builder: (_, state) {
              final q = state.uri.queryParameters['q'];
              final cat = state.uri.queryParameters['category'];
              return SearchScreen(initialKeyword: q, initialCategory: cat);
            }),
            GoRoute(path: '/products', builder: (_, __) => const ProductScreen()),
            GoRoute(path: '/conversations', builder: (_, __) => const ConversationsScreen()),
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
        // Camera → Create listing flow
        GoRoute(path: '/camera', builder: (_, __) => const CameraPickerScreen()),
        GoRoute(
          path: '/create-listing',
          builder: (_, state) {
            final extra = state.extra;
            if (extra is Map<String, dynamic>) {
              return CreateListingScreen(
                initialPaths: (extra['paths'] as List?)?.cast<String>() ?? [],
                initialXFiles: (extra['xfiles'] as List?)?.cast<XFile>() ?? [],
                initialVideoFile: extra['videoFile'] as XFile?,
              );
            }
            // fallback: extra là List<String> (legacy)
            final paths = extra as List<String>? ?? [];
            return CreateListingScreen(initialPaths: paths);
          },
        ),
        GoRoute(path: '/address', builder: (_, __) => const AddressScreen()),
        GoRoute(path: '/add-address', builder: (_, __) => const AddAddressScreen()),
        GoRoute(
          path: '/listing-success',
          builder: (_, state) {
            final id = state.uri.queryParameters['id'];
            return ListingSuccessScreen(listingId: id != null ? int.tryParse(id) : null);
          },
        ),
        GoRoute(
          path: '/listing-shipping',
          builder: (_, state) {
            final data = state.extra as Map<String, dynamic>? ?? {};
            return ListingShippingScreen(
              price: (data['price'] as num?)?.toDouble() ?? 0,
              listingData: data,
            );
          },
        ),
        // Listing detail & edit — dùng nested để tránh conflict
        GoRoute(
          path: '/listing/:id',
          builder: (_, state) {
            final id = int.tryParse(state.pathParameters['id']!);
            if (id == null) return const SizedBox();
            return ListingDetailScreen(id: id);
          },
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) {
                final id = int.parse(state.pathParameters['id']!);
                return EditListingScreen(id: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/chat/:conversationId',
          builder: (_, state) => ChatScreen(
              conversationId: int.parse(state.pathParameters['conversationId']!)),
        ),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationScreen()),
        GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
        GoRoute(path: '/favorites', builder: (_, __) => const FavoritesScreen()),
        GoRoute(
          path: '/category',
          builder: (_, state) => CategoryListingScreen(
            category: state.uri.queryParameters['category'],
            keyword: state.uri.queryParameters['q'],
          ),
        ),
        GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
        GoRoute(path: '/purchases', builder: (_, __) => const PurchasesScreen()),
        GoRoute(path: '/sales', builder: (_, __) => const SalesScreen()),
        GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
        GoRoute(path: '/wallet/history', builder: (_, __) => const TransactionHistoryScreen()),
        GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
        GoRoute(path: '/buyer-protection', builder: (_, __) => const BuyerProtectionScreen()),
        GoRoute(path: '/feedback', builder: (_, __) => const FeedbackScreen()),
        GoRoute(path: '/contact', builder: (_, __) => const ContactScreen()),
        GoRoute(path: '/support', builder: (_, __) => const SupportChatScreen()),
        GoRoute(path: '/identity-verification', builder: (_, __) => const IdentityVerificationScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/my-listings', builder: (_, __) => const MyListingsScreen()),
        GoRoute(
          path: '/order-success',
          builder: (_, state) {
            final data = state.extra as Map<String, dynamic>;
            return OrderSuccessScreen(
              order: data['order'],
              payMethod: data['payMethod'] as String,
            );
          },
        ),
        GoRoute(
          path: '/order/:id',
          builder: (_, state) {
            final data = state.extra as Map<String, dynamic>;
            return OrderDetailScreen(
              order: data['order'],
              isBuyer: data['isBuyer'] as bool? ?? true,
            );
          },
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, state) {
            final data = state.extra as Map<String, dynamic>;
            return CheckoutScreen(
              listing: data['listing'],
              quantity: data['quantity'] as int? ?? 1,
            );
          },
        ),
        GoRoute(
          path: '/profile/:userId',
          builder: (_, state) =>
              ProfileScreen(userId: int.tryParse(state.pathParameters['userId']!)),
        ),
        GoRoute(
          path: '/partner/:userId',
          builder: (_, state) {
            final id = int.tryParse(state.pathParameters['userId']!);
            if (id == null) return const SizedBox();
            return PartnerProfileScreen(userId: id);
          },
        ),
      ],
    );
