import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../main.dart';

final _localNotifications = FlutterLocalNotificationsPlugin();

Future<void> initPushNotifications({String? authToken}) async {
  // Request permission
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Init local notifications for foreground display
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await _localNotifications.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  // Register FCM token with backend
  final token = await messaging.getToken();
  if (token != null) {
    await _registerToken(token, authToken: authToken);
  }

  // Re-register when token refreshes
  messaging.onTokenRefresh.listen((t) => _registerToken(t, authToken: authToken));

  // Show notification when app is in foreground
  FirebaseMessaging.onMessage.listen((message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kamotohd_channel', 'KamotoHD',
          importance: Importance.high, priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  });
}

Future<void> _registerToken(String token, {String? authToken}) async {
  try {
    await http.post(
      Uri.parse('$kApiBase/push/register-token/'),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({'token': token, 'platform': 'android'}),
    );
  } catch (_) {}
}
