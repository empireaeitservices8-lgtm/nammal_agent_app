import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../models/agent_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeRepository(apiClient);
});

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository(this._apiClient);

  Future<List<AgentModel>> getOnlineAgents() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.onlineAgents);
      final data = response.data;
      if (data is List) {
        return data.map((e) => AgentModel.fromJson(e)).toList();
      } else if (data is Map && data['agents'] is List) {
        return (data['agents'] as List)
            .map((e) => AgentModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch online agents');
    }
  }

  Future<List<AgentModel>> getAllAgents() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.home);
      final data = response.data;
      if (data is List) {
        return data.map((e) => AgentModel.fromJson(e)).toList();
      } else if (data is Map && data['agents'] is List) {
        return (data['agents'] as List)
            .map((e) => AgentModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch agents: $e');
    }
  }
}
