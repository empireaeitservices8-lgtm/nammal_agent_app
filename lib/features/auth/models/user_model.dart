class UserModel {
  final String id;
  final String? phoneNumber;
  final String? name;
  final String? email;
  final String? gender;
  final String? avatar;
  final int coins;
  final bool isProfileComplete;

  UserModel({
    required this.id,
    this.phoneNumber,
    this.name,
    this.email,
    this.gender,
    this.avatar,
    this.coins = 0,
    this.isProfileComplete = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      phoneNumber: json['phone_number'] ?? json['phone'],
      name: json['name'] ?? json['username'],
      email: json['email'],
      gender: json['gender'],
      avatar: json['avatar'],
      coins: json['coins'] is int
          ? json['coins']
          : int.tryParse(json['coins']?.toString() ?? '0') ?? 0,
      isProfileComplete: json['is_profile_complete'] ??
          (json['name'] != null && json['name'].toString().isNotEmpty),
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
    );
  }
}
