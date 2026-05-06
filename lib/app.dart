import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/radio_station/presentation/pages/diy_radio_page.dart';

class AuraRadioApp extends StatelessWidget {
  const AuraRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraRadio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.dark(),
      home: const DiyRadioPage(),
    );
  }
}
