import 'user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  needsOnboarding,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final String? phoneNumber;
  final bool isOtpSent;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.phoneNumber,
    this.isOtpSent = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? phoneNumber,
    bool? isOtpSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOtpSent: isOtpSent ?? this.isOtpSent,
    );
  }
}
