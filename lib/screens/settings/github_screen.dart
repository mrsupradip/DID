import 'package:flutter/material.dart';

class GithubScreen extends StatefulWidget {
  const GithubScreen({super.key});

  @override
  State<GithubScreen> createState() => _GithubScreenState();
}

class _GithubScreenState extends State<GithubScreen> {
  bool _connected = false;

  void _toggle() {
    setState(() => _connected = !_connected);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_connected ? 'GitHub connected' : 'GitHub disconnected'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff101522),

      appBar: AppBar(title: const Text("Connected GitHub")),

      body: Center(
        child: ElevatedButton(
          onPressed: _toggle,

          child: Text(_connected ? 'Disconnect GitHub' : 'Connect GitHub'),
        ),
      ),
    );
  }
}
