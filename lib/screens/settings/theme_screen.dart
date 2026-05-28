import 'package:flutter/material.dart';

import '../../services/profile_service.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  bool _dark = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await ProfileService.loadProfile();
    if (!mounted) return;
    setState(() => _dark = profile.darkTheme);
  }

  Future<void> _select(bool dark) async {
    setState(() => _dark = dark);
    await ProfileService.updateTheme(dark);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),
      appBar: AppBar(title: const Text('Theme')),
      body: ListView(
        children: [
          _tile(
            title: 'Dark',
            subtitle: 'Recommended for this app',
            selected: _dark,
            onTap: () => _select(true),
          ),
          _tile(
            title: 'Light',
            subtitle: 'Switch to a brighter look',
            selected: !_dark,
            onTap: () => _select(false),
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? Icons.check_circle : Icons.circle_outlined,
        color: Colors.greenAccent,
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
    );
  }
}
