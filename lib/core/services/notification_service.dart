import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../routing/app_router.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// Request notification permission and retrieve FCM token.
  /// Returns null if permission is denied or token retrieval fails.
  Future<String?> getFCMToken() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('Notification permission denied');
        return null;
      }

      final token = await _messaging.getToken();
      print('FCM Token: $token');

      // Initialize incoming call listener
      initializeCallListeners();

      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Listens for incoming call messages in foreground and background
  void initializeCallListeners() {
    if (_isInitialized) return;
    _isInitialized = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleCallMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleCallMessage(message);
    });
  }

  void _handleCallMessage(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('call_id') ||
        data['type'] == 'incoming_call' ||
        data['action'] == 'incoming_call' ||
        data['action'] == 'call') {
      appRouter.push(AppRoutes.incomingCall, extra: data);
    }
  }

  /// Delete the FCM token from this device so it stops receiving
  /// push notifications for the logged-out user.
  Future<void> deleteFCMToken() async {
    try {
      await _messaging.deleteToken();
      print('FCM Token deleted');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}
