import 'package:flutter/material.dart';
import 'subscription_service.dart';
import 'ai_service.dart';
import 'persona_state.dart';
import 'persona_profile_screen.dart';
import 'auth_service.dart';
import 'analytics_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  Widget _buildParentProfileHeader() {
    final email = AuthService.currentUserEmail;
    final isGoogle = email.contains('@gmail.com') || email != 'mock_user@example.com';
    
    String displayName = 'Parent';
    String initial = 'P';
    Color avatarColor = Colors.pinkAccent;
    
    if (email == 'ahmed.rakib@gmail.com') {
      displayName = 'Ahmed Rakib';
      initial = 'A';
      avatarColor = Colors.blueAccent;
    } else if (email == 'guest.parent@gmail.com') {
      displayName = 'Guest Parent';
      initial = 'G';
      avatarColor = Colors.deepOrangeAccent;
    } else if (email != 'mock_user@example.com') {
      final parts = email.split('@');
      displayName = parts[0].replaceAll(RegExp(r'[._-]'), ' ');
      displayName = displayName.split(' ').map((word) {
        if (word.isEmpty) return '';
        return word[0].toUpperCase() + word.substring(1);
      }).join(' ');
      initial = displayName.isNotEmpty ? displayName[0] : 'U';
      final hash = email.hashCode;
      final colors = [
        Colors.blueAccent,
        Colors.deepOrangeAccent,
        Colors.purpleAccent,
        Colors.teal,
        Colors.indigoAccent,
        Colors.green,
      ];
      avatarColor = colors[hash.abs() % colors.length];
    } else {
      displayName = 'Guest Parent';
      initial = 'G';
      avatarColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: avatarColor,
            child: Text(
              initial,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (isGoogle)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFDADCE0), width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          child: CustomPaint(painter: _GoogleLogoSmallPainter()),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Signed in with Google',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Control Center'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header showing Gmail sign-in status
            _buildParentProfileHeader(),

            // Subscription Status Card
            _buildSubscriptionCard(context),
            const SizedBox(height: 30),

            // Interactive Analytics Dashboard
            const AnalyticsDashboardView(),
            const SizedBox(height: 30),

            const Text(
              'Manage Friends & Personas',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // List of editable personas
            ...PersonaState.savedPersonas.map((p) {
              final isDefault = p.id == 'Ruby' || p.id == 'Boby' || p.id == 'Teacher' || p.id == 'Mom' || p.id == 'Dad';
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(p.colorValue),
                    child: const Icon(Icons.face_rounded, color: Colors.white),
                  ),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Language: ${p.language}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Edit'),
                        onPressed: () async {
                          final res = await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => PersonaProfileScreen(editingPersona: p)
                          ));
                          if (res == true) setState(() {});
                        },
                      ),
                      if (!isDefault)
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Friend?'),
                                content: Text('Are you sure you want to remove ${p.name}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await PersonaState.deletePersona(p.id);
                              setState(() {});
                            }
                          },
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 30),

            const Text(
              'Recent Conversations',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // Conversation History List
            _buildConversationTile('Talking with Ruby', '2 hours ago', 'Discussed favorite animals.'),
            _buildConversationTile('Lesson with Teacher', 'Yesterday', 'Learned about the Solar System.'),
            _buildConversationTile('Chat with Dadi Ma', '2 days ago', 'Storytime about a brave tiger.'),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context) {
    bool isPremium = SubscriptionService.currentTier == SubscriptionTier.premium;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium ? [Colors.purple, Colors.pinkAccent] : [Colors.grey[700]!, Colors.grey[800]!],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(isPremium ? Icons.star : Icons.star_border, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium Member' : 'Free Plan',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  isPremium ? 'Full access unlocked' : 'Upgrade for unlimited personas',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          if (!isPremium)
            ElevatedButton(
              onPressed: () => SubscriptionService.upgradeToPremium(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              child: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String content, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30, color: Colors.black54),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(content, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(String title, String time, String summary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(summary),
        trailing: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        leading: const CircleAvatar(backgroundColor: Colors.pinkAccent, child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20)),
      ),
    );
  }
}

// ─── Analytics Dashboard Stateful Widget ──────────────────────────────────────

class AnalyticsDashboardView extends StatefulWidget {
  const AnalyticsDashboardView({super.key});

