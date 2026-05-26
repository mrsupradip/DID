import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0b0d12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Column(
            children: [
              const SizedBox(height: 30),

              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: 220,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: implement create account logic
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
                    'Create Account',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
