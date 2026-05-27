import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F3F3),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,

              children: [
                Container(
                  height: 230,

                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://picsum.photos/700/500"),

                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Positioned(
                  top: 40,
                  right: 20,

                  child: Icon(Icons.favorite_border, color: Colors.white),
                ),

                Positioned(
                  bottom: -50,
                  left: 0,
                  right: 0,

                  child: const CircleAvatar(
                    radius: 55,

                    backgroundImage: NetworkImage("https://i.pravatar.cc/300"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 65),

            Text(
              "Supradip",

              style: GoogleFonts.poppins(
                fontSize: 28,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Build in silence.\nDeploy loudly 🚀",

              textAlign: TextAlign.center,

              style: GoogleFonts.poppins(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            settingsTile(Icons.location_on_outlined, "My Projects"),

            settingsTile(Icons.person_outline, "Account"),

            settingsTile(Icons.notifications_none, "Notifications"),

            settingsTile(Icons.devices, "Devices"),

            settingsTile(Icons.lock_outline, "Password"),

            settingsTile(Icons.code, "Skills"),
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
        color: Colors.white,

        borderRadius: BorderRadius.circular(15),
      ),

      child: Row(
        children: [
          Icon(icon, color: Colors.grey),

          const SizedBox(width: 15),

          Text(title, style: GoogleFonts.poppins(fontSize: 15)),

          const Spacer(),

          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
