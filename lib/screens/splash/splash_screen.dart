import 'dart:io' show Platform;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scaleAnimation;

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

    // Only skip automatic navigation when running Flutter tests. The test
    // runner sets the environment variable `FLUTTER_TEST=true`.
    final inTest = Platform.environment['FLUTTER_TEST'] == 'true';

    if (!inTest) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
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
              Text(
                "D!D",
                style: GoogleFonts.orbitron(
                  fontSize: 75,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
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
