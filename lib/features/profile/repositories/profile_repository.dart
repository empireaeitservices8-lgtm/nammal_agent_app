import 'dart:io';
import 'package:dio/dio.dart';
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

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? gender,
    String? bio,
    String? dob,
    int? age,
    String? idType,
    String? idNumber,
    String? avatarPath,
  }) async {
    try {
      String? formattedDob;
      if (dob != null && dob.trim().isNotEmpty) {
        final clean = dob.replaceAll(' ', '').trim();
        if (clean.contains('/')) {
          final parts = clean.split('/');
          if (parts.length == 3) {
            formattedDob =
                '${parts[2].padLeft(4, '0')}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
          } else {
            formattedDob = clean;
          }
        } else {
          formattedDob = clean;
        }
      }

      final hasAvatar = avatarPath != null &&
          avatarPath.isNotEmpty &&
          File(avatarPath).existsSync();

      final baseMap = <String, dynamic>{
        if (name != null && name.isNotEmpty) 'name': name,
        if (email != null && email.isNotEmpty) 'email': email,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (bio != null) 'bio': bio,
        if (formattedDob != null && formattedDob.isNotEmpty) 'dob': formattedDob,
        if (age != null && age > 0) 'age': age,
        if (idNumber != null && idNumber.isNotEmpty) ...{
          'id_proof_number': idNumber,
          'id_number': idNumber,
        },
        if (idType != null && idType.isNotEmpty) 'id_type': idType,
      };

      dynamic payloadData;
      if (hasAvatar) {
        final fileName = avatarPath.split(Platform.pathSeparator).last;
        payloadData = FormData.fromMap({
          ...baseMap,
          'profile_picture': await MultipartFile.fromFile(
            avatarPath,
            filename: fileName,
          ),
          'avatar': await MultipartFile.fromFile(
            avatarPath,
            filename: fileName,
          ),
        });
      } else {
        payloadData = baseMap;
      }

      final response = await _apiClient.patch(
        ApiEndpoints.editProfile,
        data: payloadData,
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      // Persist values dynamically to local storage service
      final resName = data['name']?.toString() ?? name;
      if (resName != null && resName.isNotEmpty) {
        await _storageService.saveUserName(resName);
      }
      final resPhone = data['phone_number']?.toString();
      if (resPhone != null && resPhone.isNotEmpty) {
        await _storageService.savePhone(resPhone);
      }
      final resBio = data['profile']?['bio']?.toString() ??
          data['user']?['profile']?['bio']?.toString() ??
          bio;
      if (resBio != null) {
        await _storageService.saveBio(resBio);
      }
      final resDob = data['dob']?.toString() ??
          data['profile']?['date_of_birth']?.toString() ??
          dob;
      if (resDob != null && resDob.isNotEmpty) {
        await _storageService.saveDob(resDob);
      }
      final resIdNumber = data['id_proof_number']?.toString() ?? idNumber;
      if (resIdNumber != null && resIdNumber.isNotEmpty) {
        await _storageService.saveIdNumber(resIdNumber);
      }
      if (idType != null && idType.isNotEmpty) {
        await _storageService.saveIdType(idType);
      }
      if (hasAvatar) {
        await _storageService.saveAvatar(avatarPath);
      }

      return data;
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
