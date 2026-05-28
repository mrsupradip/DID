import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/session_service.dart';
import 'services/profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only once and ignore duplicate-app errors which
  // can happen during hot-restart or if another isolate already initialized
  // the default app.
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('Firebase already initialized: ${e.message}');
      } else {
        debugPrint('FirebaseException during initialize: ${e.message}');
        rethrow;
      }
    } catch (e) {
      debugPrint('Unexpected error initializing Firebase: $e');
      rethrow;
    }
  } else {
    debugPrint('Firebase already initialized (Firebase.apps.isNotEmpty)');
  }

  await ProfileService.loadProfile();

  runApp(const DIDApp());
}

class DIDApp extends StatefulWidget {
  const DIDApp({super.key});

  @override
  State<DIDApp> createState() => _DIDAppState();
}

class _DIDAppState extends State<DIDApp> with WidgetsBindingObserver {
  static const _maxIdle = Duration(days: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSessionExpiry();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Update last-active when the user returns to the app.
      SessionService.updateLastActive();
    }
  }

  Future<void> _checkSessionExpiry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final expired = await SessionService.isExpired(_maxIdle);
    if (expired) {
      await FirebaseAuth.instance.signOut();
      await SessionService.clearLastActive();
      debugPrint('Session expired: signed out user');
    } else {
      // Refresh last-active to now on app start.
      await SessionService.updateLastActive();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ProfileService.themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: "D!D",

          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xffF5F7FB),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.greenAccent,
              brightness: Brightness.light,
            ),
          ),

          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xff101522),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.greenAccent,
              brightness: Brightness.dark,
            ),
          ),

          themeMode: themeMode,

          initialRoute: AppRoutes.splash,

          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}
