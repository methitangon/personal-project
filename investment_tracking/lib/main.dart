import 'package:flutter/material.dart';
import 'app/app.dart'; // Make sure this path points to your main App widget
import 'core/di/injection_container.dart'
    as di; // Import the DI setup with a prefix

Future<void> main() async {
  // Ensure Flutter bindings are initialized before calling async code or using plugins
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetIt dependency injection setup
  await di.init();

  // Run the main Flutter application
  runApp(
      const MyApp()); // Assuming your main app widget is MyApp in app/app.dart
}

// MyApp and PropertyListScreen moved to separate files
