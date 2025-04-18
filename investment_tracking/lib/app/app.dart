import 'package:flutter/material.dart';
import '../features/property_tracking/presentation/pages/property_list_screen.dart'; // Import PropertyListScreen

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Investment Tracking',
      home: PropertyListScreen(), // Use the imported screen
    );
  }
}
