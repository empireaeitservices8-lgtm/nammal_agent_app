import 'package:go_router/go_router.dart';
import '../../features/auth/views/splash_screen.dart';
import '../../features/auth/views/phone_login_screen.dart';
import '../../features/auth/views/otp_verification_screen.dart';
import '../../features/auth/views/agent_registration_screen.dart';
import '../../features/auth/views/user_onboarding_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/wallet/views/wallet_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/views/edit_profile_screen.dart';
import '../../features/call/models/incoming_call_model.dart';
import '../../features/call/views/incoming_call_screen.dart';
import '../../features/call/views/active_call_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String onboarding = '/onboarding';
  static const String registration = '/registration';
  static const String home = '/home';
  static const String wallet = '/wallet';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String incomingCall = '/incoming-call';
  static const String activeCall = '/active-call';
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
      builder: (context, state) => const AgentRegistrationScreen(),
    ),
    GoRoute(
      path: AppRoutes.registration,
      name: 'registration',
      builder: (context, state) => const AgentRegistrationScreen(),
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
    GoRoute(
      path: AppRoutes.editProfile,
      name: 'editProfile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.incomingCall,
      name: 'incomingCall',
      builder: (context, state) {
        final extra = state.extra;
        IncomingCallModel? callModel;
        if (extra is IncomingCallModel) {
          callModel = extra;
        } else if (extra is Map<String, dynamic>) {
          callModel = IncomingCallModel.fromJson(extra);
        }
        return IncomingCallScreen(callModel: callModel);
      },
    ),
    GoRoute(
      path: AppRoutes.activeCall,
      name: 'activeCall',
      builder: (context, state) {
        final extra = state.extra;
        IncomingCallModel? callModel;
        if (extra is IncomingCallModel) {
          callModel = extra;
        } else if (extra is Map<String, dynamic>) {
          callModel = IncomingCallModel.fromJson(extra);
        }
        return ActiveCallScreen(callModel: callModel);
      },
    ),
  ],
);
