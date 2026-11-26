import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../models/auth_state.dart';
import '../models/send_otp_response.dart';
import '../models/verify_otp_response.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState();
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);
  NotificationService get _notificationService =>
      ref.read(notificationServiceProvider);

  Future<SendOtpResponse?> sendOtp(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repository.sendOtp(phoneNumber);
      state = state.copyWith(
        status: AuthStatus.initial,
        phoneNumber: response.phoneNumber.isNotEmpty
            ? response.phoneNumber
            : phoneNumber,
        isOtpSent: true,
        otpResponse: response,
      );
      return response;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<VerifyOtpResponse?> verifyOtp({
    required String otp,
    String? phoneNumber,
    String? fcmToken,
  }) async {
    final phoneToVerify = phoneNumber ?? state.phoneNumber;
    if (phoneToVerify == null || phoneToVerify.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Phone number is missing',
      );
      return null;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final token = fcmToken ?? await _notificationService.getFCMToken();
      final response = await _repository.verifyOtp(
        phoneNumber: phoneToVerify,
        otp: otp,
        fcmToken: token,
      );

      final nextStatus =
          (response.nextStep == 'onboarding' ||
              response.user?.isProfileComplete == false)
          ? AuthStatus.needsOnboarding
          : AuthStatus.authenticated;

      state = state.copyWith(
        status: nextStatus,
        user: response.user,
        verifyOtpResponse: response,
      );
      return response;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  Future<bool> registerAgent({
    required String name,
    required String gender,
    required String phoneNumber,
    required String age,
    required String dateOfBirth,
    required String idType,
    required String idNumber,
    required String jurisdiction,
    String? idPhotoPath,
    String? fcmToken,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final token = fcmToken ?? await _notificationService.getFCMToken();
      final registerResponse = await _repository.registerAgent(
        name: name,
        gender: gender,
        phoneNumber: phoneNumber,
        age: age,
        dateOfBirth: dateOfBirth,
        idType: idType,
        idNumber: idNumber,
        jurisdiction: jurisdiction,
        idPhotoPath: idPhotoPath,
        fcmToken: token,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: registerResponse.user,
        registerResponse: registerResponse,
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

  Future<bool> completeOnboarding({
    required String name,
    required String gender,
    String? email,
  }) async {
    return registerAgent(
      name: name,
      gender: gender,
      phoneNumber: state.phoneNumber ?? '',
      age: '18',
      dateOfBirth: '',
      idType: 'Aadhaar Card',
      idNumber: '',
      jurisdiction: '',
    );
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      await _notificationService.deleteFCMToken();
    } catch (_) {}
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authViewModelProvider = NotifierProvider<AuthViewModel, AuthState>(
  AuthViewModel.new,
);
