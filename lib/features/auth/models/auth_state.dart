import 'agent_register_response.dart';
import 'send_otp_response.dart';
import 'user_model.dart';
import 'verify_otp_response.dart';

export 'agent_register_response.dart';
export 'send_otp_response.dart';
export 'user_model.dart';
export 'verify_otp_response.dart';

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
  final SendOtpResponse? otpResponse;
  final VerifyOtpResponse? verifyOtpResponse;
  final AgentRegisterResponse? registerResponse;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.phoneNumber,
    this.isOtpSent = false,
    this.otpResponse,
    this.verifyOtpResponse,
    this.registerResponse,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    String? phoneNumber,
    bool? isOtpSent,
    SendOtpResponse? otpResponse,
    VerifyOtpResponse? verifyOtpResponse,
    AgentRegisterResponse? registerResponse,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      otpResponse: otpResponse ?? this.otpResponse,
      verifyOtpResponse: verifyOtpResponse ?? this.verifyOtpResponse,
      registerResponse: registerResponse ?? this.registerResponse,
    );
  }
}
