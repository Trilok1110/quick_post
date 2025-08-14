import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final navigatorKey = GlobalKey<NavigatorState>();

  final _messaging = FirebaseMessaging.instance;
  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _defaultChannel = AndroidNotificationChannel(
    'quickpost_high_importance',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.high,
  );

  Future<void> init() async {
    // Request permission on iOS/macOS and Android 13+
    await _requestPermissions();

    // Create channel for Android
    await _setupFlutterLocalNotifications();

    // Obtain FCM token
    final token = await _messaging.getToken();
    if (kDebugMode) {
      debugPrint('FCM Token: $token');
    }

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    // When app is in background and user taps the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleMessageNavigation(message.data);
    });
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      debugPrint('User granted permission: ${settings.authorizationStatus}');
    }

    if (Platform.isAndroid) {
      // On Android 13+, request POST_NOTIFICATIONS permission via plugin
      await _messaging.requestPermission();
    }
  }

  Future<void> _setupFlutterLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final initSettings = InitializationSettings(android: androidInit, iOS: darwinInit, macOS: darwinInit);

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        // Handle taps on foreground notifications
        handleMessageNavigation(response.payload != null ? {'route': response.payload!} : {});
      },
    );

    // Android channel
    await _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(_defaultChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;

    // Build a polished notification for foreground
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultChannel.id,
        _defaultChannel.name,
        channelDescription: _defaultChannel.description,
        icon: android?.smallIcon ?? '@mipmap/ic_launcher',
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification?.title ?? 'QuickPost',
      notification?.body ?? '',
      details,
      payload: message.data['route'],
    );
  }

  // Centralized deep-link handling from notification payload
  void handleMessageNavigation(Map<String, dynamic> data) {
    final route = data['route'] as String?; // e.g., '/post?id=123' or '/users'
    if (route == null || route.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Basic route handling. Extend to parse query parameters if needed.
    Navigator.of(context).pushNamed(route);
  }
}
