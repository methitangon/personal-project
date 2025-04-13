import 'package:flutter/material.dart';

// Placeholder screen for listing properties
class PropertyListScreen extends StatelessWidget {
  const PropertyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
      ),
      body: const Center(
        child: Text('Property List Placeholder'), // Placeholder content
      ),
    );
  }
}
