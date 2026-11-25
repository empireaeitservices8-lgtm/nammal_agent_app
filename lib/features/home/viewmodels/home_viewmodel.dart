import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/handled_call_model.dart';
import '../models/home_state.dart';
import '../repositories/home_repository.dart';

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() {
    Future.microtask(() => fetchHomeData());
    final authState = ref.watch(authViewModelProvider);
    final name = authState.user?.name ?? 'Rahul Sharma';
    return HomeState(
      agentName: name.isNotEmpty ? name : 'Rahul Sharma',
      recentCalls: HandledCallModel.sampleCalls,
    );
  }

  HomeRepository get _repository => ref.read(homeRepositoryProvider);

  Future<void> fetchHomeData() async {
    state = state.copyWith(status: HomeStatus.loading);
    try {
      final dashboard =
          await _repository.getAgentDashboard().catchError((_) => null);
      final calls = await _repository.getRecentHandledCalls();

      final authState = ref.read(authViewModelProvider);
      final name = authState.user?.name;

      state = state.copyWith(
        status: HomeStatus.loaded,
        agentDetails: dashboard,
        recentCalls:
            calls.isNotEmpty ? calls : HandledCallModel.sampleCalls,
        agentName: (name != null && name.isNotEmpty)
            ? name
            : (dashboard?.username.isNotEmpty == true
                ? dashboard!.username
                : state.agentName),
        isOnline: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<String?> toggleOnlineStatus() async {
    final nextStatus = !state.isOnline;
    state = state.copyWith(isTogglingStatus: true);
    try {
      final res = await _repository.toggleStatus(isOnline: nextStatus);
      final serverStatus = res['is_online'] == true;
      final message = res['message']?.toString() ??
          (serverStatus
              ? 'Agent availability set to Online'
              : 'Agent availability set to Offline');
      state = state.copyWith(
        isOnline: serverStatus,
        isTogglingStatus: false,
      );
      return message;
    } catch (e) {
      state = state.copyWith(isTogglingStatus: false);
      return null;
    }
  }
}

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);
