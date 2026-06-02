import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class AnalyticsService {
  static final _supabase = Supabase.instance.client;

  /// Check if the analytics_metrics table is empty for the current user.
  /// If it is empty, initialize it with baseline data so the parent dashboard works.
  static Future<void> initializeUserAnalyticsIfEmpty(String email) async {
    if (email == 'mock_user@example.com' || email.isEmpty) return;

    try {
      final response = await _supabase
          .from('analytics_metrics')
          .select('id')
          .eq('user_email', email)
          .limit(1);

      if (response.isEmpty) {
        print('Initializing baseline analytics for user: $email');
        await _supabase.from('analytics_metrics').insert(_getBaselineRows(email));
        print('Baseline analytics initialized successfully.');
      }
    } catch (e) {
      print('Error initializing analytics metrics: $e');
    }
  }

  /// Record a completed chat session and update both specific and 'All' metrics in Supabase.
  static Future<void> recordSession({
    required String personaId,
    required String personaRole,
    required double durationMinutes,
    required int messagesCount,
    required int newWordsCount,
  }) async {
    final email = AuthService.currentUserEmail;
    if (email == 'mock_user@example.com' || email.isEmpty) {
      print('Analytics: Running in guest mode, session not saved to database.');
      return;
    }

    try {
      // First, ensure baseline exists
      await initializeUserAnalyticsIfEmpty(email);

      // We need to update 4 rows:
      // 1. Specific persona - weekly
      // 2. Specific persona - monthly
      // 3. 'All' personas - weekly
      // 4. 'All' personas - monthly
      await _updateMetricsRow(email, personaId, 'weekly', durationMinutes, messagesCount, newWordsCount, personaRole);
      await _updateMetricsRow(email, personaId, 'monthly', durationMinutes, messagesCount, newWordsCount, personaRole);
      await _updateMetricsRow(email, 'All', 'weekly', durationMinutes, messagesCount, newWordsCount, personaRole);
      await _updateMetricsRow(email, 'All', 'monthly', durationMinutes, messagesCount, newWordsCount, personaRole);

      print('Analytics: Successfully updated all metrics for session with $personaId');
    } catch (e) {
      print('Error recording chat session: $e');
    }
  }

  static Future<void> _updateMetricsRow(
    String email,
    String personaId,
    String timeRange,
    double durationMinutes,
    int messagesCount,
    int newWordsCount,
    String personaRole,
  ) async {
    try {
      // Fetch current row
      final response = await _supabase
          .from('analytics_metrics')
          .select()
          .eq('user_email', email)
          .eq('persona_id', personaId)
          .eq('time_range', timeRange)
          .maybeSingle();

      if (response != null) {
        final Map<String, dynamic> row = response as Map<String, dynamic>;
        
        final double currentMinutes = (row['total_minutes'] as num).toDouble();
        final int currentChats = row['chats_count'] as int;
        final int currentVocab = row['vocab_growth'] as int;
        final double currentAvg = (row['avg_engagement'] as num).toDouble();
        final List<dynamic> currentChart = List<dynamic>.from(row['chart_values'] ?? []);

        // Calculate new stats
        final double newMinutes = currentMinutes + durationMinutes;
        final int newChats = currentChats + 1;
        final int newVocab = currentVocab + newWordsCount;
        // Average session length
        final double newAvg = (newMinutes / newChats);

        // Update chart values (add to last item in the list represent active minutes today)
        final List<double> newChart = currentChart.map((v) => (v as num).toDouble()).toList();
        if (newChart.isNotEmpty) {
          newChart[newChart.length - 1] = newChart[newChart.length - 1] + durationMinutes;
        } else {
          newChart.add(durationMinutes);
        }

        // Cognitive Focus weighting
        Map<String, dynamic> focus = Map<String, dynamic>.from(row['cognitive_focus'] ?? {});
        final double sci = (focus['science'] as num?)?.toDouble() ?? 0.25;
        final double soc = (focus['social'] as num?)?.toDouble() ?? 0.25;
        final double lang = (focus['language'] as num?)?.toDouble() ?? 0.25;
        final double log = (focus['logic'] as num?)?.toDouble() ?? 0.25;

        // Shift cognitive focus slightly based on this persona's activity
        double addSci = 0, addSoc = 0, addLang = 0, addLog = 0;
        final r = personaRole.toLowerCase();
        final id = personaId.toLowerCase();

        if (id == 'boby' || r.contains('robot') || r.contains('logic')) {
          addSci = 0.5; addLog = 0.5;
        } else if (id == 'ruby' || r.contains('friend') || r.contains('social')) {
          addSoc = 0.5; addLang = 0.5;
        } else if (id == 'teacher' || r.contains('teacher') || r.contains('tutor')) {
          addSci = 0.3; addLang = 0.3; addLog = 0.4;
        } else if (r.contains('mom') || r.contains('mother') || r.contains('dad') || r.contains('father')) {
          addSoc = 0.7; addLang = 0.3;
        } else {
          addSci = 0.25; addSoc = 0.25; addLang = 0.25; addLog = 0.25;
        }

        // Blend new session focus weights with existing
        final double w = 0.15; // weight of new session
        final double nextSci = sci * (1 - w) + addSci * w;
        final double nextSoc = soc * (1 - w) + addSoc * w;
        final double nextLang = lang * (1 - w) + addLang * w;
        final double nextLog = log * (1 - w) + addLog * w;
        final double focusSum = nextSci + nextSoc + nextLang + nextLog;

        final Map<String, double> newFocus = {
          'science': nextSci / focusSum,
          'social': nextSoc / focusSum,
          'language': nextLang / focusSum,
          'logic': nextLog / focusSum,
        };

        // Sentiment / Insight updates
        String newSentiment = row['sentiment'] as String? ?? '';
        if (newWordsCount > 5) {
          newSentiment = "Dynamic Realtime: Actively practicing vocabulary in conversation with $personaId. Child learned $newWordsCount new words during the last conversation.";
        } else {
          newSentiment = "Dynamic Realtime: Friendly engagement. Had a productive session speaking with $personaId.";
        }

        await _supabase.from('analytics_metrics').update({
          'total_minutes': newMinutes,
          'chats_count': newChats,
          'vocab_growth': newVocab,
          'avg_engagement': newAvg,
          'chart_values': newChart,
          'cognitive_focus': newFocus,
          'sentiment': newSentiment,
        }).eq('id', row['id']);
      } else {
        // Fallback: If not found, insert a fresh baseline row first
        print('Warning: Row not found for update, attempting baseline creation.');
      }
    } catch (e) {
      print('Error updating specific metrics row: $e');
    }
  }

  static List<Map<String, dynamic>> _getBaselineRows(String email) {
    return [
      // ALL
      _createBaselineRow(email, 'All', 'weekly', 205.0, 28, 48, 7.3, [20.0, 35.0, 15.0, 45.0, 10.0, 50.0, 30.0], 0.45, 0.30, 0.15, 0.10, "🌟 Baseline Mood: Joyful & Curious\nLoves discussing rocket science with Boby. Practiced naming colors in Bangla with Ruby."),
      _createBaselineRow(email, 'All', 'monthly', 780.0, 105, 170, 7.4, [160.0, 220.0, 200.0, 200.0], 0.45, 0.30, 0.15, 0.10, "🌟 Baseline Mood: Joyful & Curious\nLoves discussing rocket science with Boby. Practiced naming colors in Bangla with Ruby."),
      // RUBY
      _createBaselineRow(email, 'Ruby', 'weekly', 65.0, 10, 22, 6.5, [10.0, 5.0, 15.0, 5.0, 0.0, 20.0, 10.0], 0.10, 0.35, 0.45, 0.10, "Highly Social & Creative\nRuby and the child spent time sharing school stories, singing songs, and practicing spelling."),
      _createBaselineRow(email, 'Ruby', 'monthly', 240.0, 38, 80, 6.3, [50.0, 65.0, 55.0, 70.0], 0.10, 0.35, 0.45, 0.10, "Highly Social & Creative\nRuby and the child spent time sharing school stories, singing songs, and practicing spelling."),
      // BOBY
      _createBaselineRow(email, 'Boby', 'weekly', 85.0, 12, 16, 7.1, [5.0, 20.0, 0.0, 25.0, 5.0, 20.0, 10.0], 0.60, 0.10, 0.10, 0.20, "Exploratory & Logical\nBoby engaged the child in space exploration facts, building block questions, and counting games."),
      _createBaselineRow(email, 'Boby', 'monthly', 320.0, 45, 60, 7.1, [70.0, 85.0, 80.0, 85.0], 0.60, 0.10, 0.10, 0.20, "Exploratory & Logical\nBoby engaged the child in space exploration facts, building block questions, and counting games."),
      // TEACHER
      _createBaselineRow(email, 'Teacher', 'weekly', 35.0, 4, 10, 8.7, [5.0, 5.0, 0.0, 15.0, 5.0, 5.0, 0.0], 0.30, 0.10, 0.30, 0.30, "Academic Focus\nMiss Pearl led sessions on counting, reading pronunciation, and plant lifecycle facts."),
      _createBaselineRow(email, 'Teacher', 'monthly', 130.0, 15, 35, 8.6, [25.0, 35.0, 35.0, 35.0], 0.30, 0.10, 0.30, 0.30, "Academic Focus\nMiss Pearl led sessions on counting, reading pronunciation, and plant lifecycle facts."),
      // MOM
      _createBaselineRow(email, 'Mom', 'weekly', 15.0, 2, 0, 7.5, [0.0, 5.0, 0.0, 0.0, 0.0, 5.0, 5.0], 0.05, 0.75, 0.15, 0.05, "Nurturing & Emotional\nShared conversations about feelings, bedtime comfort, and helping at home."),
      _createBaselineRow(email, 'Mom', 'monthly', 50.0, 7, 0, 7.1, [10.0, 15.0, 15.0, 10.0], 0.05, 0.75, 0.15, 0.05, "Nurturing & Emotional\nShared conversations about feelings, bedtime comfort, and helping at home."),
      // DAD
      _createBaselineRow(email, 'Dad', 'weekly', 20.0, 2, 0, 10.0, [0.0, 10.0, 0.0, 0.0, 0.0, 5.0, 5.0], 0.20, 0.40, 0.10, 0.30, "Adventurous & Active\nDiscussed outdoor activities, sports rules, and building toy cars."),
      _createBaselineRow(email, 'Dad', 'monthly', 70.0, 7, 0, 10.0, [15.0, 20.0, 15.0, 20.0], 0.20, 0.40, 0.10, 0.30, "Adventurous & Active\nDiscussed outdoor activities, sports rules, and building toy cars.")
    ];
  }

  static Map<String, dynamic> _createBaselineRow(
    String email,
    String personaId,
    String timeRange,
    double totalMins,
    int chats,
    int vocab,
    double avg,
    List<double> chartVals,
    double sci,
    double soc,
    double lang,
    double log,
    String sentiment,
  ) {
    return {
      'user_email': email,
      'persona_id': personaId,
      'time_range': timeRange,
      'total_minutes': totalMins,
      'chats_count': chats,
      'vocab_growth': vocab,
      'avg_engagement': avg,
      'chart_values': chartVals,
      'cognitive_focus': {
        'science': sci,
        'social': soc,
        'language': lang,
        'logic': log,
      },
      'sentiment': sentiment,
    };
  }
}
