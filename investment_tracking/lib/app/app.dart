import 'package:flutter/material.dart';
import '../features/property_tracking/presentation/pages/property_list_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Investment Tracking',
      home: PropertyListScreen(),
    );
  }
}
