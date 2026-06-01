import 'package:flutter/material.dart';

enum PersonaTheme { playroom, forest, lab, custom }

class RubyBobyTheme {
  final PersonaTheme theme;
  final Color primaryColor;
  final Color accentColor;
  final String backgroundAsset;
  final List<Color> gradientColors;

  RubyBobyTheme({
    required this.theme,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundAsset,
    required this.gradientColors,
  });

  static RubyBobyTheme getThemeForPersona(String personaId) {
    switch (personaId.toLowerCase()) {
      case 'ruby':
        return RubyBobyTheme(
          theme: PersonaTheme.playroom,
          primaryColor: Colors.pinkAccent,
          accentColor: Colors.orangeAccent,
          backgroundAsset: 'assets/bg_playroom.png',
          gradientColors: [Colors.pink[100]!, Colors.orange[50]!],
        );
      case 'boby':
        return RubyBobyTheme(
          theme: PersonaTheme.forest,
          primaryColor: Colors.greenAccent,
          accentColor: Colors.tealAccent,
          backgroundAsset: 'assets/bg_forest.png',
          gradientColors: [Colors.green[100]!, Colors.teal[50]!],
        );
      case 'teacher':
        return RubyBobyTheme(
          theme: PersonaTheme.lab,
          primaryColor: Colors.blueAccent,
          accentColor: Colors.lightBlueAccent,
          backgroundAsset: 'assets/bg_lab.png',
          gradientColors: [Colors.blue[100]!, Colors.white],
        );
      default:
        return RubyBobyTheme(
          theme: PersonaTheme.custom,
          primaryColor: Colors.purpleAccent,
          accentColor: Colors.deepPurpleAccent,
          backgroundAsset: 'assets/bg_generic.png',
          gradientColors: [Colors.purple[50]!, Colors.white],
        );
    }
  }
}
