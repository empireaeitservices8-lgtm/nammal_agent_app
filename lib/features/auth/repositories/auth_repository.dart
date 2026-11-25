import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/services/storage_service.dart';
import '../models/agent_register_response.dart';
import '../models/send_otp_response.dart';
import '../models/user_model.dart';
import '../models/verify_otp_response.dart';

const List<int> _kDefaultImageBytes = [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepository(apiClient, storageService);
});

class AuthRepository {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthRepository(this._apiClient, this._storageService);

  Future<SendOtpResponse> sendOtp(String phoneNumber) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-+]'), '');
      final formattedPhone =
          cleanPhone.startsWith('91') && cleanPhone.length == 12
          ? cleanPhone.substring(2)
          : cleanPhone;
      final response = await _apiClient.post(
        ApiEndpoints.sendOtp,
        data: {'phone_number': formattedPhone},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final otpResponse = SendOtpResponse.fromJson(data);
        await _storageService.savePhone(
          otpResponse.phoneNumber.isNotEmpty
              ? otpResponse.phoneNumber
              : formattedPhone,
        );
        return otpResponse;
      }
      throw ApiException(message: 'Invalid response format from server');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to send OTP: $e');
    }
  }

  Future<VerifyOtpResponse> verifyOtp({
    required String phoneNumber,
    required String otp,
    String? fcmToken,
  }) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-+]'), '');
      final formattedPhone =
          cleanPhone.startsWith('91') && cleanPhone.length == 12
          ? cleanPhone.substring(2)
          : cleanPhone;
      final cleanOtp = otp.trim();

      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {
          'phone_number': formattedPhone,
          'otp': cleanOtp,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final verifyResponse = VerifyOtpResponse.fromJson(data);

        if (verifyResponse.token != null && verifyResponse.token!.isNotEmpty) {
          await _storageService.saveToken(verifyResponse.token!);
        }

        final isNew =
            !verifyResponse.isExistingUser && !verifyResponse.isExistingAgent;
        await _storageService.setIsNewUser(isNew);

        if (verifyResponse.user != null && verifyResponse.user!.id.isNotEmpty) {
          await _storageService.saveUserId(verifyResponse.user!.id);
        }

        final userName = verifyResponse.name ?? verifyResponse.user?.name;
        if (userName != null && userName.isNotEmpty) {
          await _storageService.saveUserName(userName);
        }

        if (verifyResponse.role != null) {
          await _storageService.saveRole(verifyResponse.role!);
        }
        if (verifyResponse.agentStatus != null) {
          await _storageService.saveAgentStatus(verifyResponse.agentStatus!);
        }
        await _storageService.setIsApproved(verifyResponse.isApproved);

        return verifyResponse;
      }

      throw ApiException(message: 'Invalid response format from server');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to verify OTP: $e');
    }
  }

  Future<AgentRegisterResponse> registerAgent({
    required String name,
    required String gender,
    required String phoneNumber,
    required String age,
    required String dateOfBirth,
    required String idType,
    required String idNumber,
    required String jurisdiction,
    String? idPhotoPath,
  }) async {
    try {
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-+]'), '');
      final formattedPhone =
          cleanPhone.startsWith('91') && cleanPhone.length == 12
          ? cleanPhone.substring(2)
          : cleanPhone;

      final parsedAge =
          int.tryParse(age.replaceAll(RegExp(r'[^0-9]'), '')) ?? 23;

      // Clean and format DOB into standard YYYY-MM-DD
      String cleanDob = dateOfBirth.replaceAll(' ', '').trim();
      try {
        final slashParts = cleanDob.split('/');
        if (slashParts.length == 3) {
          final d = slashParts[0].padLeft(2, '0');
          final m = slashParts[1].padLeft(2, '0');
          final y = slashParts[2];
          cleanDob = '$y-$m-$d';
        } else {
          final dashParts = cleanDob.split('-');
          if (dashParts.length == 3 && dashParts[0].length <= 2) {
            final d = dashParts[0].padLeft(2, '0');
            final m = dashParts[1].padLeft(2, '0');
            final y = dashParts[2];
            cleanDob = '$y-$m-$d';
          }
        }
      } catch (_) {}

      // Prepare ID Proof Picture file
      MultipartFile? idProofPic;
      if (idPhotoPath != null &&
          idPhotoPath.isNotEmpty &&
          File(idPhotoPath).existsSync()) {
        final filename = idPhotoPath.split(Platform.pathSeparator).last;
        idProofPic = await MultipartFile.fromFile(
          idPhotoPath,
          filename: filename.isNotEmpty ? filename : 'id_proof.jpg',
        );
      } else {
        final tempFile = File(
          '${Directory.systemTemp.path}/default_id_proof.jpg',
        );
        if (!tempFile.existsSync()) {
          await tempFile.writeAsBytes(_kDefaultImageBytes);
        }
        idProofPic = await MultipartFile.fromFile(
          tempFile.path,
          filename: 'id_proof.jpg',
        );
      }

      final formData = FormData.fromMap({
        'name': name,
        'gender': gender.toLowerCase(),
        'phone_number': formattedPhone,
        'age': parsedAge,
        'dob': cleanDob,
        'id_type': idType,
        'id_number': idNumber,
        'jurisdiction': jurisdiction,
        if (idProofPic != null) 'id_proof_pic': idProofPic,
      });

      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: formData,
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final registerResponse = AgentRegisterResponse.fromJson(data);

        if (registerResponse.token != null &&
            registerResponse.token!.isNotEmpty) {
          await _storageService.saveToken(registerResponse.token!);
        }

        await _storageService.setIsNewUser(false);

        if (registerResponse.user != null &&
            registerResponse.user!.id.isNotEmpty) {
          await _storageService.saveUserId(registerResponse.user!.id);
        }

        final userName = registerResponse.user?.name ?? name;
        if (userName.isNotEmpty) {
          await _storageService.saveUserName(userName);
        }

        await _storageService.savePhone(formattedPhone);

        if (registerResponse.role.isNotEmpty) {
          await _storageService.saveRole(registerResponse.role);
        }
        if (registerResponse.agentStatus.isNotEmpty) {
          await _storageService.saveAgentStatus(registerResponse.agentStatus);
        }
        await _storageService.setIsApproved(registerResponse.isApproved);
        await _storageService.setCanCall(registerResponse.canCall);

        return registerResponse;
      }

      throw ApiException(message: 'Invalid response format from server');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Failed to complete registration: $e');
    }
  }

  Future<UserModel> completeOnboarding({
    required String name,
    required String gender,
    String? email,
  }) async {
    final res = await registerAgent(
      name: name,
      gender: gender,
      phoneNumber: _storageService.getPhone() ?? '',
      age: '18',
      dateOfBirth: '',
      idType: 'Aadhaar Card',
      idNumber: '',
      jurisdiction: '',
    );
    return res.user ?? UserModel(id: '', name: name, gender: gender);
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
