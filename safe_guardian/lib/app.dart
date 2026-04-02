import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';

class SafeGuardianApp extends StatelessWidget {
  const SafeGuardianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '안심지킴이',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
