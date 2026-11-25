class UserModel {
  final String id;
  final String? phoneNumber;
  final String? name;
  final String? email;
  final String? gender;
  final String? avatar;
  final int coins;
  final bool isProfileComplete;
  final int? age;
  final String? role;
  final bool isAgent;
  final String? agentStatus;
  final bool isApproved;
  final bool canCall;
  final int walletBalance;
  final int todayCompletedCalls;
  final int dailyCallTarget;

  UserModel({
    required this.id,
    this.phoneNumber,
    this.name,
    this.email,
    this.gender,
    this.avatar,
    this.coins = 0,
    this.isProfileComplete = false,
    this.age,
    this.role,
    this.isAgent = false,
    this.agentStatus,
    this.isApproved = false,
    this.canCall = false,
    this.walletBalance = 0,
    this.todayCompletedCalls = 0,
    this.dailyCallTarget = 50,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    final profileMap = userMap['profile'] is Map<String, dynamic>
        ? userMap['profile'] as Map<String, dynamic>
        : (json['profile'] is Map<String, dynamic>
              ? json['profile'] as Map<String, dynamic>
              : null);

    final rawName =
        userMap['name'] ??
        profileMap?['name'] ??
        json['name'] ??
        userMap['username'];

    return UserModel(
      id:
          userMap['id']?.toString() ??
          json['id']?.toString() ??
          json['user_id']?.toString() ??
          '',
      phoneNumber:
          userMap['phone_number']?.toString() ??
          profileMap?['phone_number']?.toString() ??
          json['phone_number']?.toString() ??
          userMap['phone']?.toString(),
      name: rawName?.toString(),
      email: userMap['email']?.toString() ?? json['email']?.toString(),
      gender:
          userMap['gender']?.toString() ??
          profileMap?['gender']?.toString() ??
          json['gender']?.toString(),
      avatar:
          profileMap?['profile_picture']?.toString() ??
          userMap['avatar']?.toString() ??
          json['avatar']?.toString(),
      coins: userMap['coins'] is int
          ? userMap['coins'] as int
          : int.tryParse(userMap['coins']?.toString() ?? '0') ?? 0,
      isProfileComplete:
          json['is_profile_complete'] ??
          (rawName != null && rawName.toString().trim().isNotEmpty),
      age: userMap['age'] is int
          ? userMap['age'] as int
          : int.tryParse(
              userMap['age']?.toString() ?? json['age']?.toString() ?? '',
            ),
      role: userMap['role']?.toString() ?? json['role']?.toString(),
      isAgent: userMap['is_agent'] == true || json['is_agent'] == true,
      agentStatus:
          userMap['agent_status']?.toString() ??
          json['agent_status']?.toString(),
      isApproved: json['is_approved'] == true || userMap['is_approved'] == true,
      canCall: json['can_call'] == true || userMap['can_call'] == true,
      walletBalance:
          (json['wallet_balance'] as num?)?.toInt() ??
          (userMap['wallet_balance'] as num?)?.toInt() ??
          0,
      todayCompletedCalls:
          (json['today_completed_calls'] as num?)?.toInt() ??
          (userMap['today_completed_calls'] as num?)?.toInt() ??
          0,
      dailyCallTarget:
          (json['daily_call_target'] as num?)?.toInt() ??
          (userMap['daily_call_target'] as num?)?.toInt() ??
          50,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'email': email,
      'gender': gender,
      'avatar': avatar,
      'coins': coins,
      'is_profile_complete': isProfileComplete,
      'age': age,
      'role': role,
      'is_agent': isAgent,
      'agent_status': agentStatus,
      'is_approved': isApproved,
      'can_call': canCall,
      'wallet_balance': walletBalance,
      'today_completed_calls': todayCompletedCalls,
      'daily_call_target': dailyCallTarget,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    String? gender,
    String? avatar,
    int? coins,
    bool? isProfileComplete,
    int? age,
    String? role,
    bool? isAgent,
    String? agentStatus,
    bool? isApproved,
    bool? canCall,
    int? walletBalance,
    int? todayCompletedCalls,
    int? dailyCallTarget,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      avatar: avatar ?? this.avatar,
      coins: coins ?? this.coins,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      age: age ?? this.age,
      role: role ?? this.role,
      isAgent: isAgent ?? this.isAgent,
      agentStatus: agentStatus ?? this.agentStatus,
      isApproved: isApproved ?? this.isApproved,
      canCall: canCall ?? this.canCall,
      walletBalance: walletBalance ?? this.walletBalance,
      todayCompletedCalls: todayCompletedCalls ?? this.todayCompletedCalls,
      dailyCallTarget: dailyCallTarget ?? this.dailyCallTarget,
    );
  }
}
