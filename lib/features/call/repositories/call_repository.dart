import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CallRepository(apiClient);
});

class CallRepository {
  final ApiClient _apiClient;

  CallRepository(this._apiClient);

  Future<void> updateCallStatus({
    required dynamic callId,
    required String status,
  }) async {
    try {
      if (callId == null || callId.toString().isEmpty) return;
      await _apiClient.post(
        ApiEndpoints.callEnd(callId),
        data: {'status': status},
      ).catchError((_) async {
        return await _apiClient.post(
          ApiEndpoints.callStatus(callId),
          data: {'status': status},
        );
      });
    } catch (_) {
      // Gracefully handle call status update errors
    }
  }

  Future<void> declineCall(dynamic callId) async {
    await updateCallStatus(callId: callId, status: 'declined');
  }

  Future<void> acceptCall(dynamic callId) async {
    await updateCallStatus(callId: callId, status: 'accepted');
  }
}
