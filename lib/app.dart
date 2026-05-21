import 'package:flutter/material.dart';

import 'src/core/app_theme.dart';
import 'src/screens/tablet_home_screen.dart';

class DartFoodMesaApp extends StatelessWidget {
  const DartFoodMesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DartFood Mesa',
      theme: AppTheme.build(),
      home: const TabletHomeScreen(),
    );
  }
}
