import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'persona_state.dart';
import 'persona_service.dart';

class PersonaFineTuneScreen extends StatefulWidget {
  final CustomPersona persona;
  const PersonaFineTuneScreen({super.key, required this.persona});

  @override
  State<PersonaFineTuneScreen> createState() => _PersonaFineTuneScreenState();
}

class _PersonaFineTuneScreenState extends State<PersonaFineTuneScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];
  final Map<String, String> _selectedAnswers = {};
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final response = await Supabase.instance.client
          .from('interactive_questions')
          .select()
          .or('persona_id.eq.${widget.persona.id},persona_id.eq.All');
      
      if (response != null && response is List) {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('PersonaFineTune: Error loading questions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _saveAndClose() async {
    if (_selectedAnswers.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    // Format new traits: merge existing traits (avoid duplicate appends if possible)
    final existingTraitsList = widget.persona.traits.split(' · ');
    final tuningTraits = _selectedAnswers.values.toList();
    
    // We filter out any previous traits that match the new choices to avoid bloat
    final Set<String> updatedTraitsSet = {};
    for (var trait in existingTraitsList) {
      if (trait.trim().isNotEmpty) {
        updatedTraitsSet.add(trait.trim());
      }
    }
    for (var trait in tuningTraits) {
      if (trait.trim().isNotEmpty) {
        updatedTraitsSet.add(trait.trim());
      }
    }
    
    final finalTraits = updatedTraitsSet.join(' · ');

    final updatedPersona = CustomPersona(
      id: widget.persona.id,
      name: widget.persona.name,
      traits: finalTraits,
      age: widget.persona.age,
      gender: widget.persona.gender,
      colorValue: widget.persona.colorValue,
      language: widget.persona.language,
      role: widget.persona.role,
      faceZoom: widget.persona.faceZoom,
      faceYOffset: widget.persona.faceYOffset,
      imageBase64: widget.persona.imageBase64,
      imageBytes: widget.persona.imageBytes,
    );

    try {
      await PersonaState.updatePersona(updatedPersona);
      await PersonaService.savePersona(updatedPersona);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.persona.name}\'s conversation style updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update personality traits: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color(widget.persona.colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tune ${widget.persona.name}\'s Voice'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, themeColor.withOpacity(0.12)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _questions.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      // Progress indicators
                      _buildProgressBar(themeColor),
                      const SizedBox(height: 20),
                      
                      // Flashcard slider
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _questions.length,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return _buildFlashcard(_questions[index], themeColor);
                          },
                        ),
                      ),
                      
                      // Bottom navigation
                      _buildBottomControls(themeColor),
                      const SizedBox(height: 30),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_alt_rounded, size: 70, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Customization Flashcards Yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add question flashcards inside the Web Admin Panel to enable fine-tuning options here!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(Color themeColor) {
    final double percent = (_selectedAnswers.length / _questions.length);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tuning Progress',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              Text(
                '${_selectedAnswers.length} of ${_questions.length} answered',
                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashcard(Map<String, dynamic> question, Color themeColor) {
    final questionId = question['id'].toString();
    final questionText = question['question_text'] as String;
    final optionsList = List<String>.from(question['options'] as List<dynamic>);
    final currentChoice = _selectedAnswers[questionId];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: themeColor.withOpacity(0.15), width: 1),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded, color: themeColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'QUESTION ${_currentIndex + 1}',
                  style: TextStyle(fontWeight: FontWeight.w900, color: themeColor, fontSize: 13, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              questionText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333), height: 1.4),
            ),
            const SizedBox(height: 30),
            ...optionsList.map((opt) {
              final isSelected = currentChoice == opt;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAnswers[questionId] = opt;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? themeColor : Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? themeColor : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: themeColor.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                        color: isSelected ? Colors.white : Colors.grey[400],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF444444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          TextButton(
            onPressed: _currentIndex > 0
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            child: Row(
              children: const [
                Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                SizedBox(width: 4),
                Text('Previous', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Next / Apply button
          ElevatedButton(
            onPressed: () {
              if (_currentIndex < _questions.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _saveAndClose();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              children: [
                Text(
                  _currentIndex < _questions.length - 1 ? 'Next' : 'Apply Tuning',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(width: 6),
                Icon(
                  _currentIndex < _questions.length - 1 ? Icons.arrow_forward_ios_rounded : Icons.psychology_rounded,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
