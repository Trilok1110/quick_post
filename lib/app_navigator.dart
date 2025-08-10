import 'package:flutter/material.dart';
import 'package:quickpost/signup_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';
import 'splash_page.dart';
import 'login_page.dart';
import 'phone_auth_page.dart';
import 'create_post_page.dart';


Route<dynamic>? quickpostRouteGenerator(RouteSettings settings) {
  Widget page;
  switch (settings.name) {
    case '/':
      page = const SplashPage();
      break;
    case '/login':
      page = const LoginPage();
      break;
    case '/forget_password':
      page = const ForgotPasswordPage();
      break;
    case '/signup':
      page = const SignupPage();
      break;
    case '/phone_auth':
      page = const PhoneAuthPage();
      break;
    case '/home':
      page = const HomePage();
      break;
    case '/create_post':
      page = const CreatePostPage();
      break;
    default:
      page = const SplashPage();
  }

  // Gen-Z transition: slide up + fade (can tweak for style)
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Combo: scale in + fade in + slight upward slide
      var beginOffset = const Offset(0, 0.08);
      var endOffset = Offset.zero;
      var tween = Tween(begin: beginOffset, end: endOffset).chain(CurveTween(curve: Curves.easeOutCubic));
      var fadeTween = Tween<double>(begin: 0.0, end: 1.0);
      var scaleTween = Tween<double>(begin: 0.96, end: 1.0);
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 470),
  );
}

class AppNavigator {
  static void pushNamed(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }

  static void pushReplacementNamed(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  static void pop(BuildContext context) {
    Navigator.of(context).pop();
  }
}

