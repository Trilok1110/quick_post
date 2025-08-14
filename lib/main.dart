import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'app_navigator.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'services/remote_config_service.dart';
import 'controllers/theme_controller.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Optionally log or process background data here
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Initialize notifications (permissions, channels, listeners)
  await NotificationService.instance.init();

  // Remote Config init
  final rc = RemoteConfigService.instance;
  await rc.init();

  // Theme controller
  final themeController = ThemeController.instance;
  await themeController.load(rc: rc);

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle the case where the app was opened from a terminated state by a notification
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    NotificationService.instance.handleMessageNavigation(initialMessage.data);
  }

  runApp(QuickPostApp(rc: rc, themeController: themeController));
}

class QuickPostApp extends StatefulWidget {
  final RemoteConfigService rc;
  final ThemeController themeController;
  const QuickPostApp({super.key, required this.rc, required this.themeController});

  @override
  State<QuickPostApp> createState() => _QuickPostAppState();
}

class _QuickPostAppState extends State<QuickPostApp> {
  @override
  Widget build(BuildContext context) {
    final rc = widget.rc;

    final light = rc.useRemoteTheme
        ? AppTheme.fromRemote(
            brightness: Brightness.light,
            seedColor: rc.seedColor,
            surfaceBg: rc.surfaceBg,
          )
        : AppTheme.light;

    final dark = rc.useRemoteTheme
        ? AppTheme.fromRemote(
            brightness: Brightness.dark,
            seedColor: rc.seedColor,
            surfaceBg: rc.surfaceBgDark,
          )
        : AppTheme.dark;

    return AnimatedBuilder(
      animation: widget.themeController,
      builder: (_, __) {
        return MaterialApp(
          title: 'QuickPost',
          theme: light,
          darkTheme: dark,
          themeMode: widget.themeController.mode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          onGenerateRoute: quickpostRouteGenerator,
          navigatorKey: NotificationService.instance.navigatorKey,
        );
      },
    );
  }
}

// Import custom navigator

