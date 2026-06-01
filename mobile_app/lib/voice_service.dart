import 'package:flutter/foundation.dart' show kIsWeb, ValueNotifier;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isInitialized = false;
  static List<dynamic> _availableVoices = [];
  
  static final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);

  static Future<void> init() async {
    if (_isInitialized) return;

    if (!kIsWeb) {
      // iOS-only audio session setup — not supported on web
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.defaultMode);
    }

    // Set up TTS handlers to update speaking state
    _flutterTts.setStartHandler(() {
      isSpeaking.value = true;
    });
    _flutterTts.setCompletionHandler(() {
      isSpeaking.value = false;
    });
    _flutterTts.setCancelHandler(() {
      isSpeaking.value = false;
    });
    _flutterTts.setErrorHandler((_) {
      isSpeaking.value = false;
    });

    // Cache available voices on all platforms (web uses browser Speech API voices)
    try {
      _availableVoices = await _flutterTts.getVoices ?? [];
    } catch (_) {
      _availableVoices = [];
    }

    _isInitialized = true;
  }

  /// Tries to select a voice matching the desired gender and language.
  /// Falls back gracefully if no match is found.
  static Future<void> _setVoice({required bool isGirl, required bool isBangla}) async {
    // Dynamic retrieval if the voice list was empty during initialization (very common on Web)
    if (_availableVoices.isEmpty) {
      for (int i = 0; i < 10; i++) {
        try {
          _availableVoices = await _flutterTts.getVoices ?? [];
        } catch (_) {}
        if (_availableVoices.isNotEmpty) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (_availableVoices.isEmpty) return;

    // Build a list of candidate voices filtered by locale
    final String targetLocale = isBangla ? 'bn' : 'en';

    // Keywords that suggest a female voice in TTS engine naming conventions (including Android's "bdf" and web tags)
    final femaleKeywords = ['female', 'woman', 'girl', 'fiona', 'samantha', 'victoria',
        'karen', 'kate', 'moira', 'tessa', 'veena', 'allison', 'ava', 'susan',
        'zira', 'hazel', 'heera', 'helena', 'nora', 'natural', 'bdf', 'f-local', 'f-network', '-f-'];
    // Keywords that suggest a male voice in TTS engine naming conventions (including Android's "bdm" and web tags)
    final maleKeywords = ['male', 'man', 'boy', 'daniel', 'alex', 'fred', 'jorge',
        'luca', 'oliver', 'thomas', 'david', 'mark', 'george', 'rishi', 'bdm', 'm-local', 'm-network', '-m-'];

    Map<String, String>? bestVoice;

    // Pass 1: Try to find a voice matching the target locale and containing gender-specific keywords
    for (final v in _availableVoices) {
      if (v is! Map) continue;
      final name = (v['name'] ?? '').toString().toLowerCase();
      final locale = (v['locale'] ?? '').toString().toLowerCase();

      if (!locale.startsWith(targetLocale)) continue;

      final isFemaleVoiceName = femaleKeywords.any((k) => name.contains(k)) ||
          (name.contains('google') && !name.contains('male'));
      final isMaleVoiceName = maleKeywords.any((k) => name.contains(k)) ||
          (name.contains('google') && name.contains('male'));

      final nameMatches = isGirl ? isFemaleVoiceName : isMaleVoiceName;

      if (nameMatches) {
        bestVoice = {'name': v['name'].toString(), 'locale': v['locale'].toString()};
        break;
      }
    }

    // Pass 2: If no match found, fallback to any voice of the correct locale that doesn't match the OPPOSITE gender's keywords
    if (bestVoice == null) {
      for (final v in _availableVoices) {
        if (v is! Map) continue;
        final name = (v['name'] ?? '').toString().toLowerCase();
        final locale = (v['locale'] ?? '').toString().toLowerCase();

        if (!locale.startsWith(targetLocale)) continue;

        final isFemaleVoiceName = femaleKeywords.any((k) => name.contains(k)) ||
            (name.contains('google') && !name.contains('male'));
        final isMaleVoiceName = maleKeywords.any((k) => name.contains(k)) ||
            (name.contains('google') && name.contains('male'));

        final oppositeMatches = isGirl ? isMaleVoiceName : isFemaleVoiceName;

        if (!oppositeMatches) {
          bestVoice = {'name': v['name'].toString(), 'locale': v['locale'].toString()};
          break;
        }
      }
    }

    // Pass 3: Final fallback to any voice matching target locale
    if (bestVoice == null) {
      for (final v in _availableVoices) {
        if (v is! Map) continue;
        final locale = (v['locale'] ?? '').toString().toLowerCase();

        if (locale.startsWith(targetLocale)) {
          bestVoice = {'name': v['name'].toString(), 'locale': v['locale'].toString()};
          break;
        }
      }
    }

    // If we found a matching voice, apply it
    if (bestVoice != null) {
      try {
        await _flutterTts.setVoice(bestVoice);
      } catch (_) {}
    }
  }

  static Future<void> speak(String text, {
    String gender = "Girl",
    String age = "5",
    String language = "English",
    String role = "",
    String name = "",
  }) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      int ageInt = int.tryParse(age) ?? 30;
      bool isBangla = !language.toLowerCase().contains("banglish") &&
          (language.toLowerCase().contains("bangla") || language.toLowerCase().contains("bengali"));
      
      String checkStr = "$gender $role $name".toLowerCase();
      bool isGirl = gender.toLowerCase().contains("girl") || gender.toLowerCase().contains("female");
      
      // Smart voice gender correction based on name/role keywords
      if (checkStr.contains('mom') || checkStr.contains('mother') || checkStr.contains('grandma') || checkStr.contains('grandmother') || checkStr.contains('aunt') || checkStr.contains('sister') || checkStr.contains('dida') || checkStr.contains('nani') || checkStr.contains('dadi') || checkStr.contains('thakuma')) {
        isGirl = true;
      }
      if (checkStr.contains('dad') || checkStr.contains('father') || checkStr.contains('grandpa') || checkStr.contains('grandfather') || checkStr.contains('uncle') || checkStr.contains('brother') || checkStr.contains('baba') || checkStr.contains('abba') || checkStr.contains('dadu') || checkStr.contains('nana') || checkStr.contains('dada')) {
        isGirl = false;
      }

      // ── Pitch & rate tuned per age ─────────────────────────────────────
      double pitch;
      double rate;

      if (ageInt <= 5) {
        pitch = isGirl ? 1.4 : 1.3;
        rate = 0.48;
      } else if (ageInt <= 8) {
        pitch = isGirl ? 1.3 : 1.2;
        rate = 0.5;
      } else if (ageInt <= 12) {
        pitch = isGirl ? 1.25 : 1.15;
        rate = 0.5;
      } else if (ageInt <= 25) {
        pitch = isGirl ? 1.1 : 0.95;
        rate = 0.52;
      } else if (ageInt > 55) {
        pitch = isGirl ? 0.9 : 0.8;
        rate = 0.46;
      } else {
        pitch = isGirl ? 1.05 : 0.9;
        rate = 0.5;
      }

      await _flutterTts.setPitch(pitch);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.setVolume(1.0);

      // Set language first, as changing language can reset the voice selection
      if (isBangla) {
        await _flutterTts.setLanguage("bn-BD");
      } else {
        await _flutterTts.setLanguage("en-US");
      }

      // ── Pick and apply a gender-appropriate voice AFTER language/pitch is set ───────────────────────────────
      await _setVoice(isGirl: isGirl, isBangla: isBangla);

      isSpeaking.value = true;
      await _flutterTts.speak(text);
    } catch (e) {
      isSpeaking.value = false;
      print('Speech synthesis error: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _flutterTts.stop();
      isSpeaking.value = false;
    } catch (e) {
      print('Error stopping speech: $e');
    }
  }
}
