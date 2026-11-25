class HandledCallModel {
  final String id;
  final String callerName;
  final String initials;
  final String status; // 'Completed' or 'Resolved'
  final String timeAgo; // e.g. 'Today, 03:45 PM'
  final String duration; // e.g. '12m 30s'
  final int coins; // e.g. 45
  final double earnings; // e.g. 180.0

  const HandledCallModel({
    required this.id,
    required this.callerName,
    required this.initials,
    this.status = 'Completed',
    required this.timeAgo,
    required this.duration,
    required this.coins,
    required this.earnings,
  });

  factory HandledCallModel.fromJson(Map<String, dynamic> json) {
    final caller = json['caller_name'] ??
        json['user_name'] ??
        json['name'] ??
        json['caller'] ??
        'Caller';
    final nameStr = caller.toString();
    final initials = json['initials'] ??
        (nameStr.isNotEmpty
            ? nameStr
                .split(' ')
                .where((part) => part.isNotEmpty)
                .map((part) => part[0])
                .take(2)
                .join()
                .toUpperCase()
            : 'CL');

    return HandledCallModel(
      id: json['id']?.toString() ?? '',
      callerName: nameStr,
      initials: initials,
      status: json['status']?.toString() ?? 'Completed',
      timeAgo: json['time_ago']?.toString() ??
          json['time']?.toString() ??
          json['created_at']?.toString() ??
          'Today',
      duration: json['duration']?.toString() ??
          json['duration_formatted']?.toString() ??
          '10m 00s',
      coins: (json['coins'] as num?)?.toInt() ?? 30,
      earnings: (json['earnings'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          120.0,
    );
  }

  static List<HandledCallModel> get sampleCalls => const [
        HandledCallModel(
          id: '1',
          callerName: 'Ananya Deshmukh',
          initials: 'AD',
          status: 'Completed',
          timeAgo: 'Today, 03:45 PM',
          duration: '12m 30s',
          coins: 45,
          earnings: 180.0,
        ),
        HandledCallModel(
          id: '2',
          callerName: 'Vikramaditya Rao',
          initials: 'VR',
          status: 'Completed',
          timeAgo: 'Today, 02:15 PM',
          duration: '08m 10s',
          coins: 30,
          earnings: 120.0,
        ),
        HandledCallModel(
          id: '3',
          callerName: 'Meera Krishnan',
          initials: 'MK',
          status: 'Completed',
          timeAgo: 'Today, 11:30 AM',
          duration: '18m 45s',
          coins: 70,
          earnings: 280.0,
        ),
        HandledCallModel(
          id: '4',
          callerName: 'Karthik Subramanian',
          initials: 'KS',
          status: 'Resolved',
          timeAgo: 'Yesterday, 06:10 PM',
          duration: '04m 20s',
          coins: 15,
          earnings: 60.0,
        ),
      ];
}
