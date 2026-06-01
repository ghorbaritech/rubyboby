import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'persona_service.dart';
import 'auth_service.dart';


class CustomPersona {
  final String id;
  final String name;
  final String traits;
  final String age;
  final String gender;
  final int colorValue;
  final String language;
  final String role; // persisted role/relationship
  final double faceZoom; // zoom factor for custom avatars
  final double faceYOffset; // vertical shift offset for custom avatars
  final String? imageBase64; // base64-encoded image, persisted in JSON
  final Uint8List? imageBytes; // decoded bytes, used for display (Image.memory)

  CustomPersona({
    required this.id,
    required this.name,
    required this.traits,
    required this.age,
    required this.gender,
    required this.colorValue,
    required this.language,
    this.role = 'Friend',
    this.faceZoom = 1.8,
    this.faceYOffset = -0.2,
    this.imageBase64,
    this.imageBytes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'traits': traits,
    'age': age,
    'gender': gender,
    'colorValue': colorValue,
    'language': language,
    'role': role,
    'faceZoom': faceZoom,
    'faceYOffset': faceYOffset,
    'imageBase64': imageBase64,
  };

  factory CustomPersona.fromJson(Map<String, dynamic> json) {
    final b64 = json['imageBase64'] as String?;
    Uint8List? bytes;
    if (b64 != null) {
      try { bytes = base64Decode(b64); } catch (_) {}
    }
    return CustomPersona(
      id: json['id'],
      name: json['name'],
      traits: json['traits'],
      age: json['age'] ?? "5",
      gender: json['gender'] ?? "Girl",
      colorValue: json['colorValue'] ?? Colors.pink[100]!.value,
      language: json['language'] ?? "English",
      role: json['role'] ?? "Friend",
      faceZoom: (json['faceZoom'] as num?)?.toDouble() ?? 1.8,
      faceYOffset: (json['faceYOffset'] as num?)?.toDouble() ?? -0.2,
      imageBase64: b64,
      imageBytes: bytes,
    );
  }
}

class PersonaState {
  static List<CustomPersona> savedPersonas = [];

  static Future<void> loadPersonas() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear in-memory cache to prevent carrying over personas from a previous session
    savedPersonas = [];
    
    final String key = 'saved_personas_${AuthService.currentUserEmail}';

    // 1. Load from user-specific local prefs
    final String? personasJson = prefs.getString(key);
    if (personasJson != null) {
      final List<dynamic> decoded = jsonDecode(personasJson);
      savedPersonas = decoded.map((item) => CustomPersona.fromJson(item)).toList();
    }

    // 2. Load from backend to sync across rebuilds
    final backendPersonas = await PersonaService.getPersonas();
    if (backendPersonas != null) {
      bool changed = false;
      for (final bp in backendPersonas) {
        final cp = CustomPersona.fromJson(bp);
        final idx = savedPersonas.indexWhere((p) => p.id == cp.id);
        if (idx == -1) {
          savedPersonas.add(cp);
          changed = true;
        } else {
          // Sync update from backend
          savedPersonas[idx] = cp;
          changed = true;
        }
      }
      if (changed) {
        final String encoded = jsonEncode(savedPersonas.map((p) => p.toJson()).toList());
        await prefs.setString(key, encoded);
      }
    }
    
    // Seed default personas if they are missing
    bool rubyExists = savedPersonas.any((p) => p.id == 'Ruby');
    bool bobyExists = savedPersonas.any((p) => p.id == 'Boby');
    bool teacherExists = savedPersonas.any((p) => p.id == 'Teacher');
    bool momExists = savedPersonas.any((p) => p.id == 'Mom');
    bool dadExists = savedPersonas.any((p) => p.id == 'Dad');

    bool changed = false;
    if (!rubyExists) {
      savedPersonas.insert(0, CustomPersona(
        id: 'Ruby', name: 'Ruby', traits: 'Your Fun Girl Friend', age: '5',
        gender: 'Girl', colorValue: Colors.pink[100]!.value, language: 'English',
        role: 'Friend',
      ));
      changed = true;
    }
    if (!bobyExists) {
      savedPersonas.insert(1, CustomPersona(
        id: 'Boby', name: 'Boby', traits: 'Your Cool Boy Friend', age: '6',
        gender: 'Boy', colorValue: Colors.blue[100]!.value, language: 'English',
        role: 'Friend',
      ));
      changed = true;
    }
    if (!teacherExists) {
      savedPersonas.insert(2, CustomPersona(
        id: 'Teacher', name: 'Miss Pearl', traits: 'Learn & Grow Together', age: '28',
        gender: 'Girl', colorValue: Colors.purple[100]!.value, language: 'English',
        role: 'Teacher',
      ));
      changed = true;
    }
    if (!momExists) {
      savedPersonas.add(CustomPersona(
        id: 'Mom', name: 'Mom', traits: 'Loving · Warm · Gentle', age: '42',
        gender: 'Girl', colorValue: Colors.pink[100]!.value, language: 'English',
        role: 'Mom',
      ));
      changed = true;
    }
    if (!dadExists) {
      savedPersonas.add(CustomPersona(
        id: 'Dad', name: 'Dad', traits: 'Playful · Adventurous · Strong', age: '45',
        gender: 'Boy', colorValue: Colors.blue[100]!.value, language: 'English',
        role: 'Dad',
      ));
      changed = true;
    }

    if (changed) {
      await _saveToPrefs();
    }
  }

  static Future<void> addPersona(CustomPersona persona) async {
    savedPersonas.add(persona);
    await _saveToPrefs();
  }

  static Future<void> updatePersona(CustomPersona persona) async {
    final index = savedPersonas.indexWhere((p) => p.id == persona.id);
    if (index != -1) {
      savedPersonas[index] = persona;
      await _saveToPrefs();
    }
  }
  
  static Future<void> deletePersona(String id) async {
    savedPersonas.removeWhere((p) => p.id == id);
    await _saveToPrefs();
    await PersonaService.deletePersona(id);
  }

  static Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(savedPersonas.map((p) => p.toJson()).toList());
    final String key = 'saved_personas_${AuthService.currentUserEmail}';
    await prefs.setString(key, encoded);
  }
}
