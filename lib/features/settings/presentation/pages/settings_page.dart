import 'package:flutter/material.dart';

/// Placeholder for the Settings feature — real preferences (sound, music,
/// haptics, language, reset progress) are added in a later phase.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings (placeholder)')),
    );
  }
}
