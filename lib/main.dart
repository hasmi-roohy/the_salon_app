import 'package:flutter/material.dart';
import 'package:the_salon_app/core/presentation/theme/app_theme.dart';
import 'package:the_salon_app/features/dashboard/presentation/pages/main_navigation_hub.dart';

void main() {
  runApp(const TheSalonApp());
}

class TheSalonApp extends StatelessWidget {
  const TheSalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Salon App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationHub(),
    );
  }
}