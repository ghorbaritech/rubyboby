import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=AIzaSyAF4OYTsYMFoMJwwmWFI-f9GEl1d1qZxF4');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "systemInstruction": {
        "parts": [{"text": "You are a pirate."}]
      },
      "contents": [{"parts": [{"text": "Hello"}]}]
    }),
  );
  print('Status: ' + response.statusCode.toString());
  print('Body: ' + response.body);
}
