git initimport 'package:flutter/material.dart';
import 'screens/auth_screen.dart';

void main() => runApp(const FitnessApp());

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  static const lime = Color(0xFFD4FF00);
  static const background = Color(0xFF080A0A);
  static const surface = Color(0xFF171A1A);

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Fitness Independiente',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: background,
          colorScheme: const ColorScheme.dark(
            primary: lime,
            secondary: lime,
            surface: surface,
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: background,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            color: surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: Color(0xFF282D2D)),
            ),
          ),
        ),
        home: const AuthScreen(),
      );
}