  @override
  State<AnalyticsDashboardView> createState() => _AnalyticsDashboardViewState();
}

class _AnalyticsDashboardViewState extends State<AnalyticsDashboardView> {
  bool _isWeekly = true;
  int? _hoveredIndex;

  String _selectedPersonaId = 'All';
  String _selectedDateRange = '7days';

  final List<String> _weeklyDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<String> _monthlyWeeks = ['W1', 'W2', 'W3', 'W4'];

  List<dynamic> _supabaseAnalytics = [];
  bool _loadingAnalytics = false;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsFromSupabase();
  }

  Future<void> _loadAnalyticsFromSupabase() async {
    if (!mounted) return;
    setState(() => _loadingAnalytics = true);
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('analytics_metrics')
          .select()
          .eq('user_email', AuthService.currentUserEmail);
          
      if (response.isEmpty && AuthService.currentUserEmail != 'mock_user@example.com') {
        // Initialize user analytics in DB with baseline values
        await AnalyticsService.initializeUserAnalyticsIfEmpty(AuthService.currentUserEmail);
        
        // Re-fetch from DB
        final List<dynamic> reFetched = await Supabase.instance.client
            .from('analytics_metrics')
            .select()
            .eq('user_email', AuthService.currentUserEmail);
            
        if (mounted) {
          setState(() {
            _supabaseAnalytics = reFetched;
            _loadingAnalytics = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _supabaseAnalytics = response;
            _loadingAnalytics = false;
          });
        }
      }
    } catch (e) {
      print('Error loading analytics from Supabase: $e');
      if (mounted) {
        setState(() => _loadingAnalytics = false);
      }
    }
  }

  Map<String, dynamic> _getFilteredData() {
    final is7Days = _selectedDateRange == '7days';
    final isLastMonth = _selectedDateRange == 'last_month';
    
    // Try custom matching from Supabase table
    final String targetRange = (_selectedDateRange == '7days' || _selectedDateRange == '30days')
        ? (_isWeekly ? 'weekly' : 'monthly')
        : (_selectedDateRange == 'this_month' ? 'monthly' : 'monthly');
    
    Map<String, dynamic>? match;
    for (final row in _supabaseAnalytics) {
      if (row is Map<String, dynamic> &&
          row['persona_id'] == _selectedPersonaId &&
          row['time_range'] == targetRange) {
        match = row;
        break;
      }
    }

    if (match != null) {
      final double totalMins = (match['total_minutes'] as num).toDouble();
      final int chats = match['chats_count'] as int;
      final int words = match['vocab_growth'] as int;
      final double avgMins = (match['avg_engagement'] as num).toDouble();
      final List<dynamic> rawChart = match['chart_values'] as List<dynamic>;
      final List<double> chartVals = rawChart.map((v) => (v as num).toDouble()).toList();
      final List<String> chartLabels = _isWeekly ? _weeklyDays : _monthlyWeeks;
      
      final Map<String, dynamic> focus = match['cognitive_focus'] as Map<String, dynamic>;
      final double sci = (focus['science'] as num?)?.toDouble() ?? 0.25;
      final double soc = (focus['social'] as num?)?.toDouble() ?? 0.25;
      final double lang = (focus['language'] as num?)?.toDouble() ?? 0.25;
      final double log = (focus['logic'] as num?)?.toDouble() ?? 0.25;
      final String sentiment = match['sentiment'] as String;

      return {
        'totalTime': '${totalMins.round()}m',
        'chatsCount': chats.toString(),
        'vocabGrowth': words > 0 ? '+$words' : '0',
        'avgEngagement': '${avgMins.toStringAsFixed(1)}m',
        'chartVals': chartVals,
        'chartLabels': chartLabels,
        'sci': sci,
        'soc': soc,
        'lang': lang,
        'log': log,
        'sentiment': sentiment,
      };
    }
    
    double totalMins = 0;
    int chats = 0;
    int words = 0;
    double avgMins = 0;
    List<double> chartVals = [];
    List<String> chartLabels = [];
    
    double sci = 0.25;
    double soc = 0.25;
    double lang = 0.25;
    double log = 0.25;
    
    String sentiment = "🌟 Baseline Mood: Content & Learning\nRegular, healthy engagement patterns across the platform.";

    if (_selectedPersonaId == 'All') {
      totalMins = is7Days ? 205 : (isLastMonth ? 780 : 820);
      chats = is7Days ? 28 : (isLastMonth ? 105 : 112);
      words = is7Days ? 48 : (isLastMonth ? 170 : 192);
      avgMins = is7Days ? 7.3 : (isLastMonth ? 7.4 : 7.3);
      chartVals = is7Days ? [20, 35, 15, 45, 10, 50, 30] : (isLastMonth ? [160, 220, 200, 200] : [180, 240, 210, 190]);
      chartLabels = is7Days ? _weeklyDays : _monthlyWeeks;
      sci = 0.45; soc = 0.30; lang = 0.15; log = 0.10;
      sentiment = "🌟 Baseline Mood: Joyful & Curious\nLoves discussing rocket science with Boby. Practiced naming colors in Bangla with Ruby.";
    } else if (_selectedPersonaId == 'Ruby') {
      totalMins = is7Days ? 65 : (isLastMonth ? 240 : 260);
      chats = is7Days ? 10 : (isLastMonth ? 38 : 40);
      words = is7Days ? 22 : (isLastMonth ? 80 : 88);
      avgMins = is7Days ? 6.5 : (isLastMonth ? 6.3 : 6.5);
      chartVals = is7Days ? [10, 5, 15, 5, 0, 20, 10] : (isLastMonth ? [50, 65, 55, 70] : [60, 70, 50, 80]);
      chartLabels = is7Days ? _weeklyDays : _monthlyWeeks;
      sci = 0.10; soc = 0.35; lang = 0.45; log = 0.10;
      sentiment = "Highly Social & Creative\nRuby and the child spent time sharing school stories, singing songs, and practicing spelling.";
    } else if (_selectedPersonaId == 'Boby') {
      totalMins = is7Days ? 85 : (isLastMonth ? 320 : 340);
      chats = is7Days ? 12 : (isLastMonth ? 45 : 48);
      words = is7Days ? 16 : (isLastMonth ? 60 : 64);
      avgMins = is7Days ? 7.1 : (isLastMonth ? 7.1 : 7.1);
      chartVals = is7Days ? [5, 20, 0, 25, 5, 20, 10] : (isLastMonth ? [70, 85, 80, 85] : [80, 90, 80, 90]);
      chartLabels = is7Days ? _weeklyDays : _monthlyWeeks;
      sci = 0.60; soc = 0.10; lang = 0.10; log = 0.20;
      sentiment = "Exploratory & Logical\nBoby engaged the child in space exploration facts, building block questions, and counting games.";
    } else if (_selectedPersonaId == 'Teacher') {
      totalMins = is7Days ? 35 : (isLastMonth ? 130 : 140);
      chats = is7Days ? 4 : (isLastMonth ? 15 : 16);
      words = is7Days ? 10 : (isLastMonth ? 35 : 40);
      avgMins = is7Days ? 8.7 : (isLastMonth ? 8.6 : 8.7);
      chartVals = is7Days ? [5, 5, 0, 15, 5, 5, 0] : (isLastMonth ? [25, 35, 35, 35] : [30, 40, 35, 35]);
      chartLabels = is7Days ? _weeklyDays : _monthlyWeeks;
      sci = 0.30; soc = 0.10; lang = 0.30; log = 0.30;
      sentiment = "Academic Focus\nMiss Pearl led sessions on counting, reading pronunciation, and plant lifecycle facts.";
    } else if (_selectedPersonaId == 'Mom') {
      totalMins = is7Days ? 15 : (isLastMonth ? 50 : 60);
      chats = is7Days ? 2 : (isLastMonth ? 7 : 8);
      words = 0;
      avgMins = is7Days ? 7.5 : (isLastMonth ? 7.1 : 7.5);
      chartVals = is7Days ? [0, 5, 0, 0, 0, 5, 5] : (isLastMonth ? [10, 15, 15, 10] : [10, 20, 15, 15]);
      chartLabels = is7Days ? _weeklyDays : _monthlyWeeks;
      sci = 0.05; soc = 0.75; lang = 0.15; log = 0.05;
      sentiment = "Nurturing & Emotional\nShared conversations about feelings, bedtime comfort, and helping at home.";
    } else if (_selectedPersonaId == 'Dad') {
      totalMins = is7Days ? 20 : (isLastMonth ? 70 : 80);
      chats = is7Days ? 2 : (isLastMonth ? 7 : 8);
      words = 0;
      avgMins = is7Days ? 10.0 : (isLastMonth ? 10.0 : 10.0);
      chartVals = is7Days ? [0, 10, 0, 0, 0, 5, 5] : (isLastMonth ? [15, 20, 15, 20] : [20, 20, 20, 20]);
      chartLabels = is7Days ? _weeklyDays : _monthlyWeeks;
      sci = 0.20; soc = 0.40; lang = 0.10; log = 0.30;
      sentiment = "Adventurous & Active\nDiscussed outdoor activities, sports rules, and building toy cars.";
    } else {
      final int seed = _selectedPersonaId.hashCode;
      chats = is7Days ? (seed % 6 + 3) : (isLastMonth ? (seed % 15 + 15) : (seed % 15 + 20));
      avgMins = (seed % 4 + 6).toDouble() + 0.5;
      totalMins = (chats * avgMins).roundToDouble();
      words = (chats * (seed % 3 + 1)).toInt();
      
      if (is7Days) {
        chartVals = List.generate(7, (i) => ((seed + i) % 12 + 2).toDouble());
        chartLabels = _weeklyDays;
      } else {
        chartVals = List.generate(4, (i) => ((seed + i) % 45 + 15).toDouble());
        chartLabels = _monthlyWeeks;
      }
      
      final double totalFocus = (seed % 10 + 10).toDouble();
      sci = (seed % 4 + 1) / totalFocus;
      soc = (seed % 3 + 2) / totalFocus;
      lang = (seed % 2 + 3) / totalFocus;
      log = 1.0 - (sci + soc + lang);
      
      sentiment = "🌟 Custom Persona Activity\nInteracted with custom friend. Focus shifted towards personalized conversation dynamics.";
    }

    return {
      'totalTime': '${totalMins.round()}m',
      'chatsCount': chats.toString(),
      'vocabGrowth': words > 0 ? '+$words' : '0',
      'avgEngagement': '${avgMins.toStringAsFixed(1)}m',
      'chartVals': chartVals,
      'chartLabels': chartLabels,
      'sci': sci,
      'soc': soc,
      'lang': lang,
      'log': log,
      'sentiment': sentiment,
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _getFilteredData();
    final String totalTime = data['totalTime'];
    final String chatsCount = data['chatsCount'];
    final String vocabGrowth = data['vocabGrowth'];
    final String avgEngagement = data['avgEngagement'];
    final List<double> chartVals = List<double>.from(data['chartVals']);
    final List<String> chartLabels = List<String>.from(data['chartLabels']);
    final double sci = data['sci'];
    final double soc = data['soc'];
    final double lang = data['lang'];
    final double log = data['log'];
    final String sentiment = data['sentiment'];

    final double maxVal = chartVals.isEmpty ? 1.0 : chartVals.reduce((a, b) => a > b ? a : b);

    // List of active personas
    final personasList = [
      {'id': 'All', 'name': 'All Friends'},
      ...PersonaState.savedPersonas.map((p) => {'id': p.id, 'name': p.name}),
    ];

    // List of date filters
    final dateRangeOptions = [
      {'id': '7days', 'name': 'Last 7 Days'},
      {'id': '30days', 'name': 'Last 30 Days'},
      {'id': 'this_month', 'name': 'This Month'},
      {'id': 'last_month', 'name': 'Last Month'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Switch toggle
        // Title and Switch toggle (wrapped in a Wrap for responsiveness)
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Activity Analytics',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF333333)),
                ),
                const SizedBox(width: 8),
                if (_loadingAnalytics)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.pinkAccent),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _loadAnalyticsFromSupabase,
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toggleButton(
                    label: 'Weekly',
                    isActive: _isWeekly,
                    onTap: () => setState(() {
                      _isWeekly = true;
                      _selectedDateRange = '7days';
                    }),
                  ),
                  _toggleButton(
                    label: 'Monthly',
                    isActive: !_isWeekly,
                    onTap: () => setState(() {
                      _isWeekly = false;
                      _selectedDateRange = '30days';
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filter Dropdowns
        Row(
          children: [
            // Persona Dropdown
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPersonaId,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFFF6B9D)),
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF555555)),
                    items: personasList.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['id'],
                        child: Text(p['name']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPersonaId = val);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Date Range Dropdown
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDateRange,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFFFF6B9D)),
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF555555)),
                    items: dateRangeOptions.map((d) {
                      return DropdownMenuItem<String>(
                        value: d['id'],
                        child: Text(d['name']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedDateRange = val;
                          _isWeekly = (val == '7days');
                        });
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 2x2 Metric Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _metricCard(
              title: 'Total Talk Time',
              value: totalTime,
              subtitle: _isWeekly ? '+12% vs last week' : '+18% vs last month',
              icon: Icons.timer_rounded,
              color: const Color(0xFFFFF0F6),
              iconColor: Colors.pink,
            ),
            _metricCard(
              title: 'Chats Completed',
              value: chatsCount,
              subtitle: 'Active interactions',
              icon: Icons.chat_bubble_rounded,
              color: const Color(0xFFE3F2FD),
              iconColor: Colors.blue,
            ),
            _metricCard(
              title: 'New Words Used',
              value: vocabGrowth,
              subtitle: 'Vocabulary expansion',
              icon: Icons.auto_stories_rounded,
              color: const Color(0xFFE8F5E9),
              iconColor: Colors.green,
            ),
            _metricCard(
              title: 'Avg. Engagement',
              value: avgEngagement,
              subtitle: 'Mins per conversation',
              icon: Icons.speed_rounded,
              color: const Color(0xFFFFF8E1),
              iconColor: Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Activity Bar Chart Panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isWeekly ? 'Daily Minutes Active' : 'Weekly Minutes Active',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF444444)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    chartVals.length,
                    (idx) {
                      final val = chartVals[idx];
                      final label = chartLabels[idx];
                      final pct = maxVal > 0 ? val / maxVal : 0.0;
                      final isHovered = _hoveredIndex == idx;

                      return Expanded(
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _hoveredIndex = idx),
                          onTapCancel: () => setState(() => _hoveredIndex = null),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedOpacity(
                                opacity: isHovered ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 150),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF333333),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${val.round()}m',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: MouseRegion(
                                    onEnter: (_) => setState(() => _hoveredIndex = idx),
                                    onExit: (_) => setState(() => _hoveredIndex = null),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 400),
                                      curve: Curves.easeOutBack,
                                      width: _isWeekly ? 16 : 28,
                                      height: pct * 100,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isHovered 
                                              ? [Colors.pinkAccent, Colors.orangeAccent]
                                              : [const Color(0xFFFF6B9D), const Color(0xFFFFAB40)],
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                label,
                                style: TextStyle(
                                  fontWeight: isHovered ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 12,
                                  color: isHovered ? const Color(0xFFFF6B9D) : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Topic & Cognitive Focus Areas
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cognitive Focus Area',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF444444)),
              ),
              const SizedBox(height: 16),
              _focusBar(title: 'Science & Nature (Space, Animals)', percentage: sci, color: Colors.blue),
              const SizedBox(height: 12),
              _focusBar(title: 'Social & Emotional (Family, Sharing)', percentage: soc, color: Colors.pinkAccent),
              const SizedBox(height: 12),
              _focusBar(title: 'Language & Stories (Reading, Vocab)', percentage: lang, color: Colors.purpleAccent),
              const SizedBox(height: 12),
              _focusBar(title: 'Numbers & Logic (Counting, Puzzles)', percentage: log, color: Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sentiment Highlights Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F7FA), Color(0xFFFFF9C4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.face_retouching_natural_rounded, size: 40, color: Colors.teal),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Curiosity & Mood Highlight',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF263238)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sentiment,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF37474F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggleButton({required String label, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: isActive ? const Color(0xFFFF6B9D) : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey[700]),
                ),
              ),
              Icon(icon, size: 18, color: iconColor),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF333333)),
              ),
              Text(
                subtitle,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 9, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _focusBar({required String title, required double percentage, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF555555)),
            ),
            Text(
              '${(percentage * 100).round()}%',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 6,
            backgroundColor: Colors.grey[100],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ─── Small Google Logo Painter ───────────────────────────────────────────────

class _GoogleLogoSmallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    final rect = Rect.fromLTWH(0, 0, w, h);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.28;
      
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -3.14 * 0.75, 3.14 * 0.5, false, paint);
    
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -3.14 * 0.25, 3.14 * 0.5, false, paint);
    
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 3.14 * 0.25, 3.14 * 0.5, false, paint);
    
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 3.14 * 0.75, 3.14 * 0.5, false, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
