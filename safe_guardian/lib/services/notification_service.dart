import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 푸시 알림 서비스
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  int _notificationId = 0;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  /// 위험 알림 발송
  Future<void> showDangerAlert({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'danger_channel',
      '위험 알림',
      channelDescription: '스미싱 위험 감지 알림',
      importance: Importance.max,
      priority: Priority.high,
<<<<<<< HEAD
=======
      color: Color(0xFFC62828),
>>>>>>> 6ddcc6c101a73da16c16f46604675fd4ca04a30c
      enableVibration: true,
      playSound: true,
    );

    await _plugin.show(
      _notificationId++,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// 안전 알림 발송
  Future<void> showSafeAlert({
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'safe_channel',
      '안전 알림',
      channelDescription: '안전한 문자 확인 알림',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
<<<<<<< HEAD
=======
      color: Color(0xFF2E7D32),
>>>>>>> 6ddcc6c101a73da16c16f46604675fd4ca04a30c
    );

    await _plugin.show(
      _notificationId++,
      '✅ 안전 확인',
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
