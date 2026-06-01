import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyBALUTuFjIVUxGoRxkPCIoX-F6fc6Tto_Y');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "contents": [{"parts": [{"text": "Hello"}]}]
    }),
  );
  print('Status: \${response.statusCode}');
  print('Body: \${response.body}');
}
