import 'package:flutter/material.dart';

import 'core/theme/night_fm_theme.dart';
import 'features/shell/night_fm_shell.dart';

class AuraRadioApp extends StatelessWidget {
  const AuraRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Night FM',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: nightFmTheme(),
      home: const NightFmShell(),
    );
  }
}
