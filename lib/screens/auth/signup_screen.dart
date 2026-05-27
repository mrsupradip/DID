import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/auth_service.dart';
import '../profile/profile_setup_screen.dart';
import '../../services/session_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService authService = AuthService();

  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accent = const Color(0xffC08A68);

    return Scaffold(
      backgroundColor: const Color(0xff0B0B1D),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),

          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),

                Text(
                  "CREATE ACCOUNT",

                  style: GoogleFonts.poppins(
                    color: accent,

                    fontSize: 28,

                    fontWeight: FontWeight.bold,

                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 60),

                buildField(
                  controller: nameController,

                  hint: "Name",

                  icon: Icons.person,
                ),

                const SizedBox(height: 25),

                buildField(
                  controller: emailController,

                  hint: "Email",

                  icon: Icons.alternate_email,
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

                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (name.isEmpty || email.isEmpty || password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                          ),
                        );
                        return;
                      }

                      setState(() {
                        loading = true;
                      });

                      final user = await authService.signUp(
                        email: email,

                        password: password,
                      );

                      setState(() {
                        loading = false;
                      });

                      if (user != null) {
                        await SessionService.updateLastActive();
                        Navigator.pushReplacement(
                          context,

                          MaterialPageRoute(
                            builder: (_) => const ProfileSetupScreen(),
                          ),
                        );
                      } else {
                        final err =
                            authService.lastError ??
                            'Sign up failed. Check details or network.';
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(err)));
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),

                    child: loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text(
                            "SIGN UP",

                            style: TextStyle(
                              color: Colors.black,

                              fontSize: 18,

                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 50),

                Text(
                  "SIGN IN WITH",

                  style: GoogleFonts.poppins(
                    color: Colors.grey,

                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    social(Icons.facebook),

                    const SizedBox(width: 35),

                    social(Icons.g_mobiledata),

                    const SizedBox(width: 35),

                    social(Icons.apple),
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

  Widget social(IconData icon) {
    return Icon(icon, size: 42, color: Colors.white70);
  }
}
