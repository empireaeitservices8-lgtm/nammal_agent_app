import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../viewmodels/splash_viewmodel.dart';
import '../widgets/nammal_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _progressAnimation = Tween<double>(begin: 0.05, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _progressController.forward();

    // Trigger initialization in ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashViewModelProvider.notifier).initializeApp();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ViewModel state for navigation
    ref.listen<SplashState>(splashViewModelProvider, (previous, next) {
      if (next.isReady) {
        switch (next.target) {
          case SplashNavigationTarget.home:
            context.go(AppRoutes.home);
            break;
          case SplashNavigationTarget.onboarding:
            context.go(AppRoutes.onboarding);
            break;
          case SplashNavigationTarget.login:
          default:
            context.go(AppRoutes.login);
            break;
        }
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.screenGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Centered App Logo Card
              const NammalLogoCard(size: 175),

              const Spacer(flex: 4),

              // Bottom Progress Bar & Version Tag
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Slim Progress Bar matching screenshot
                    Container(
                      width: 215,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E3FC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 215 * _progressAnimation.value,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Version Tag
                    const Text(
                      'V1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.2,
                        color: Color(0xFFB5B3C7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
