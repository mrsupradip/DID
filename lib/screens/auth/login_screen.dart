import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 70),

              Text(
                "Welcome Back",
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Dive Into Development",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),

              const SizedBox(height: 60),

              TextField(
                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  hintText: "Email",

                  hintStyle: const TextStyle(color: Colors.grey),

                  filled: true,

                  fillColor: Colors.grey.shade900,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),

                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                obscureText: true,

                style: const TextStyle(color: Colors.white),

                decoration: InputDecoration(
                  hintText: "Password",

                  hintStyle: const TextStyle(color: Colors.grey),

                  filled: true,

                  fillColor: Colors.grey.shade900,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),

                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  onPressed: () {},

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),

                  child: const Text("Login"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
