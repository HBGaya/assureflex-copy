import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // You can log or handle background data here if needed
}

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  final _storage = const FlutterSecureStorage();
  static const _kFcmToken = 'fcm_token';

  final _flutterLocal = FlutterLocalNotificationsPlugin();

  // Android channel for heads-up notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'assureflex_default',
    'AssureFlex Notifications',
    description: 'General notifications',
    importance: Importance.high,
  );

  Future<void> init() async {
    try {
      await Firebase.initializeApp();

      // iOS: request permission
      if (Platform.isIOS) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true, badge: true, sound: true,
        );
        debugPrint('APNs permission: ${settings.authorizationStatus}');
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true,
        );
      }

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Local notifications init
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _flutterLocal.initialize(initSettings);

      // Android channel create
      if (Platform.isAndroid) {
        await _flutterLocal
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null) {
          _flutterLocal.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channel.id,
                _channel.name,
                channelDescription: _channel.description,
                priority: Priority.high,
                importance: Importance.high,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              ),
              iOS: const DarwinNotificationDetails(),
            ),
          );
        }
      });

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('Notification tapped: ${message.data}');
      });

      // Save the initial token with retry logic
      try {
        final token = await FirebaseMessaging.instance.getToken()
            .timeout(const Duration(seconds: 10));
        if (token != null && token.isNotEmpty) {
          await _storage.write(key: _kFcmToken, value: token);
          debugPrint('FCM token: $token');
        }
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
        // Continue without token - can retry later
      }

      // Watch for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _storage.write(key: _kFcmToken, value: newToken);
        debugPrint('FCM token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('Notification service init error: $e');
      rethrow; // Let the caller handle it
    }
  }

  Future<String?> readToken() => _storage.read(key: _kFcmToken);

  String get platform => Platform.isAndroid ? 'android' : 'ios';
}
