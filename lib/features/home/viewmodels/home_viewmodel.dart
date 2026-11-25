import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent_model.dart';
import '../models/home_state.dart';
import '../repositories/home_repository.dart';

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    Future.microtask(() => fetchHomeData());
    return const HomeState();
  }

  HomeRepository get _repository => ref.read(homeRepositoryProvider);

  Future<void> fetchHomeData() async {
    state = state.copyWith(status: HomeStatus.loading);
    try {
      final online = await _repository.getOnlineAgents().catchError(
        (_) => <AgentModel>[],
      );
      final all = await _repository.getAllAgents().catchError(
        (_) => <AgentModel>[],
      );

      state = state.copyWith(
        status: HomeStatus.loaded,
        onlineAgents: online,
        allAgents: all.isNotEmpty ? all : online,
      );
    } catch (e) {
      state = state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void selectCategory(int index) {
    state = state.copyWith(selectedCategoryIndex: index);
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);
