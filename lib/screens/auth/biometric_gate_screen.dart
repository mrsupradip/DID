import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../routes/app_routes.dart';
import '../../services/session_service.dart';

class BiometricGateScreen extends StatefulWidget {
  final bool enrollMode;

  const BiometricGateScreen({super.key, this.enrollMode = false});

  @override
  State<BiometricGateScreen> createState() => _BiometricGateScreenState();
}

class _BiometricGateScreenState extends State<BiometricGateScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _bootstrapStarted = false;
  bool _navigationCompleted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepare();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    if (_bootstrapStarted || _navigationCompleted) return;
    _bootstrapStarted = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _goToLogin();
      return;
    }

    try {
      final supported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final enabled = await SessionService.isBiometricEnabled();

      if (!mounted) return;
      setState(() {
        _biometricSupported = supported && canCheckBiometrics;
        _biometricEnabled = enabled;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _biometricSupported = false;
        _biometricEnabled = false;
        _errorMessage = 'Fingerprint not available: $e';
      });
      return;
    }

    final hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
    );

    if (!widget.enrollMode && _biometricSupported && _biometricEnabled) {
      await _authenticateWithFingerprint();
    } else if (!widget.enrollMode && !hasPasswordProvider) {
      await SessionService.updateLastActive();
      if (!mounted) return;
      _goToHome();
    }
  }

  void _goToLogin() {
    if (!mounted || _navigationCompleted) return;
    _navigationCompleted = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _goToHome() {
    if (!mounted || _navigationCompleted) return;
    _navigationCompleted = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _authenticateWithFingerprint() async {
    if (_loading || _navigationCompleted) return;

    try {
      if (!_biometricSupported) return;
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      final authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to open D!D',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (authenticated) {
        await SessionService.setBiometricEnabled(true);
        if (!mounted) return;
        _goToHome();
      } else {
        setState(() {
          _loading = false;
          _errorMessage = 'Fingerprint verification was cancelled';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Fingerprint not available: $e';
      });
    }
  }

  Future<void> _continueWithPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final password = _passwordController.text.trim();
    if (user == null) return;

    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your password to continue';
      });
      return;
    }

    try {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });

      final email = user.email;
      if (email == null || email.isEmpty) {
        throw Exception('No email account found for password verification');
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);

      if (!mounted) return;
      _goToHome();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Wrong password. Try again.';
      });
    }
  }

  Future<void> _skipBiometricSetup() async {
    await SessionService.setBiometricEnabled(false);
    if (!mounted) return;
    _goToHome();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.enrollMode
        ? 'Set fingerprint now. Later you can unlock with fingerprint or password.'
        : 'Use fingerprint or password to enter your dashboard.';

    return Scaffold(
      backgroundColor: const Color(0xff101522),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fingerprint,
                  size: 72,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.enrollMode ? 'Set up unlock' : 'Unlock your account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? subtitle,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xff1B2235),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _continueWithPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue with password'),
                ),
              ),
              const SizedBox(height: 10),
              if (_biometricSupported)
                ElevatedButton.icon(
                  onPressed: _loading ? null : _authenticateWithFingerprint,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(
                    widget.enrollMode
                        ? 'Enable fingerprint unlock'
                        : 'Use fingerprint',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              if (widget.enrollMode)
                TextButton(
                  onPressed: _loading ? null : _skipBiometricSetup,
                  child: const Text('Skip for now'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
