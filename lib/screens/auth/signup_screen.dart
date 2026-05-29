import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/auth_service.dart';

import '../profile/profile_setup_screen.dart';
import '../../services/permission_service.dart';
import '../../services/session_service.dart';
import '../settings/terms_conditions_screen.dart';
import '../../services/user_service.dart';
import '../../services/firestore_service.dart';

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
  bool acceptedTerms = false;

  Future<bool> _showTermsAcceptanceSheet() async {
    bool localAccepted = acceptedTerms;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xff101522),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please read and accept these rules before creating your account.',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(height: 280, child: const TermsConditionsScreen()),
                    const SizedBox(height: 14),
                    CheckboxListTile(
                      value: localAccepted,
                      onChanged: (value) {
                        setSheetState(() => localAccepted = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.greenAccent,
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'I accept the Terms & Conditions',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: localAccepted
                            ? () => Navigator.pop(sheetContext, true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      if (!mounted) return false;
      setState(() {
        acceptedTerms = true;
      });
      return true;
    }

    return acceptedTerms;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _ensureUserDocExists({
    required String uid,
    required String name,
    required String email,
  }) async {
    final fs = FirestoreService();
    await fs.updateUser(
      uid: uid,
      data: {
        'uid': uid,
        'name': name,
        'email': email,
        'bio': '',
        'github': '',
        'skills': <String>[],
        'profileImage': '',
        'createdAt': DateTime.now(),
      },
    );
  }

  Future<void> _handleOauth({
    required Future<dynamic> Function() signIn,

    required String authProviderName,
  }) async {
    FocusScope.of(context).unfocus();

    if (loading) return;
    setState(() => loading = true);

    try {
      final user = await signIn();
      if (!mounted) return;

      if (user == null) {
        final err =
            authService.lastError ?? '$authProviderName sign-in failed.';

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(err)));

        return;
      }

      final name = user.displayName ?? 'Developer';
      final email = user.email ?? '';

      UserService.updateCurrentUser(
        id: user.uid,
        name: name,
        email: email,
        bio: '',
        github: '',
        skills: const [],
        profileImage: '',
      );

      await _ensureUserDocExists(uid: user.uid, name: name, email: email);
      if (!mounted) return;

      await SessionService.updateLastActive();
      if (!mounted) return;

      await PermissionService.requestOnboardingPermissions();
      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xffC08A68);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 34, 93),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Text(
                  'CREATE ACCOUNT',
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
                  hint: 'Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 25),
                buildField(
                  controller: emailController,
                  hint: 'Email',
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 25),
                buildField(
                  controller: passwordController,
                  hint: 'Password',
                  icon: Icons.lock,
                  hide: true,
                ),
                const SizedBox(height: 50),
                CheckboxListTile(
                  value: acceptedTerms,
                  onChanged: (value) {
                    setState(() => acceptedTerms = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: accent,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'I accept the Terms & Conditions',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsConditionsScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Read the app rules and privacy policy',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 160, 228, 196),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 250,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      FocusScope.of(context).unfocus();
                      final messenger = ScaffoldMessenger.of(context);

                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final password = passwordController.text.trim();

                      if (name.isEmpty || email.isEmpty || password.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                          ),
                        );
                        return;
                      }

                      if (!acceptedTerms) {
                        final accepted = await _showTermsAcceptanceSheet();
                        if (!accepted) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Accept the Terms & Conditions to continue',
                              ),
                            ),
                          );
                        }
                        if (!accepted) return;
                      }

                      if (!mounted) return;
                      setState(() => loading = true);

                      final user = await authService.signUp(
                        email: email,
                        password: password,
                      );

                      if (!mounted) return;
                      setState(() => loading = false);

                      if (user != null) {
                        UserService.updateCurrentUser(
                          id: user.uid,
                          name: name,
                          email: email,
                          bio: '',
                          github: '',
                          skills: const [],
                          profileImage: '',
                        );

                        await SessionService.updateLastActive();
                        await PermissionService.requestOnboardingPermissions();

                        if (!mounted) return;
                        Navigator.pushReplacement(
                          this.context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileSetupScreen(),
                          ),
                        );
                      } else {
                        if (!mounted) return;
                        final err =
                            authService.lastError ??
                            'Sign up failed. Check details or network.';
                        messenger.showSnackBar(SnackBar(content: Text(err)));
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
                            'SIGN UP',
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
                  'SIGN IN WITH',
                  style: GoogleFonts.poppins(
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      icon: Icons.g_mobiledata,
                      label: 'Google',
                      onPressed: loading
                          ? null
                          : () => _handleOauth(
                              authProviderName: 'Google',
                              signIn: authService.signInWithGoogle,
                            ),
                    ),
                    const SizedBox(width: 18),
                    _SocialButton(
                      icon: Icons.code,
                      label: 'GitHub',
                      onPressed: loading
                          ? null
                          : () => _handleOauth(
                              authProviderName: 'GitHub',
                              signIn: authService.signInWithGitHub,
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
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 34),
        label: Text(label, style: const TextStyle(fontSize: 10)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white10,
          foregroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
