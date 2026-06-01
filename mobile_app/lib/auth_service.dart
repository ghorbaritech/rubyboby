import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static String currentUserEmail = 'mock_user@example.com';
  static String currentUserName = 'Guest Parent';
  
  // Loaded from environment or set dynamically
  static String? googleClientId = const String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '413982991748-g585l9nefab5a4rbo2rscdhmnnaif5r0.apps.googleusercontent.com');

  static Future<void> loadSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user.email != null) {
        currentUserEmail = session.user.email!;
        currentUserName = session.user.userMetadata?['full_name'] ?? 'Guest Parent';
      } else {
        final prefs = await SharedPreferences.getInstance();
        currentUserEmail = prefs.getString('user_email') ?? 'mock_user@example.com';
        currentUserName = prefs.getString('user_name') ?? 'Guest Parent';
      }
    } catch (_) {}
  }

  static Future<void> saveSession(String email, [String? displayName]) async {
    currentUserEmail = email;
    if (displayName != null && displayName.isNotEmpty) {
      currentUserName = displayName;
    } else {
      final parts = email.split('@');
      String name = parts[0].replaceAll(RegExp(r'[._-]'), ' ');
      currentUserName = name.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', currentUserName);
    } catch (_) {}
  }

  static GoogleSignIn _buildGoogleSignIn() {
    final clientId = (googleClientId != null && googleClientId!.isNotEmpty)
        ? googleClientId!
        : '413982991748-ntgb5dfnkfo23h6mhsvparv23jjdh5td.apps.googleusercontent.com';

    debugPrint("Google Sign-In: using client ID (should be Web Client ID): $clientId");

    // On Android: use serverClientId (clientId is ignored by the plugin)
    // On Web/iOS: use clientId
    if (!kIsWeb && Platform.isAndroid) {
      return GoogleSignIn(
        serverClientId: clientId,
        scopes: ['email', 'profile'],
      );
    } else {
      return GoogleSignIn(
        clientId: clientId,
        scopes: ['email', 'profile'],
      );
    }
  }

  static Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = _buildGoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        final idToken = auth.idToken;
        final accessToken = auth.accessToken;

        if (idToken != null) {
          // Authenticate with Supabase using the Google ID token
          final response = await Supabase.instance.client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );

          final email = response.user?.email ?? account.email;
          final name = response.user?.userMetadata?['full_name'] ?? account.displayName;
          await saveSession(email, name);
        } else {
          // Fallback: no idToken (e.g. web simulator without proper setup)
          await saveSession(account.email, account.displayName);
        }
      }
      return account;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    currentUserEmail = 'mock_user@example.com';
    currentUserName = 'Guest Parent';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_email');
      await prefs.remove('user_name');

      // Sign out of Supabase
      await Supabase.instance.client.auth.signOut();

      // Sign out of Google
      final GoogleSignIn googleSignIn = _buildGoogleSignIn();
      await googleSignIn.signOut();
    } catch (_) {}
  }

  /// Simple parental verification logic.
  /// In a real app, this would involve a complex mathematical challenge 
  /// or biometric authentication to ensure an adult is accessing the settings.
  static Future<bool> verifyParent(BuildContext context) async {
    bool verified = false;
    
    int a = 12;
    int b = 15;
    int? result;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Parental Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please solve this to continue: $a + $b = ?'),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  result = int.tryParse(value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (result == (a + b)) {
                  verified = true;
                  Navigator.pop(context);
                } else {
                  // Show error or shake
                }
              },
              child: const Text('Verify'),
            ),
          ],
        );
      },
    );

    return verified;
  }
}
