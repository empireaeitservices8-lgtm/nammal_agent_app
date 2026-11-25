class ProfileModel {
  final String id;
  final String name;
  final String? phoneNumber;
  final String? email;
  final String? gender;
  final String? avatar;
  final int totalCalls;

  ProfileModel({
    required this.id,
    required this.name,
    this.phoneNumber,
    this.email,
    this.gender,
    this.avatar,
    this.totalCalls = 0,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['username'] ?? 'User',
      phoneNumber: json['phone_number'] ?? json['phone'],
      email: json['email'],
      gender: json['gender'],
      avatar: json['avatar'],
      totalCalls: json['total_calls'] ?? 0,
    );
  }
}
