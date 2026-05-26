import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const DIDApp());
}

class DIDApp extends StatelessWidget {
  const DIDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "D!D",

      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),

      home: const SplashScreen(),
    );
  }
}
