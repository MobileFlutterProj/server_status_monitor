import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);
  }

  Future<void> showCriticalAlert(String title, String body) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'critical_alerts',
        'Критические предупреждения',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        color: Color.fromARGB(255, 255, 0, 0),
      ),
    );

    await _notifications.show(0, title, body, platformChannelSpecifics);
  }
}