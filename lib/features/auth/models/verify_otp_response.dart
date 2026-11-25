import 'user_model.dart';

class VerifyOtpResponse {
  final String? token;
  final String? role;
  final bool isAgent;
  final String? agentStatus;
  final String? phoneNumber;
  final String? name;
  final int? age;
  final String? gender;
  final UserModel? user;
  final String message;
  final String status;
  final bool otpVerified;
  final bool isExistingAgent;
  final bool isExistingUser;
  final String nextStep;
  final bool isApproved;
  final bool canCall;
  final int walletBalance;
  final int todayCompletedCalls;
  final int dailyCallTarget;

  const VerifyOtpResponse({
    this.token,
    this.role,
    this.isAgent = false,
    this.agentStatus,
    this.phoneNumber,
    this.name,
    this.age,
    this.gender,
    this.user,
    required this.message,
    required this.status,
    this.otpVerified = false,
    this.isExistingAgent = false,
    this.isExistingUser = false,
    this.nextStep = 'home',
    this.isApproved = false,
    this.canCall = false,
    this.walletBalance = 0,
    this.todayCompletedCalls = 0,
    this.dailyCallTarget = 50,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    if (json['user'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    } else {
      parsedUser = UserModel.fromJson(json);
    }

    return VerifyOtpResponse(
      token: json['token']?.toString(),
      role: json['role']?.toString(),
      isAgent: json['is_agent'] == true,
      agentStatus: json['agent_status']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      name: json['name']?.toString() ?? parsedUser.name,
      age: (json['age'] as num?)?.toInt() ?? parsedUser.age,
      gender: json['gender']?.toString() ?? parsedUser.gender,
      user: parsedUser,
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      otpVerified: json['otp_verified'] == true,
      isExistingAgent: json['is_existing_agent'] == true,
      isExistingUser: json['is_existing_user'] == true,
      nextStep: json['next_step']?.toString() ?? 'home',
      isApproved: json['is_approved'] == true,
      canCall: json['can_call'] == true,
      walletBalance: (json['wallet_balance'] as num?)?.toInt() ?? 0,
      todayCompletedCalls: (json['today_completed_calls'] as num?)?.toInt() ?? 0,
      dailyCallTarget: (json['daily_call_target'] as num?)?.toInt() ?? 50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'role': role,
      'is_agent': isAgent,
      'agent_status': agentStatus,
      'phone_number': phoneNumber,
      'name': name,
      'age': age,
      'gender': gender,
      'user': user?.toJson(),
      'message': message,
      'status': status,
      'otp_verified': otpVerified,
      'is_existing_agent': isExistingAgent,
      'is_existing_user': isExistingUser,
      'next_step': nextStep,
      'is_approved': isApproved,
      'can_call': canCall,
      'wallet_balance': walletBalance,
      'today_completed_calls': todayCompletedCalls,
      'daily_call_target': dailyCallTarget,
    };
  }
}
