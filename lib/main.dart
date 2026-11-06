import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CompanionApp());
}

class CompanionApp extends StatelessWidget {
  const CompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    const blush = Color(0xFFE58AA5);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My AI Companion',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: blush,
          brightness: Brightness.light,
          surface: const Color(0xFFFFF8FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8FA),
        fontFamily: 'Roboto',
      ),
      home: const ChatScreen(),
    );
  }
}
