import 'package:flutter/material.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  bool _dark = true;

  void _select(bool dark) {
    setState(() => _dark = dark);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(dark ? 'Dark theme selected' : 'Light theme selected'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(title: const Text("Theme")),

      body: Column(
        children: [
          RadioListTile<bool>(
            value: true,
            groupValue: _dark,
            onChanged: (v) => _select(v ?? true),
            title: const Text("Dark", style: TextStyle(color: Colors.white)),
          ),

          RadioListTile<bool>(
            value: false,
            groupValue: _dark,
            onChanged: (v) => _select(v ?? false),
            title: const Text("Light", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
