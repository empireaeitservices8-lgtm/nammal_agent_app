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
    final user = authState.user;
    final name = (user?.name?.isNotEmpty == true)
        ? user!.name!
        : (user?.username?.isNotEmpty == true
              ? user!.username!
              : (user?.phoneNumber?.isNotEmpty == true
                    ? user!.phoneNumber!
                    : 'Agent'));
    return HomeState(agentName: name, recentCalls: const []);
  }

  HomeRepository get _repository => ref.read(homeRepositoryProvider);

  Future<void> fetchHomeData() async {
    state = state.copyWith(status: HomeStatus.loading);
    try {
      final dashboard = await _repository.getAgentDashboard().catchError(
        (_) => null,
      );
      final calls = await _repository.getRecentHandledCalls().catchError(
        (_) => <HandledCallModel>[],
      );

      final authState = ref.read(authViewModelProvider);
      final user = authState.user;
      final agent = dashboard?.agent;

      final resolvedName = (agent?.name.isNotEmpty == true)
          ? agent!.name
          : ((user?.name?.isNotEmpty == true)
                ? user!.name!
                : (agent?.username.isNotEmpty == true
                      ? agent!.username
                      : (user?.username?.isNotEmpty == true
                            ? user!.username!
                            : (user?.phoneNumber?.isNotEmpty == true
                                  ? user!.phoneNumber!
                                  : state.agentName))));

      state = state.copyWith(
        status: HomeStatus.loaded,
        dashboard: dashboard,
        agentDetails: agent,
        recentCalls: calls,
        agentName: resolvedName,
        isOnline: dashboard?.canCall ?? state.isOnline,
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
      final message =
          res['message']?.toString() ??
          (serverStatus
              ? 'Agent availability set to Online'
              : 'Agent availability set to Offline');
      state = state.copyWith(isOnline: serverStatus, isTogglingStatus: false);
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
