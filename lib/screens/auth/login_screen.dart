import 'package:firebase_auth/firebase_auth.dart';
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

  Future<bool> _requireVerifiedEmail(User user, {required String email}) async {
    await user.sendEmailVerification();
    if (!mounted) return false;

    var checking = false;
    var status = 'We sent a verification link to $email.';

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> checkNow() async {
              if (checking) return;
              setDialogState(() => checking = true);
              try {
                await user.reload();
                final refreshedUser = FirebaseAuth.instance.currentUser;
                if (refreshedUser?.emailVerified == true) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext, true);
                  }
                  return;
                }

                setDialogState(
                  () => status =
                      'Email not verified yet. Open the link and try again.',
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => checking = false);
                }
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xff101522),
              title: const Text('Verify your email'),
              content: Text(
                status,
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: checking
                      ? null
                      : () async {
                          await user.sendEmailVerification();
                          if (dialogContext.mounted) {
                            setDialogState(
                              () => status = 'Verification email sent again.',
                            );
                          }
                        },
                  child: const Text('Resend'),
                ),
                ElevatedButton(
                  onPressed: checking ? null : checkNow,
                  child: Text(checking ? 'Checking...' : 'I verified it'),
                ),
              ],
            );
          },
        );
      },
    );

    return verified == true;
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
                        if (!user.emailVerified) {
                          final verified = await _requireVerifiedEmail(
                            user,
                            email: email,
                          );
                          if (!verified) {
                            await authService.logout();
                            if (!mounted) return;
                            setState(() => loading = false);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please verify your email before logging in.',
                                ),
                              ),
                            );
                            return;
                          }
                        }

                        await FirestoreService().updateUser(
                          uid: user.uid,
                          data: {
                            'uid': user.uid,
                            'email': email,
                            'lastLoginAt': DateTime.now(),
                          },
                        );
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
