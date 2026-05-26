import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

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

                buildField("Name", Icons.person),

                const SizedBox(height: 25),

                buildField("Email", Icons.alternate_email),

                const SizedBox(height: 25),

                buildField("Password", Icons.lock, true),

                const SizedBox(height: 50),

                SizedBox(
                  width: 250,
                  height: 55,

                  child: OutlinedButton(
                    onPressed: () {},

                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: accent),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),

                    child: Text(
                      "SIGN UP",
                      style: GoogleFonts.poppins(
                        color: accent,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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

  Widget buildField(String hint, IconData icon, [bool hide = false]) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xff232334),

        borderRadius: BorderRadius.circular(35),
      ),

      child: TextField(
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
