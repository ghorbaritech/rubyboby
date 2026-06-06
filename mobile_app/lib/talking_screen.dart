import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'persona_state.dart';
import 'voice_service.dart';
import 'stt_service.dart';
import 'ai_service.dart';
import 'custom_avatar.dart';
import 'lip_sync_mouth.dart';
import 'analytics_service.dart';

// ─── Persona definition ──────────────────────────────────────────────────────

class PersonaDef {
  final String id;
  final String name;
  final String imagePath;
  final Color bgTop;
  final Color bgBottom;
  final String age;
  final String gender;
  final String greeting;
  final List<String> responses;

  const PersonaDef({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.bgTop,
    required this.bgBottom,
    required this.age,
    required this.gender,
    required this.greeting,
    required this.responses,
  });
}

final Map<String, PersonaDef> kDefaultPersonas = {
  'Ruby': PersonaDef(
    id: 'Ruby',
    name: 'Ruby',
    imagePath: 'assets/images/ruby.png',
    bgTop: const Color(0xFFFFB7C5),
    bgBottom: const Color(0xFFFFE4C0),
    age: '5',
    gender: 'Girl',
    greeting: "Hiii! I'm Ruby! Ready to play a fun game or hear a story?",
    responses: [
      "Ooh that sounds SO fun! Tell me more!",
      "Wow, I love that! Let's play together!",
      "Hehe, you're so silly! I like you!",
      "That's amazing! Can we do it again?",
      "I want to hear more! Keep going!",
    ],
  ),
  'Boby': PersonaDef(
    id: 'Boby',
    name: 'Boby',
    imagePath: 'assets/images/boby.png',
    bgTop: const Color(0xFF90CAF9),
    bgBottom: const Color(0xFFB2EBF2),
    age: '6',
    gender: 'Boy',
    greeting: "Hey! I'm Boby! Wanna race or build something cool?",
    responses: [
      "COOL! That's really awesome!",
      "Yeah yeah yeah! Let's do it!",
      "Whoa, you're super smart!",
      "That's the best thing I ever heard!",
      "Let's go! Adventure time!",
    ],
  ),
  'Teacher': PersonaDef(
    id: 'Teacher',
    name: 'Miss Pearl',
    imagePath: 'assets/images/teacher.png',
    bgTop: const Color(0xFFCE93D8),
    bgBottom: const Color(0xFFA5D6A7),
    age: '28',
    gender: 'Girl',
    greeting: "Hello there! I'm Miss Pearl. Let's learn something wonderful today!",
    responses: [
      "Excellent thinking! You're very clever!",
      "That's a wonderful question!",
      "Great job! I'm so proud of you!",
      "Let me tell you something amazing about that!",
      "You are learning so fast! Fantastic!",
    ],
  ),
};

// ─── Talking Screen ──────────────────────────────────────────────────────────

class TalkingScreen extends StatefulWidget {
  final String personaId;
  final String? customName;
  final String age;
  final String gender;
  final String language;
  final Uint8List? customImageBytes; // bytes for user-uploaded persona photos
  final String role;
  final double faceZoom;
  final double faceYOffset;

  const TalkingScreen({
    super.key,
    required this.personaId,
    this.customName,
    this.age = '5',
    this.gender = 'Girl',
    this.language = 'English',
    this.customImageBytes,
    this.role = 'Friend',
    this.faceZoom = 1.8,
    this.faceYOffset = -0.2,
  });

  @override
  State<TalkingScreen> createState() => _TalkingScreenState();
}

