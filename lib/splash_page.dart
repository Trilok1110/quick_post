import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickpost/home_page.dart';
import 'package:quickpost/login_page.dart';
import 'components/qp_loading.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges()
        , builder: (context,snapshot)
        {
      if (snapshot.connectionState == ConnectionState.waiting){
        return Scaffold(
          extendBody: true,
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF150050), const Color(0xFF0B1026)]
                    : [const Color(0xFFB7F8DB), const Color(0xFFF2B5D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _controller,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (r) => const LinearGradient(
                        colors: [Color(0xFFFF61A6), Color(0xFF54E8C2)],
                      ).createShader(r),
                      child: const Icon(
                        Icons.flash_on_rounded,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('QuickPost',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 40),
                    const QPLoading(label: 'Loading...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      else if (snapshot.hasData){
        return HomePage();
      }
      else {
        return LoginPage();
      }

        }
    );


  }
}

