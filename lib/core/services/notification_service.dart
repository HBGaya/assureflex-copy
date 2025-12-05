import 'dart:io';
import 'dart:math';
import 'package:assureflex/core/services/secure_storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final NotificationService I = NotificationService._();

  // IMPORTANT: Android options add karo
  // final _storage = const FlutterSecureStorage(
  //   aOptions: AndroidOptions(
  //     encryptedSharedPreferences: true,
  //     resetOnError: true,
  //   ),
  // );

  final _flutterLocal = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'assureflex_default',
    'AssureFlex Notifications',
    description: 'General notifications',
    importance: Importance.high,
  );

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      if (kDebugMode) print('🔥 Firebase initialized');

      if (Platform.isIOS) {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true, badge: true, sound: true,
        );
        if (kDebugMode) print('APNs permission: ${settings.authorizationStatus}');
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true,
        );
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
      await _flutterLocal.initialize(initSettings);

      if (Platform.isAndroid) {
        await _flutterLocal
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

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

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode) print('Notification tapped: ${message.data}');
      });

      // TOKEN SAVE - Using shared storage
      try {
        if (kDebugMode) print('📱 Requesting FCM token...');

        final token = await FirebaseMessaging.instance.getToken()
            .timeout(const Duration(seconds: 20));

        if (kDebugMode) {
          print('📱 Token received: ${token != null ? "YES (${token.length} chars)" : "NULL"}');
        }

        if (token != null && token.isNotEmpty) {
          if (kDebugMode) {
            final preview = token.substring(0, min(30, token.length));
            print('📱 Token preview: $preview...');
          }

          // USE SHARED STORAGE
          await SecureStorageService.I.saveFcmToken(token);
          if (kDebugMode) print('💾 Token saved using shared storage');

          // VERIFY
          final verification = await SecureStorageService.I.readFcmToken();
          if (verification == token) {
            if (kDebugMode) print('✅ Token verification SUCCESS');
          } else {
            if (kDebugMode) print('❌ Token verification FAILED');
          }
        } else {
          if (kDebugMode) print('⚠️ Token is null or empty');
        }
      } catch (e, stack) {
        if (kDebugMode) {
          print('❌ Failed to get/save FCM token: $e');
          print('Stack: $stack');
        }
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          print('🔄 Token refresh: ${newToken.substring(0, min(30, newToken.length))}...');
        }

        await SecureStorageService.I.saveFcmToken(newToken);
        final saved = await SecureStorageService.I.readFcmToken();
        if (kDebugMode) print(saved == newToken ? '✅ Refresh saved' : '❌ Refresh failed');
      });

    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Notification service init error: $e');
        print('Stack: $stack');
      }
      rethrow;
    }
  }

  Future<String?> readToken() async {
    final token = await SecureStorageService.I.readFcmToken();
    if (kDebugMode) {
      print('📖 Reading FCM token: ${token != null ? "Found (${token.length} chars)" : "NULL"}');
    }
    return token;
  }

  String get platform => Platform.isAndroid ? 'android' : 'ios';
}