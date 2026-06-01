import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static Future<String> generateResponse({
    required String userText,
    required String personaName,
    required String age,
    required String traits,
    required String language,
  }) async {
    if (_apiKey.isEmpty) {
      print("Error: GEMINI_API_KEY is not defined. Please run/build the app with --dart-define=GEMINI_API_KEY=your_api_key");
      return "I'm having a little trouble thinking right now. Let's try again in a minute!";
    }

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$_apiKey');

    final systemInstruction = "You are $personaName, a $age-year-old character/friend. "
        "Your personality is: $traits. "
        "You are talking to a user (likely a child) in a friendly conversation. "
        "Keep your answers very short (1-2 sentences maximum). Use simple, conversational words. "
        "Act completely in character and never break character. "
        "Here is the most important rule for your behavior: You must ALWAYS be highly conversational and reciprocal. "
        "If the user asks you a question (like 'How are you?'), you must answer them, and then ask them a relevant question back (like 'I am good, thanks! How are you today?'). "
        "If the user makes a statement (like 'I like Talking Tom'), you must acknowledge it nicely, and then ask a related question (like 'Yes, Talking Tom is super cool! Do you like teddy bears too?'). "
        "Never end your turn without asking a question to keep the conversation going. "
        "Do not use any emojis, asterisks, or special symbols because your response will be read by a voice engine. "
        "IMPORTANT LANGUAGE RULE: You must ONLY converse in $language. "
        "If the language is 'Bangla (Native)' or 'Bengali', you MUST ONLY use the native Bengali alphabet script (e.g., 'আমি ভালো আছি'). "
        "If the language is 'Banglish (Romanized)', you MUST ONLY use English letters to write Bengali words phonetically (e.g., 'Ami valo achi'), and NEVER use the Bengali alphabet. "
        "If the user speaks in another language, gently bring the conversation back to $language.";

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {"text": systemInstruction}
            ]
          },
          "contents": [
            {
              "parts": [
                {"text": userText}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'] as String;
          return content.trim().replaceAll('*', '').replaceAll('#', '');
        }
      } else {
        print("Gemini API Error: ${response.statusCode} - ${response.body}");
        return "I'm having a little trouble thinking right now. Let's try again in a minute!";
      }
      return "I didn't quite catch that. Can you say it again?";
    } catch (e) {
      print("Gemini Network Error: \$e");
      return "My brain is feeling a bit dizzy! Can we try again later?";
    }
  }
}
