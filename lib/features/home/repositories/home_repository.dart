import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../../profile/models/profile_model.dart';
import '../models/handled_call_model.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HomeRepository(apiClient);
});

class HomeRepository {
  final ApiClient _apiClient;

  HomeRepository(this._apiClient);

  Future<ProfileModel?> getAgentDashboard() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dashboard);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ProfileModel.fromJson(data);
      }
      return null;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to fetch agent dashboard: $e');
    }
  }

  Future<Map<String, dynamic>> toggleStatus({required bool isOnline}) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.toggleStatus,
        data: {'is_online': isOnline},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return {
        'status': 'success',
        'is_online': isOnline,
        'message': isOnline
            ? 'Agent availability set to Online'
            : 'Agent availability set to Offline',
      };
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to toggle status: $e');
    }
  }

  Future<List<HandledCallModel>> getRecentHandledCalls() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.callHistory);
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => HandledCallModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (data is Map<String, dynamic> && data['history'] is List) {
        return (data['history'] as List)
            .map((e) => HandledCallModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
