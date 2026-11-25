import 'user_model.dart';

class AgentRegisterResponse {
  final String status;
  final String nextStep;
  final String agentStatus;
  final bool isApproved;
  final bool canCall;
  final String role;
  final bool isAgent;
  final String? token;
  final UserModel? user;
  final String message;

  const AgentRegisterResponse({
    required this.status,
    this.nextStep = 'home',
    this.agentStatus = 'pending',
    this.isApproved = false,
    this.canCall = false,
    this.role = 'agent',
    this.isAgent = true,
    this.token,
    this.user,
    this.message = '',
  });

  factory AgentRegisterResponse.fromJson(Map<String, dynamic> json) {
    UserModel? parsedUser;
    if (json['user'] is Map<String, dynamic>) {
      parsedUser = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['user'] != null) {
      parsedUser = UserModel.fromJson(json);
    }

    return AgentRegisterResponse(
      status: json['status']?.toString() ?? '',
      nextStep: json['next_step']?.toString() ?? 'home',
      agentStatus: json['agent_status']?.toString() ?? 'pending',
      isApproved: json['is_approved'] == true,
      canCall: json['can_call'] == true,
      role: json['role']?.toString() ?? 'agent',
      isAgent: json['is_agent'] == true || json['is_agent'] == null,
      token: json['token']?.toString(),
      user: parsedUser,
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'next_step': nextStep,
      'agent_status': agentStatus,
      'is_approved': isApproved,
      'can_call': canCall,
      'role': role,
      'is_agent': isAgent,
      'token': token,
      'user': user?.toJson(),
      'message': message,
    };
  }
}
