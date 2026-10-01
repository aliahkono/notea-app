import 'package:flutter/material.dart';

import 'profile_screens.dart';

/// The old SettingsTabView now opens the combined Profile & Settings screen
/// from the redesign (every gear icon in the app leads here).
class SettingsTabView extends StatelessWidget {
  const SettingsTabView({super.key});

  @override
  Widget build(BuildContext context) => const ProfileSettingsScreen();
}
