import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/auth_service.dart';
import '../../routes/app_routes.dart';
import '../../services/permission_service.dart';
import 'signup_screen.dart';
import '../../services/session_service.dart';
import '../../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadLastEmail();
  }

  Future<void> _loadLastEmail() async {
    final email = await SessionService.getLastEmail();
    if (!mounted || email == null || email.isEmpty) return;
    emailController.text = email;
  }

  Future<void> _handleOauthLogin({
    required String providerName,
    required Future<dynamic> Function() signIn,
  }) async {
    if (loading) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => loading = true);
    try {
      final user = await signIn();
      if (!mounted) return;

      if (user == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              authService.lastError ?? '$providerName sign-in failed.',
            ),
          ),
        );
        return;
      }

      await FirestoreService().updateUser(
        uid: user.uid,
        data: {
          'uid': user.uid,
          'name': user.displayName ?? 'Developer',
          'email': user.email ?? '',
          'createdAt': DateTime.now(),
        },
      );
      await SessionService.updateLastActive();
      if ((user.email ?? '').isNotEmpty) {
        await SessionService.saveLastEmail(user.email!);
      }
      await PermissionService.requestOnboardingPermissions();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.biometricGate);
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('$providerName sign-in failed: $error')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accent = const Color(0xff63FF9B);

    return Scaffold(
      backgroundColor: const Color(0xff0B0B1D),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),

          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 70),

                Text(
                  "WELCOME BACK",

                  style: GoogleFonts.poppins(
                    color: accent,

                    fontSize: 30,

                    fontWeight: FontWeight.bold,

                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 70),

                buildField(
                  controller: emailController,

                  hint: "Email",

                  icon: Icons.email,
                ),

                const SizedBox(height: 25),

                buildField(
                  controller: passwordController,

                  hint: "Password",

                  icon: Icons.lock,

                  hide: true,
                ),

                const SizedBox(height: 50),

                SizedBox(
                  width: 250,

                  height: 55,

                  child: ElevatedButton(
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      final messenger = ScaffoldMessenger.of(context);

                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (email.isEmpty || password.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                          ),
                        );
                        return;
                      }

                      if (!mounted) return;
                      setState(() {
                        loading = true;
                      });

                      final user = await authService.login(
                        email: email,

                        password: password,
                      );

                      if (!mounted) return;
                      setState(() {
                        loading = false;
                      });

                      if (user != null) {
                        await SessionService.updateLastActive();
                        await SessionService.saveLastEmail(email);
                        await PermissionService.requestOnboardingPermissions();
                        if (!mounted) return;
                        Navigator.of(
                          this.context,
                        ).pushReplacementNamed(AppRoutes.biometricGate);
                      } else {
                        final err =
                            authService.lastError ??
                            'Login failed. Check credentials or network.';
                        messenger.showSnackBar(SnackBar(content: Text(err)));
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    child: loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "LOGIN",

                            style: TextStyle(
                              color: Colors.black,

                              fontSize: 18,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  'SIGN IN WITH',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _OAuthButton(
                      icon: Icons.g_mobiledata,
                      label: 'Google',
                      onPressed: loading
                          ? null
                          : () => _handleOauthLogin(
                              providerName: 'Google',
                              signIn: authService.signInWithGoogle,
                            ),
                    ),
                    const SizedBox(width: 14),
                    _OAuthButton(
                      icon: Icons.code,
                      label: 'GitHub',
                      onPressed: loading
                          ? null
                          : () => _handleOauthLogin(
                              providerName: 'GitHub',
                              signIn: authService.signInWithGitHub,
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Text(
                      "Don't have an account?",

                      style: TextStyle(color: Colors.grey),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },

                      child: Text(
                        "Sign Up",

                        style: GoogleFonts.poppins(
                          color: accent,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,

    required String hint,

    required IconData icon,

    bool hide = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff232334),

        borderRadius: BorderRadius.circular(35),
      ),

      child: TextField(
        controller: controller,

        obscureText: hide,

        style: const TextStyle(color: Colors.white),

        decoration: InputDecoration(
          hintText: hint,

          hintStyle: const TextStyle(color: Colors.grey),

          suffixIcon: Icon(icon, color: Colors.grey),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.all(25),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _OAuthButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}
