import '../../profile/models/profile_model.dart';
import 'handled_call_model.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final AgentDetailsModel? agentDetails;
  final List<HandledCallModel> recentCalls;
  final String? errorMessage;
  final String agentName;
  final bool isOnline;
  final bool isTogglingStatus;
  final int unreadNotificationsCount;

  const HomeState({
    this.status = HomeStatus.initial,
    this.agentDetails,
    this.recentCalls = const [],
    this.errorMessage,
    this.agentName = 'Rahul Sharma',
    this.isOnline = true,
    this.isTogglingStatus = false,
    this.unreadNotificationsCount = 3,
  });

  HomeState copyWith({
    HomeStatus? status,
    AgentDetailsModel? agentDetails,
    List<HandledCallModel>? recentCalls,
    String? errorMessage,
    String? agentName,
    bool? isOnline,
    bool? isTogglingStatus,
    int? unreadNotificationsCount,
  }) {
    return HomeState(
      status: status ?? this.status,
      agentDetails: agentDetails ?? this.agentDetails,
      recentCalls: recentCalls ?? this.recentCalls,
      errorMessage: errorMessage,
      agentName: agentName ?? this.agentName,
      isOnline: isOnline ?? this.isOnline,
      isTogglingStatus: isTogglingStatus ?? this.isTogglingStatus,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
    );
  }
}
