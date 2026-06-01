import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SttService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isInitialized = false;

  /// Starts listening to the microphone and returns the transcribed text.
  /// If it fails, returns a string starting with "ERROR:".
  static Future<String> listen({String language = "English"}) async {
    final completer = Completer<String>();

    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      return "ERROR: Microphone permission denied";
    }

    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          if (!completer.isCompleted) {
            completer.complete("ERROR: $error");
          }
        },
      );
    }

    if (!_isInitialized) {
      return "ERROR: Speech recognition not available on this device";
    }

    bool isBangla = !language.toLowerCase().contains("banglish") &&
        (language.toLowerCase().contains("bangla") || language.toLowerCase().contains("bengali"));

    String localeId = isBangla ? "bn_BD" : "en_US";

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          if (!completer.isCompleted) {
            completer.complete(result.recognizedWords);
          }
        }
      },
      localeId: localeId,
      cancelOnError: true,
      partialResults: false,
    );

    // Timeout fallback if the user doesn't say anything
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        _speech.stop();
        completer.complete("ERROR: Timeout listening");
      }
    });

    return completer.future;
  }

  static void stop() {
    if (_isInitialized) {
      _speech.stop();
    }
  }
}
