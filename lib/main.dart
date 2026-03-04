import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const StepFlowApp());
}

class StepFlowApp extends StatelessWidget {
  const StepFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StepFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00D1B2),
          secondary: Color(0xFF4CC9F0),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
