import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Gère les notifications locales OS (bannières, sons).
/// Pas de Firebase requis — fonctionne en polling depuis Strapi.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Dernier nombre de notifications non-lues connu
  int _lastUnreadCount = 0;

  static const _channelId = 'medicare_main';
  static const _channelName = 'MediCare';
  static const _channelDesc = 'Notifications médicales';

  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Crée le canal Android (requis Android 8+)
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    _initialized = true;
  }

  /// Appelé par le watcher de provider quand le count change.
  Future<void> onUnreadCountChanged(int newCount) async {
    if (newCount > _lastUnreadCount && newCount > 0) {
      final diff = newCount - _lastUnreadCount;
      await _showNotification(
        id: 1001,
        title: 'MediCare',
        body: diff == 1
            ? 'Vous avez une nouvelle notification'
            : 'Vous avez $diff nouvelles notifications',
      );
    }
    _lastUnreadCount = newCount;
  }

  Future<void> showMessageNotification({
    required String senderName,
    required String preview,
  }) async {
    await _showNotification(
      id: 1002,
      title: 'Message de $senderName',
      body: preview,
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
