class SendOtpResponse {
  final String status;
  final String message;
  final String phoneNumber;
  final String? otp;
  final int otpLength;
  final int resendAfter;
  final bool isExistingUser;

  const SendOtpResponse({
    required this.status,
    required this.message,
    required this.phoneNumber,
    this.otp,
    this.otpLength = 4,
    this.resendAfter = 45,
    this.isExistingUser = false,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      otp: json['otp']?.toString(),
      otpLength: (json['otp_length'] as num?)?.toInt() ?? 4,
      resendAfter: (json['resend_after'] as num?)?.toInt() ?? 45,
      isExistingUser: json['is_existing_user'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'phone_number': phoneNumber,
      if (otp != null) 'otp': otp,
      'otp_length': otpLength,
      'resend_after': resendAfter,
      'is_existing_user': isExistingUser,
    };
  }
}
