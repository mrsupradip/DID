import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'create_account_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0b0d12),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),

          child: Column(
            children: [
              const SizedBox(height: 70),

              // D!D LOGO
              Text(
                "D!D",
                style: GoogleFonts.orbitron(
                  fontSize: 80,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 5,
                ),
              ),

              const SizedBox(height: 70),

              // USERNAME
              TextField(
                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Colors.white70,
                  ),

                  hintText: "Enter Username",

                  hintStyle: TextStyle(color: Colors.grey.shade500),

                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),

                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // PASSWORD
              TextField(
                obscureText: true,

                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Colors.white70,
                  ),

                  hintText: "Enter Password",

                  hintStyle: TextStyle(color: Colors.grey.shade500),

                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),

                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 70),

              // LOGIN
              SizedBox(
                width: 220,
                height: 50,

                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },

                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),

                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // CREATE ACCOUNT
              SizedBox(
                width: 220,
                height: 50,

                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateAccountScreen(),
                      ),
                    );
                  },

                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),

                  child: const Text(
                    "Create Account",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const Spacer(),

              Icon(Icons.fingerprint, size: 65, color: Colors.grey.shade300),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
