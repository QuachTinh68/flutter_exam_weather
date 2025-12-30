import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notes_screen.dart';
import 'providers/auth_provider.dart';

class WeatherCalendarApp extends StatelessWidget {
  const WeatherCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.lightBlue,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Calendar',
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        // Sử dụng font Raleway cho headlines
        primaryTextTheme: baseTheme.textTheme.copyWith(
          headlineLarge: const TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/notes': (context) => const NotesScreen(),
        '/weather': (context) => const MainScreen(),
      },
      home: const MainScreen(), // Luôn cho phép xem lịch thời tiết
    );
  }
}
