class IncomingCallModel {
  final String callId;
  final String callerName;
  final String callerPhone;
  final String? callerAvatar;
  final String? channelName;
  final String? agoraToken;
  final String callType; // 'audio' or 'video'
  final Map<String, dynamic> extra;

  const IncomingCallModel({
    required this.callId,
    required this.callerName,
    required this.callerPhone,
    this.callerAvatar,
    this.channelName,
    this.agoraToken,
    this.callType = 'audio',
    this.extra = const {},
  });

  String get maskedPhoneNumber {
    final clean = callerPhone.replaceAll(' ', '').trim();
    if (clean.isEmpty) return '+91 ••••• •••••';
    if (clean.startsWith('+91')) {
      if (clean.length >= 8) {
        final prefix = clean.substring(0, 8);
        return '$prefix •••••';
      }
      return '$clean •••••';
    }
    if (clean.length >= 5) {
      final prefix = clean.substring(0, 5);
      return '+91 $prefix •••••';
    }
    return '+91 $clean •••••';
  }

  factory IncomingCallModel.fromJson(Map<String, dynamic> json) {
    return IncomingCallModel(
      callId: json['call_id']?.toString() ??
          json['id']?.toString() ??
          json['channel']?.toString() ??
          '',
      callerName: json['caller_name']?.toString() ??
          json['name']?.toString() ??
          json['user_name']?.toString() ??
          'Incoming Caller',
      callerPhone: json['caller_phone']?.toString() ??
          json['phone_number']?.toString() ??
          json['phone']?.toString() ??
          '',
      callerAvatar: json['caller_avatar']?.toString() ??
          json['avatar']?.toString() ??
          json['profile_picture']?.toString(),
      channelName: json['channel_name']?.toString() ??
          json['channel']?.toString(),
      agoraToken: json['agora_token']?.toString() ??
          json['token']?.toString(),
      callType: json['call_type']?.toString() ?? 'audio',
      extra: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'caller_name': callerName,
      'caller_phone': callerPhone,
      'caller_avatar': callerAvatar,
      'channel_name': channelName,
      'agora_token': agoraToken,
      'call_type': callType,
      'extra': extra,
    };
  }

  IncomingCallModel copyWith({
    String? callId,
    String? callerName,
    String? callerPhone,
    String? callerAvatar,
    String? channelName,
    String? agoraToken,
    String? callType,
    Map<String, dynamic>? extra,
  }) {
    return IncomingCallModel(
      callId: callId ?? this.callId,
      callerName: callerName ?? this.callerName,
      callerPhone: callerPhone ?? this.callerPhone,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      channelName: channelName ?? this.channelName,
      agoraToken: agoraToken ?? this.agoraToken,
      callType: callType ?? this.callType,
      extra: extra ?? this.extra,
    );
  }
}
