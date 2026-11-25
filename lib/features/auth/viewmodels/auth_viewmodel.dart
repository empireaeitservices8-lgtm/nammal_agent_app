import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/auth_state.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<bool> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _repository.sendOtp(phoneNumber);
      state = state.copyWith(
        status: AuthStatus.initial,
        phoneNumber: phoneNumber,
        isOtpSent: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String otp, {String? fcmToken}) async {
    if (state.phoneNumber == null) return false;
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.verifyOtp(
        phoneNumber: state.phoneNumber!,
        otp: otp,
        fcmToken: fcmToken,
      );

      final nextStatus = user.isProfileComplete
          ? AuthStatus.authenticated
          : AuthStatus.needsOnboarding;

      state = state.copyWith(status: nextStatus, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> completeOnboarding({
    required String name,
    required String gender,
    String? email,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repository.completeOnboarding(
        name: name,
        gender: gender,
        email: email,
      );
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
