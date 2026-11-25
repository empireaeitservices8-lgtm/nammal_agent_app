class AgentModel {
  final String id;
  final String name;
  final String? avatar;
  final String? bio;
  final double ratePerMinute;
  final bool isOnline;
  final double rating;
  final int totalCalls;
  final List<String> languages;

  AgentModel({
    required this.id,
    required this.name,
    this.avatar,
    this.bio,
    this.ratePerMinute = 10.0,
    this.isOnline = false,
    this.rating = 4.8,
    this.totalCalls = 0,
    this.languages = const ['Tamil', 'English'],
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) {
    return AgentModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['username'] ?? 'Agent',
      avatar: json['avatar'] ?? json['profile_pic'],
      bio: json['bio'] ?? json['description'],
      ratePerMinute: (json['rate_per_minute'] ?? json['coins_per_min'] ?? 10)
          .toDouble(),
      isOnline: json['is_online'] == true || json['status'] == 'online',
      rating: (json['rating'] ?? 4.8).toDouble(),
      totalCalls: json['total_calls'] ?? 0,
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ??
          ['Tamil', 'English'],
    );
  }
}
