// MINIMAL TEST: Only import flutter/material
// This is the absolute simplest Flutter app to test web rendering
import 'package:flutter/material.dart';

void main() {
  runApp(const BareApp());
}

class BareApp extends StatelessWidget {
  const BareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vespara',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Scaffold(
        backgroundColor: Color(0xFF1A1523),
        body: Center(
          child: Text(
            'VESPARA',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE0D8EA),
              letterSpacing: 10,
            ),
          ),
        ),
      ),
    );
  }
}
