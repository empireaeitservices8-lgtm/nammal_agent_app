import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/storage_service.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepository(apiClient, storageService);
});

class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepository(this._apiClient, this._storageService);

  Future<void> sendOtp(String phoneNumber) async {
    try {
      await _apiClient.post(
        ApiEndpoints.sendOtp,
        data: {'phone_number': phoneNumber},
      );
      await _storageService.savePhone(phoneNumber);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to send OTP: $e');
    }
  }

  Future<UserModel> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? fcmToken,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {
          'phone_number': phoneNumber,
          'otp': otp,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final token = data['token'] ?? data['access_token'] ?? data['key'];
        if (token != null) {
          await _storageService.saveToken(token.toString());
        }

        final isNewUser = data['is_new_user'] == true || data['is_new'] == true;
        await _storageService.setIsNewUser(isNewUser);

        final userData = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;

        final user = UserModel.fromJson(userData);
        if (user.id.isNotEmpty) {
          await _storageService.saveUserId(user.id);
        }
        if (user.name != null) {
          await _storageService.saveUserName(user.name!);
        }

        return user;
      }

      throw ApiException(message: 'Invalid response format from server');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to verify OTP: $e');
    }
  }

  Future<UserModel> completeOnboarding({
    required String name,
    required String gender,
    String? email,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'gender': gender,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      await _storageService.setIsNewUser(false);
      await _storageService.saveUserName(name);

      return UserModel.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to save profile: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {
      // Continue clearing session locally regardless of network error
    } finally {
      await _storageService.clearAll();
    }
  }

  Future<bool> checkSession() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty && _storageService.isLoggedIn();
  }
}
