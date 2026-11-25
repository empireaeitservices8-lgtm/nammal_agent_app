import 'agent_model.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final List<AgentModel> onlineAgents;
  final List<AgentModel> allAgents;
  final String? errorMessage;
  final int selectedCategoryIndex;

  const HomeState({
    this.status = HomeStatus.initial,
    this.onlineAgents = const [],
    this.allAgents = const [],
    this.errorMessage,
    this.selectedCategoryIndex = 0,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<AgentModel>? onlineAgents,
    List<AgentModel>? allAgents,
    String? errorMessage,
    int? selectedCategoryIndex,
  }) {
    return HomeState(
      status: status ?? this.status,
      onlineAgents: onlineAgents ?? this.onlineAgents,
      allAgents: allAgents ?? this.allAgents,
      errorMessage: errorMessage,
      selectedCategoryIndex:
          selectedCategoryIndex ?? this.selectedCategoryIndex,
    );
  }
}
