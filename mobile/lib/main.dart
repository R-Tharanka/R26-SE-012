import 'package:flutter/material.dart';

import 'package:pepper_care/features/grading_forecast/screens/grading_forecast_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pepper Care',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const GradingForecastHomeScreen(),
    );
  }
}
