import 'package:flutter/material.dart';
import 'theme_engine.dart';
import 'voice_service.dart';

class AvatarView extends StatefulWidget {
  final String personaId;
  final String age;
  final String gender;

  const AvatarView({
    super.key, 
    required this.personaId, 
    this.age = "5", 
    this.gender = "Girl"
  });

  @override
  State<AvatarView> createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> {
  bool _isTalking = false;
  bool _isThinking = false;
  String _aiMessage = "I'm listening! Tell me something fun.";

  void _startTalking() async {
    setState(() {
      _isThinking = true;
      _aiMessage = "Thinking...";
    });

    // Simulate AI Processing & Lip-Sync Generation
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isThinking = false;
        _isTalking = true;
        _aiMessage = "That sounds wonderful! Let's talk more about it.";
      });
      // START AUDIO with persona-specific tuning
      VoiceService.speak(_aiMessage, gender: widget.gender, age: widget.age);
    }

    // Character talks for 4 seconds
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      setState(() {
        _isTalking = false;
        _aiMessage = "Tap the mic to tell me more!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = RubyBobyTheme.getThemeForPersona(widget.personaId);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: theme.gradientColors,
          ),
        ),
        child: Stack(
          children: [
            // Character Container
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 320,
                    height: 480,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: Colors.white70, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Base Avatar Icon (No network dependency to avoid CORS)
                          Icon(
                            _isTalking ? Icons.face_retouching_natural : Icons.face,
                            size: 180, 
                            color: theme.primaryColor.withOpacity(0.8)
                          ),
                          
                          // Talking Waveform Overlay
                          if (_isTalking)
                            Positioned(
                              bottom: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) => _buildAnimatedBar(i, theme.accentColor)),
                              ),
                            ),
                          
                          // Loading State
                          if (_isThinking)
                            Container(
                              color: Colors.black12,
                              child: CircularProgressIndicator(color: theme.primaryColor),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // AI Message Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _aiMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.w600, 
                        color: Colors.black87
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mic Button
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isTalking || _isThinking ? null : _startTalking,
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: _isTalking || _isThinking ? Colors.grey : theme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 5)
                      ],
                    ),
                    child: Icon(
                      _isTalking ? Icons.graphic_eq : Icons.mic,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),

            // Back Button
            Positioned(
              top: 50,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    VoiceService.stop();
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBar(int index, Color color) {
    return Container(
      width: 8,
      height: 40 + (index * 10),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
