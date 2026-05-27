import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';
import '../../data/app_data.dart';
import '../../widgets/custom_chip.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppData.user;

    return Scaffold(
      backgroundColor: AppColors.background,

      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,

              children: [
                Container(
                  height: 220,

                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, Color(0xff0F172A)],

                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                Positioned(
                  top: 50,
                  right: 20,

                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },

                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                Positioned(
                  bottom: -55,
                  left: 0,
                  right: 0,

                  child: CircleAvatar(
                    radius: 58,

                    backgroundColor: AppColors.accent,

                    child: CircleAvatar(
                      radius: 54,

                      backgroundColor: AppColors.card,

                      child: const Icon(
                        Icons.person,
                        size: 55,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 70),

            Text(
              user.name,

              style: GoogleFonts.poppins(
                color: AppColors.text,

                fontSize: 28,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),

              child: Text(
                user.bio,

                textAlign: TextAlign.center,

                style: GoogleFonts.poppins(color: AppColors.subText),
              ),
            ),

            const SizedBox(height: 25),

            Wrap(
              spacing: 10,

              runSpacing: 10,

              children: user.skills
                  .map((skill) => CustomChip(title: skill))
                  .toList(),
            ),

            const SizedBox(height: 35),

            settingsTile(Icons.folder_open, "My Projects"),

            settingsTile(Icons.code, "GitHub"),

            settingsTile(Icons.people, "Connections"),

            settingsTile(Icons.star_border, "Achievements"),

            settingsTile(Icons.settings, "Settings"),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget settingsTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.card,

        borderRadius: BorderRadius.circular(20),
      ),

      child: Row(
        children: [
          Icon(icon, color: Colors.white70),

          const SizedBox(width: 15),

          Text(title, style: GoogleFonts.poppins(color: Colors.white)),

          const Spacer(),

          const Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey),
        ],
      ),
    );
  }
}
