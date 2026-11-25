class TaskProgressModel {
  final int completed;
  final int target;
  final double progressPercentage;

  const TaskProgressModel({
    this.completed = 0,
    this.target = 0,
    this.progressPercentage = 0.0,
  });

  factory TaskProgressModel.fromJson(Map<String, dynamic> json) {
    return TaskProgressModel(
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      target: (json['target'] as num?)?.toInt() ?? 0,
      progressPercentage:
          (json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'target': target,
      'progress_percentage': progressPercentage,
    };
  }
}

class TasksModel {
  final TaskProgressModel daily;
  final TaskProgressModel weekly;
  final TaskProgressModel monthly;

  const TasksModel({
    this.daily = const TaskProgressModel(),
    this.weekly = const TaskProgressModel(),
    this.monthly = const TaskProgressModel(),
  });

  factory TasksModel.fromJson(Map<String, dynamic> json) {
    return TasksModel(
      daily: json['daily'] is Map<String, dynamic>
          ? TaskProgressModel.fromJson(json['daily'] as Map<String, dynamic>)
          : const TaskProgressModel(),
      weekly: json['weekly'] is Map<String, dynamic>
          ? TaskProgressModel.fromJson(json['weekly'] as Map<String, dynamic>)
          : const TaskProgressModel(),
      monthly: json['monthly'] is Map<String, dynamic>
          ? TaskProgressModel.fromJson(json['monthly'] as Map<String, dynamic>)
          : const TaskProgressModel(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily': daily.toJson(),
      'weekly': weekly.toJson(),
      'monthly': monthly.toJson(),
    };
  }
}

class AgentDetailsModel {
  final String username;
  final String agentStatus;
  final bool isApproved;
  final bool canCall;
  final int coinsEarned;
  final double walletBalance;
  final double totalEarnings;
  final double todayEarnings;
  final int totalDurationSeconds;
  final int todayDurationSeconds;
  final String totalDurationFormatted;
  final String todayDurationFormatted;
  final int callsCompleted;
  final double successRate;
  final double agentRating;

  const AgentDetailsModel({
    this.username = '',
    this.agentStatus = 'pending',
    this.isApproved = false,
    this.canCall = false,
    this.coinsEarned = 0,
    this.walletBalance = 0.0,
    this.totalEarnings = 0.0,
    this.todayEarnings = 0.0,
    this.totalDurationSeconds = 0,
    this.todayDurationSeconds = 0,
    this.totalDurationFormatted = '0h 0m',
    this.todayDurationFormatted = '0h 0m',
    this.callsCompleted = 0,
    this.successRate = 0.0,
    this.agentRating = 4.9,
  });

  factory AgentDetailsModel.fromJson(Map<String, dynamic> json) {
    return AgentDetailsModel(
      username: json['username']?.toString() ?? '',
      agentStatus: json['agent_status']?.toString() ?? 'pending',
      isApproved: json['is_approved'] == true,
      canCall: json['can_call'] == true,
      coinsEarned: (json['coins_earned'] as num?)?.toInt() ?? 0,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0.0,
      todayEarnings: (json['today_earnings'] as num?)?.toDouble() ?? 0.0,
      totalDurationSeconds:
          (json['total_duration_seconds'] as num?)?.toInt() ?? 0,
      todayDurationSeconds:
          (json['today_duration_seconds'] as num?)?.toInt() ?? 0,
      totalDurationFormatted:
          json['total_duration_formatted']?.toString() ?? '0h 0m',
      todayDurationFormatted:
          json['today_duration_formatted']?.toString() ?? '0h 0m',
      callsCompleted: (json['calls_completed'] as num?)?.toInt() ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
      agentRating: (json['agent_rating'] as num?)?.toDouble() ?? 4.9,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'agent_status': agentStatus,
      'is_approved': isApproved,
      'can_call': canCall,
      'coins_earned': coinsEarned,
      'wallet_balance': walletBalance,
      'total_earnings': totalEarnings,
      'today_earnings': todayEarnings,
      'total_duration_seconds': totalDurationSeconds,
      'today_duration_seconds': todayDurationSeconds,
      'total_duration_formatted': totalDurationFormatted,
      'today_duration_formatted': todayDurationFormatted,
      'calls_completed': callsCompleted,
      'success_rate': successRate,
      'agent_rating': agentRating,
    };
  }
}

class ProfileModel {
  final String status;
  final String agentStatus;
  final bool isApproved;
  final bool canCall;
  final AgentDetailsModel agent;
  final TasksModel tasks;

  // Convenience getters for backwards compatibility with UI
  String get id => agent.username;
  String get name =>
      agent.username.isNotEmpty ? 'Agent ${agent.username}' : 'Agent';
  String? get phoneNumber => agent.username;
  String? get email => null;
  String? get gender => null;
  String? get avatar => null;
  int get totalCalls => agent.callsCompleted;
  double get rating => agent.agentRating;
  double get walletBalance => agent.walletBalance;
  double get todayEarnings => agent.todayEarnings;
  double get totalEarnings => agent.totalEarnings;

  const ProfileModel({
    this.status = 'success',
    this.agentStatus = 'pending',
    this.isApproved = false,
    this.canCall = false,
    this.agent = const AgentDetailsModel(),
    this.tasks = const TasksModel(),
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final agentData = json['agent'] is Map<String, dynamic>
        ? json['agent'] as Map<String, dynamic>
        : (json.containsKey('username') ? json : <String, dynamic>{});

    final tasksData = json['tasks'] is Map<String, dynamic>
        ? json['tasks'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ProfileModel(
      status: json['status']?.toString() ?? 'success',
      agentStatus: json['agent_status']?.toString() ??
          agentData['agent_status']?.toString() ??
          'pending',
      isApproved:
          json['is_approved'] == true || agentData['is_approved'] == true,
      canCall: json['can_call'] == true || agentData['can_call'] == true,
      agent: AgentDetailsModel.fromJson(agentData),
      tasks: TasksModel.fromJson(tasksData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'agent_status': agentStatus,
      'is_approved': isApproved,
      'can_call': canCall,
      'agent': agent.toJson(),
      'tasks': tasks.toJson(),
    };
  }
}
