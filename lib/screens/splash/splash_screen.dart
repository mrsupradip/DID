import 'dart:async';
import 'dart:io' show Platform;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;
  Timer? _startupTimer;
  bool _routingStarted = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    scaleAnimation = CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    );

    controller.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStartupFlow();
    });
  }

  Future<void> _startStartupFlow() async {
    if (_routingStarted) return;
    _routingStarted = true;

    final inTest = Platform.environment['FLUTTER_TEST'] == 'true';
    if (inTest) return;

    _startupTimer?.cancel();
    _startupTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        return;
      }

      Navigator.of(context).pushReplacementNamed(AppRoutes.biometricGate);
    });
  }

  @override
  void dispose() {
    _startupTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Center(
        child: ScaleTransition(
          scale: scaleAnimation,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.26),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/didapplogo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              AnimatedTextKit(
                repeatForever: true,

                animatedTexts: [
                  TypewriterAnimatedText(
                    "Dive into Development",

                    speed: const Duration(milliseconds: 80),

                    textStyle: GoogleFonts.spaceGrotesk(
                      fontSize: 24,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              Text(
                "BUILD • CONNECT • GROW",

                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
