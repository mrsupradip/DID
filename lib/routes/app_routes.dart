import 'package:flutter/material.dart';

import '../screens/auth/biometric_gate_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_setup_screen.dart';
import '../screens/splash/splash_screen.dart';

class AppRoutes {
  static const splash = "/";

  static const login = "/login";

  static const signup = "/signup";

  static const profileSetup = "/profileSetup";

  static const biometricGate = "/biometric-gate";

  static const home = "/home";

  static Route onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case profileSetup:
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());

      case biometricGate:
        return MaterialPageRoute(builder: (_) => const BiometricGateScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text("Page Not Found"))),
        );
    }
  }
}
