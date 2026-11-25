import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/storage_service.dart';
import '../models/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return ProfileRepository(apiClient, storageService);
});

class ProfileRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  ProfileRepository(this._apiClient, this._storageService);

  Future<ProfileModel> getProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.dashboard);
      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final profile = ProfileModel.fromJson(data);
      if (profile.agentStatus.isNotEmpty) {
        await _storageService.saveAgentStatus(profile.agentStatus);
      }
      await _storageService.setIsApproved(profile.isApproved);
      return profile;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to load agent dashboard: $e');
    }
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? gender,
  }) async {
    try {
      await _apiClient.put(
        ApiEndpoints.profile,
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (gender != null) 'gender': gender,
        },
      );
      if (name != null) {
        await _storageService.saveUserName(name);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to update profile: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _apiClient.delete(ApiEndpoints.deleteAccount);
    } finally {
      await _storageService.clearAll();
    }
  }
}
