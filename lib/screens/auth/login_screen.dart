import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/auth_service.dart';
import '../../routes/app_routes.dart';
import '../../services/permission_service.dart';
import 'signup_screen.dart';
import '../../services/session_service.dart';

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

                      setState(() {
                        loading = true;
                      });

                      final user = await authService.login(
                        email: email,

                        password: password,
                      );

                      setState(() {
                        loading = false;
                      });

                      if (user != null) {
                        await SessionService.updateLastActive();
                        await SessionService.saveLastEmail(email);
                        await PermissionService.requestOnboardingPermissions();
                        if (!context.mounted) return;
                        Navigator.of(
                          context,
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
