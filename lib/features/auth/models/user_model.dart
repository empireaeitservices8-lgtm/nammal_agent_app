class UserModel {
  final String id;
  final String? username;
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
  final String? bio;
  final String? dateOfBirth;
  final String? idType;
  final String? idNumber;

  UserModel({
    required this.id,
    this.username,
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
    this.bio,
    this.dateOfBirth,
    this.idType,
    this.idNumber,
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
      username:
          userMap['username']?.toString() ?? json['username']?.toString(),
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
      bio: profileMap?['bio']?.toString() ??
          userMap['bio']?.toString() ??
          json['bio']?.toString(),
      dateOfBirth: profileMap?['date_of_birth']?.toString() ??
          profileMap?['date_of_birth_display']?.toString() ??
          userMap['date_of_birth']?.toString() ??
          json['date_of_birth']?.toString() ??
          json['dob']?.toString(),
      idType: profileMap?['id_type']?.toString() ??
          userMap['id_type']?.toString() ??
          json['id_type']?.toString(),
      idNumber: profileMap?['id_number']?.toString() ??
          userMap['id_number']?.toString() ??
          json['id_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
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
      'bio': bio,
      'date_of_birth': dateOfBirth,
      'id_type': idType,
      'id_number': idNumber,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
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
    String? bio,
    String? dateOfBirth,
    String? idType,
    String? idNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
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
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
    );
  }
}
