import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/alert.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifs.initialize(settings);

    // FCM setup for push notifications when app is background
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification != null) {
        showRaw(
          title: notification.title ?? 'MyeTaxi Tracker',
          body: notification.body ?? '',
          channelId: 'alerts',
        );
      }
    });
  }

  Future<void> showAlert(String message, AlertSeverity severity) async {
    final channelId = severity == AlertSeverity.critical ? 'critical' : 'alerts';
    final channelName = severity == AlertSeverity.critical
        ? 'Critical Alerts'
        : 'Fleet Alerts';

    await showRaw(
      title: severity == AlertSeverity.critical ? '🚨 CRITICAL ALERT' : '⚠️ Fleet Alert',
      body: message,
      channelId: channelId,
      channelName: channelName,
      priority: severity == AlertSeverity.critical
          ? Priority.max
          : Priority.high,
    );
  }

  Future<void> showExpiryAlert({
    required String subject,
    required int daysLeft,
  }) async {
    await showRaw(
      title: '📋 Document Expiry Warning',
      body: '$subject expires in $daysLeft days. Please renew soon.',
      channelId: 'expiry',
      channelName: 'Expiry Alerts',
    );
  }

  Future<void> showRaw({
    required String title,
    required String body,
    String channelId = 'general',
    String channelName = 'General',
    Priority priority = Priority.high,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.high,
      priority: priority,
      color: const Color(0xFF00D4FF),
      enableLights: true,
      ledColor: const Color(0xFF00D4FF),
      ledOnMs: 500,
      ledOffMs: 500,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifs.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}

// Needed for color in AndroidNotificationDetails
class Color {
  final int value;
  const Color(this.value);
}
