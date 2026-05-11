import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class FcmService {
  static final _logger = Logger();
  static String? _fcmToken;
  static String? get fcmToken => _fcmToken;

  /// Initialize Firebase + FCM. Safe to call multiple times.
  /// Returns the FCM token or null if init failed (e.g. placeholder google-services.json).
  static Future<String?> init() async {
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS + Android 13+)
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      _fcmToken = await messaging.getToken();
      if (_fcmToken != null && _fcmToken!.length > 20) {
        _logger.i('FCM Token: ${_fcmToken!.substring(0, 20)}...');
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _logger.i('FCM Token refreshed');
        // TODO: re-register with backend
      });

      // Foreground messages — also show as local notification
      FirebaseMessaging.onMessage.listen((message) {
        _logger.d('FCM foreground message: ${message.notification?.title}');
        // The flutter_local_notifications service already handles displaying
      });

      return _fcmToken;
    } catch (e) {
      // If google-services.json is a placeholder, init will throw — fail gracefully
      if (kDebugMode) {
        _logger.w('FCM init failed (likely placeholder Firebase config): $e');
      }
      return null;
    }
  }

  /// Register the FCM token with the backend so it can send pushes to this device.
  static Future<void> registerWithBackend(
    Future<void> Function(String token) registerFn,
  ) async {
    if (_fcmToken != null) {
      try {
        await registerFn(_fcmToken!);
        _logger.i('FCM token registered with backend');
      } catch (e) {
        _logger.w('FCM token registration failed: $e');
      }
    }
  }
}