class _TalkingScreenState extends State<TalkingScreen>
    with TickerProviderStateMixin {
  bool _isTalking = false;
  bool _isListening = false;
  String _message = '';
  final TextEditingController _textController = TextEditingController();
  late AnimationController _waveController;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  // Session tracking metrics
  late DateTime _sessionStartTime;
  final Set<String> _uniqueWordsUsed = {};
  int _messagesSent = 0;

  bool _detectStoryRequest(String text) {
    final lower = text.toLowerCase();
    return lower.contains('story') || 
           lower.contains('stories') || 
           lower.contains('tale') || 
           lower.contains('গল্প') || 
           lower.contains('golpo') ||
           lower.contains('কাহিনী');
  }

  Future<Map<String, String>?> _fetchStoryForCharacter() async {
    try {
      final response = await Supabase.instance.client
          .from('stories')
          .select('title, content')
          .or('persona_id.eq.${widget.personaId},persona_id.eq.All');
      if (response != null && response is List && response.isNotEmpty) {
        final randomIdx = Random().nextInt(response.length);
        final story = response[randomIdx];
        return {
          'title': (story['title'] ?? '') as String,
          'content': (story['content'] ?? '') as String,
        };
      }
    } catch (e) {
      debugPrint('TalkingScreen: Error fetching stories: $e');
    }
    return null;
  }

  PersonaDef? get _persona => kDefaultPersonas[widget.personaId];

  String get _displayName =>
      widget.customName ?? _persona?.name ?? widget.personaId;
  String get _imagePath =>
      _persona?.imagePath ?? 'assets/images/ruby.png';
  Color get _bgTop =>
      _persona?.bgTop ?? const Color(0xFFFFB7C5);
  Color get _bgBottom =>
      _persona?.bgBottom ?? const Color(0xFFFFE4C0);
  String get _greeting =>
      _persona?.greeting ?? "Hi! I'm $_displayName!";
  List<String> get _responses =>
      _persona?.responses ?? ["That sounds great!", "Tell me more!"];

  String _getBackgroundImagePath() {
    final r = widget.role.toLowerCase();
    final name = _displayName.toLowerCase();
    
    // Default characters specific backdrops
    if (widget.personaId == 'Ruby' || widget.personaId == 'Boby') {
      return 'assets/images/bg_playroom.png';
    }
    if (widget.personaId == 'Teacher' || r.contains('teacher') || name.contains('teacher') || name.contains('miss')) {
      return 'assets/images/bg_classroom.png';
    }
    
    // Custom roles mapping
    if (r.contains('mom') || r.contains('mother') || name.contains('mom') || name.contains('mother') || name.contains('ammi') || name.contains('ma')) {
      return 'assets/images/bg_livingroom.png';
    }
    if (r.contains('dad') || r.contains('father') || name.contains('dad') || name.contains('father') || name.contains('baba') || name.contains('abba')) {
      return 'assets/images/bg_livingroom.png';
    }
    if (r.contains('grandma') || r.contains('grandmother') || name.contains('grandma') || name.contains('dida') || name.contains('nani') || name.contains('dadi') || name.contains('thakuma')) {
      return 'assets/images/bg_cozy_room.png';
    }
    if (r.contains('grandpa') || r.contains('grandfather') || name.contains('grandpa') || name.contains('dadu') || name.contains('nana') || name.contains('dada') || name.contains('dadu')) {
      return 'assets/images/bg_garden.png';
    }
    
    return 'assets/images/bg_playroom.png';
  }

  Color? _getBackgroundColorFilterColor() {
    if (_getBackgroundImagePath() != 'assets/images/bg_playroom.png') {
      return null;
    }

    final r = widget.role.toLowerCase();
    final name = _displayName.toLowerCase();
    final g = widget.gender.toLowerCase();
    
    final isBoy = widget.personaId == 'Boby' || 
                  g.contains('boy') || 
                  g.contains('male') || 
                  r.contains('brother') || 
                  name.contains('boby') || 
                  name.contains('brother') || 
                  name.contains('bhai');
                  
    if (isBoy) {
      return const Color(0xFF00B0FF).withOpacity(0.32); // Cool blue overlay tint
    } else {
      return const Color(0xFFFF4081).withOpacity(0.28); // Warm strawberry pink overlay tint
    }
  }

  BlendMode? _getBackgroundColorFilterMode() {
    return _getBackgroundColorFilterColor() != null ? BlendMode.srcATop : null;
  }

  Widget _buildTalkingAvatar(double avatarHeight) {
    final String avatarAsset;
    // Check if it's a default persona (Ruby, Boby, Teacher)
    if (widget.personaId == 'Ruby' || widget.personaId == 'Boby' || widget.personaId == 'Teacher') {
      avatarAsset = _imagePath;
    } else {
      // Resolve custom role-based avatars based on BOTH role and name
      final r = widget.role.toLowerCase();
      final name = _displayName.toLowerCase();
      final g = widget.gender.toLowerCase();
      
      if (r.contains('grandma') || r.contains('grandmother') || name.contains('grandma') || name.contains('dida') || name.contains('nani') || name.contains('dadi') || name.contains('thakuma')) {
        avatarAsset = 'assets/images/avatar_grandma.png';
      } else if (r.contains('grandpa') || r.contains('grandfather') || name.contains('grandpa') || name.contains('dadu') || name.contains('nana') || name.contains('dada')) {
        avatarAsset = 'assets/images/avatar_grandpa.png';
      } else if (r.contains('mom') || r.contains('mother') || name.contains('mom') || name.contains('mother') || name.contains('ammi') || name == 'ma' || name == 'maa' || name.split(' ').contains('ma') || name.split(' ').contains('maa')) {
        avatarAsset = 'assets/images/avatar_mom.png';
      } else if (r.contains('dad') || r.contains('father') || name.contains('dad') || name.contains('father') || name.contains('baba') || name.contains('abba')) {
        avatarAsset = 'assets/images/avatar_dad.png';
      } else if (r.contains('teacher') || name.contains('teacher') || name.contains('miss') || name.contains('pearl')) {
        avatarAsset = 'assets/images/teacher.png';
      } else {
        avatarAsset = g.contains('boy') || g.contains('male') || r.contains('brother') || name.contains('brother') || name.contains('bhai')
            ? 'assets/images/avatar_boy.png'
            : 'assets/images/avatar_girl.png';
      }
    }

    return Center(
      child: Image.asset(
        avatarAsset,
        height: avatarHeight,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.face_rounded,
          size: avatarHeight * 0.5,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _bounceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: -12).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut));

    // Greet after short delay
    Future.delayed(const Duration(milliseconds: 800), _greet);
  }

  void _greet() {
    if (!mounted) return;
    setState(() {
      _message = _greeting;
      _isTalking = true;
    });
    VoiceService.speak(_greeting,
        gender: widget.gender,
        age: widget.age,
        language: widget.language,
        role: widget.role,
        name: _displayName);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isTalking = false);
    });
  }

  void _processUserInput(String userText) async {
    _messagesSent++;
    
    // Extract and track unique vocabulary words (words > 3 characters)
    final wordsList = userText.toLowerCase().split(RegExp(r'\s+'));
    for (final w in wordsList) {
      final clean = w.replaceAll(RegExp(r'[^\w]'), '');
      if (clean.length > 3) {
        _uniqueWordsUsed.add(clean);
      }
    }

    setState(() {
      _message = '🤔 Thinking...';
      _isListening = false;
      _isTalking = false;
    });
    
    // If it's a custom persona, its traits are saved in the subtitle/traits field of savedPersonas.
    // We'll try to find it, otherwise default to a generic playful trait.
    String personaTraits = "Friendly and playful";
    try {
      final custom = PersonaState.savedPersonas.firstWhere((p) => p.id == widget.personaId);
      personaTraits = custom.traits;
    } catch (_) {}

    String promptText = userText;
    if (_detectStoryRequest(userText)) {
      final story = await _fetchStoryForCharacter();
      if (story != null) {
        promptText = "The child asked for a story. Please tell the following story from your archive in your unique friendly character voice, keeping it brief (around 2-3 sentences) and engaging. Story title: '${story['title']}'. Story content: ${story['content']}.";
      }
    }

    final aiResponse = await AiService.generateResponse(
      userText: promptText,
      personaName: _displayName,
      age: widget.age,
      traits: personaTraits,
      language: widget.language,
    );
    
    if (!mounted) return;

    // 3. Play AI response
    setState(() {
      _isTalking = true;
      _message = aiResponse;
    });
    
    VoiceService.speak(aiResponse,
        gender: widget.gender,
        age: widget.age,
        language: widget.language,
        role: widget.role,
        name: _displayName);
    
    // Estimate reading time to hide the talking animation
    final estimatedMs = max(3000, aiResponse.length * 75);
    Future.delayed(Duration(milliseconds: estimatedMs), () {
      if (mounted) setState(() => _isTalking = false);
    });
  }

  void _onMicTap() async {
    if (_isTalking || _isListening) return;
    
    VoiceService.stop();

    setState(() {
      _isListening = true;
      _message = '🎤 Listening...';
    });
    
    // 1. Listen for user speech
    final userText = await SttService.listen(language: widget.language);
    
    if (!mounted) return;
    
    if (userText.startsWith("ERROR:")) {
      setState(() {
        _isListening = false;
        _message = "Oops, I couldn't hear you clearly!";
      });
      return;
    }

    _processUserInput(userText);
  }

  void _onSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isTalking || _isListening) return;
    
    _textController.clear();
    FocusScope.of(context).unfocus();
    VoiceService.stop();
    _processUserInput(text);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bounceController.dispose();
    _textController.dispose();
    VoiceService.stop();

    // Save session analytics in the background
    final durationSeconds = DateTime.now().difference(_sessionStartTime).inSeconds;
    final durationMinutes = durationSeconds / 60.0;

    // Only record if it was an active session (e.g. lasted at least 5 seconds and had user messages)
    if (durationSeconds >= 5 && _messagesSent > 0) {
      final vocabGrowth = max(1, _uniqueWordsUsed.length ~/ 3);
      AnalyticsService.recordSession(
        personaId: widget.personaId,
        personaRole: widget.role,
        durationMinutes: durationMinutes,
        messagesCount: _messagesSent,
        newWordsCount: vocabGrowth,
      );
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ──────────────────────────────────────────
          Image.asset(
            _getBackgroundImagePath(),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            color: _getBackgroundColorFilterColor(),
            colorBlendMode: _getBackgroundColorFilterMode(),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _bgTop.withOpacity(0.35),
                  _bgBottom.withOpacity(0.55),
                ],
              ),
            ),
          ),

          // ── Settings button ─────────────────────────────────────
          Positioned(
            top: 52,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 34),
              ),
            ),
          ),
          Positioned(
            top: 116,
            left: 20,
            child: Text('SETTINGS',
                style: TextStyle(fontFamily: 'Nunito', 
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                          color: Colors.black45,
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ])),
          ),

          // ── Persona name ────────────────────────────────────────
          Positioned(
            top: 46,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                _displayName.toUpperCase(),
                style: TextStyle(fontFamily: 'Nunito', 
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [Color(0xFFFF6B9D), Color(0xFFFFC300)],
                    ).createShader(
                        const Rect.fromLTWH(0, 0, 300, 60)),
                  shadows: [
                    Shadow(
                        color: Colors.white,
                        blurRadius: 2,
                        offset: Offset(0, 0)),
                    Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3)),
                  ],
                ),
              ),
            ),
          ),
          // sparkle icons around name
          ..._buildSparkles(size),

          // ── Character image ─────────────────────────────────────
          Positioned(
            bottom: size.height * 0.32,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _bounceAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, _isTalking || _isListening ? _bounceAnim.value : 0),
                child: child,
              ),
              child: _buildTalkingAvatar(size.height * 0.42),
            ),
          ),

          // ── Mic button + waveform ───────────────────────────────
          Positioned(
            bottom: size.height * 0.27,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isTalking || _isListening)
                      _buildWaveRow(left: true),
                    GestureDetector(
                      onTap: _onMicTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            _isListening
                                ? const Color(0xFFFF4444)
                                : const Color(0xFFFF8C00),
                            _isListening
                                ? const Color(0xFFCC0000)
                                : const Color(0xFFFF5500),
                          ]),
                          border: Border.all(
                              color: const Color(0xFF4FC3F7), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: (_isListening
                                      ? Colors.red
                                      : const Color(0xFFFF8C00))
                                  .withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                        child: Icon(
                          _isListening
                              ? Icons.graphic_eq_rounded
                              : Icons.mic_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    if (_isTalking || _isListening)
                      _buildWaveRow(left: false),
                  ],
                ),
              ],
            ),
          ),

          // ── "Listen & Talk" label ───────────────────────────────
          Positioned(
            bottom: size.height * 0.22,
            left: 0,
            right: 0,
            child: Text(
              _isListening ? 'LISTENING...' : 'LISTEN & TALK',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Nunito', 
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
            ),
          ),

          // ── AI message bubble ───────────────────────────────────
          if (_message.isNotEmpty)
            Positioned(
              bottom: size.height * 0.135,
              left: 24,
              right: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.93),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Nunito', 
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF333333)),
                ),
              ),
            ),

          // ── Text Input Bar ──────────────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.black38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _onSendText(),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4FC3F7),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _onSendText,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles(Size size) {
    return [
      Positioned(
          top: 48,
          left: size.width * 0.35,
          child: const _Sparkle(size: 22, color: Color(0xFFFFF176))),
      Positioned(
          top: 60,
          right: size.width * 0.28,
          child: const _Sparkle(size: 18, color: Color(0xFFB3E5FC))),
      Positioned(
          top: 78,
          left: size.width * 0.28,
          child: const _Sparkle(size: 14, color: Color(0xFFFFCDD2))),
    ];
  }

  Widget _buildWaveRow({required bool left}) {
    return SizedBox(
      width: 60,
      height: 40,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (_, __) {
          return Row(
            mainAxisAlignment:
                left ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(4, (i) {
              final v = _waveController.value;
              final h = 8.0 +
                  18 * sin((v * 2 * pi) + (left ? -i : i) * 0.8).abs();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 12,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(fontFamily: 'Nunito', 
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ─── Sparkle widget ──────────────────────────────────────────────────────────

class _Sparkle extends StatelessWidget {
  final double size;
  final Color color;
  const _Sparkle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.auto_awesome_rounded, size: size, color: color);
  }
}



