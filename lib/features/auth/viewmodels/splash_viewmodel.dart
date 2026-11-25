import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/storage_service.dart';
import '../repositories/auth_repository.dart';

enum SplashNavigationTarget { initial, home, login, onboarding }

class SplashState {
  final SplashNavigationTarget target;
  final double progress;
  final bool isReady;

  const SplashState({
    this.target = SplashNavigationTarget.initial,
    this.progress = 0.0,
    this.isReady = false,
  });

  SplashState copyWith({
    SplashNavigationTarget? target,
    double? progress,
    bool? isReady,
  }) {
    return SplashState(
      target: target ?? this.target,
      progress: progress ?? this.progress,
      isReady: isReady ?? this.isReady,
    );
  }
}

class SplashViewModel extends Notifier<SplashState> {
  @override
  SplashState build() {
    return const SplashState();
  }

  Future<void> initializeApp() async {
    final storageService = ref.read(storageServiceProvider);
    final authRepository = ref.read(authRepositoryProvider);

    state = state.copyWith(progress: 0.20);
    await storageService.init();

    state = state.copyWith(progress: 0.50);
    await Future.delayed(const Duration(milliseconds: 350));

    state = state.copyWith(progress: 0.80);
    final hasSession = await authRepository.checkSession();
    final isNewUser = storageService.isNewUser();

    SplashNavigationTarget nextTarget;
    if (hasSession) {
      nextTarget = isNewUser
          ? SplashNavigationTarget.onboarding
          : SplashNavigationTarget.home;
    } else {
      nextTarget = SplashNavigationTarget.login;
    }

    state = state.copyWith(progress: 1.0);
    await Future.delayed(const Duration(milliseconds: 300));

    state = state.copyWith(target: nextTarget, isReady: true);
  }
}

final splashViewModelProvider =
    NotifierProvider.autoDispose<SplashViewModel, SplashState>(
  SplashViewModel.new,
);
