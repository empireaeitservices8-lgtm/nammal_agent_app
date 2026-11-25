import 'package:go_router/go_router.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/phone_login_screen.dart';
import '../../features/auth/views/otp_verification_screen.dart';
import '../../features/auth/views/user_onboarding_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/wallet/views/wallet_screen.dart';
import '../../features/profile/views/profile_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String wallet = '/wallet';
  static const String profile = '/profile';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const PhoneLoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.otp,
      name: 'otp',
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '+91 0000000000';
        return OtpVerificationScreen(phoneNumber: phoneNumber);
      },
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const UserOnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.wallet,
      name: 'wallet',
      builder: (context, state) => const WalletScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
