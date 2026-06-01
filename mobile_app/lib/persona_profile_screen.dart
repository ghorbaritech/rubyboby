import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'persona_state.dart';
import 'persona_service.dart';

class PersonaProfileScreen extends StatefulWidget {
  final CustomPersona? editingPersona;
  const PersonaProfileScreen({super.key, this.editingPersona});

  @override
  State<PersonaProfileScreen> createState() => _PersonaProfileScreenState();
}

class _PersonaProfileScreenState extends State<PersonaProfileScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _ageController = TextEditingController(text: '5');
  final _traitsController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _languageController = TextEditingController(text: 'English');

  String _gender = 'Girl';
  String _relationship = 'Friend';
  String _personality = 'Playful';
  String _voiceTone = 'Cheerful';
  String _language = 'English';
  XFile? _photo;
  Uint8List? _photoBytes; // bytes loaded from picker — works on web & mobile
  double _faceZoom = 1.8;
  double _faceYOffset = -0.2;
  bool _isLoading = false;
  int _currentStep = 0;
  final ImagePicker _picker = ImagePicker();

  final _relationships = ['Friend', 'Mom', 'Dad', 'Grandma', 'Grandpa', 'Teacher', 'Sibling', 'Other'];
  final _personalities = ['Playful', 'Nurturing', 'Adventurous', 'Calm', 'Funny', 'Wise', 'Energetic'];
  final _voiceTones = ['Cheerful', 'Warm', 'Soft', 'Enthusiastic', 'Gentle', 'Bright'];
  final _languages = ['English', 'Bangla (Native)', 'Banglish (Romanized)', 'English & Bangla'];

  Future<void> _pickPhoto() async {
    try {
      final img = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (img != null) {
        final bytes = await img.readAsBytes();
        setState(() {
          _photo = img;
          _photoBytes = bytes;
        });
      }
    } catch (e) {
      print("Error picking photo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach photo: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.editingPersona != null) {
      final p = widget.editingPersona!;
      _nameController.text = p.name;
      _ageController.text = p.age;
      _gender = p.gender;
      _language = p.language;
      _traitsController.text = p.traits;
      _faceZoom = p.faceZoom;
      _faceYOffset = p.faceYOffset;
      _photoBytes = p.imageBytes;
    }
  }

  bool get _step0Valid => _nameController.text.isNotEmpty;
  bool get _step1Valid => _ageController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editingPersona != null ? 'Edit Friend' : 'Create New Friend',
          style: TextStyle(fontFamily: 'Nunito', 
              fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF333333)),
        ),
        centerTitle: true,
        actions: [
          if (widget.editingPersona != null &&
              widget.editingPersona!.id != 'Ruby' &&
              widget.editingPersona!.id != 'Boby' &&
              widget.editingPersona!.id != 'Teacher' &&
              widget.editingPersona!.id != 'Mom' &&
              widget.editingPersona!.id != 'Dad')
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Friend?'),
                    content: Text('Are you sure you want to remove ${widget.editingPersona!.name}?'),
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
                  await PersonaState.deletePersona(widget.editingPersona!.id);
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Step indicator ──────────────────────────────────────
          _StepIndicator(current: _currentStep, total: 3),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),
          // ── Navigation buttons ──────────────────────────────────
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Identity ─────────────────────────────────────────────────────
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE0EC),
                    border: Border.all(color: const Color(0xFFFF6B9D), width: 3),
                  ),
                  child: _photoBytes != null
                      ? ClipOval(
                          child: Transform.scale(
                            scale: _faceZoom,
                            alignment: Alignment(0, _faceYOffset),
                            child: Image.memory(
                              _photoBytes!,
                              width: 130,
                              height: 130,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : const Icon(Icons.camera_alt_rounded,
                          size: 48, color: Color(0xFFFF6B9D)),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF6B9D),
                  ),
                  child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text('Tap to upload photo',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Colors.grey)),
        ),
        if (_photoBytes != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Text('Crop Face Area:',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF444444))),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.zoom_in_rounded, size: 20, color: Color(0xFFFF6B9D)),
              const SizedBox(width: 8),
              const Text('Zoom: ', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
              Expanded(
                child: Slider(
                  value: _faceZoom,
                  min: 1.0,
                  max: 3.5,
                  activeColor: const Color(0xFFFF6B9D),
                  inactiveColor: const Color(0xFFFFE0EC),
                  onChanged: (v) => setState(() => _faceZoom = v),
                ),
              ),
              Text('${_faceZoom.toStringAsFixed(1)}x', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF666666))),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.unfold_more_rounded, size: 20, color: Color(0xFFFF6B9D)),
              const SizedBox(width: 8),
              const Text('Shift Y: ', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF666666))),
              Expanded(
                child: Slider(
                  value: _faceYOffset,
                  min: -1.0,
                  max: 1.0,
                  activeColor: const Color(0xFFFF6B9D),
                  inactiveColor: const Color(0xFFFFE0EC),
                  onChanged: (v) => setState(() => _faceYOffset = v),
                ),
              ),
              Text(_faceYOffset > 0 ? 'Down' : _faceYOffset < 0 ? 'Up' : 'Center', style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF666666))),
            ],
          ),
        ],
        const SizedBox(height: 28),
        _label('Friend\'s Name *'),
        _inputField(controller: _nameController, hint: 'e.g. Ruby, Dadi Ma, Uncle...', icon: Icons.person_rounded),
        const SizedBox(height: 16),
        _label('Nickname (optional)'),
        _inputField(controller: _nicknameController, hint: 'e.g. Bubu, Choco...', icon: Icons.star_rounded),
        const SizedBox(height: 16),
        _label('Relationship'),
        _chipSelector(
          items: _relationships,
          selected: _relationship,
          color: const Color(0xFFFF6B9D),
          onSelect: (v) => setState(() => _relationship = v),
        ),
        const SizedBox(height: 16),
        _label('Language'),
        _chipSelector(
          items: _languages,
          selected: _language,
          color: const Color(0xFF4CAF50),
          onSelect: (v) => setState(() => _language = v),
        ),
      ],
    );
  }

  // ── Step 1: Personality ──────────────────────────────────────────────────
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Gender'),
        Row(
          children: ['Girl', 'Boy', 'Non-binary'].map((g) {
            final sel = _gender == g;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFFF6B9D) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: sel ? const Color(0xFFFF6B9D) : Colors.grey.shade300),
                    boxShadow: sel
                        ? [BoxShadow(color: const Color(0xFFFF6B9D).withOpacity(0.3), blurRadius: 8, offset: const Offset(0,3))]
                        : [],
                  ),
                  child: Text(g,
                      style: TextStyle(fontFamily: 'Nunito', 
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : Colors.grey.shade600)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _label('Age'),
        SizedBox(
          width: 120,
          child: _inputField(
              controller: _ageController,
              hint: '5',
              icon: Icons.cake_rounded,
              keyboardType: TextInputType.number),
        ),
        const SizedBox(height: 20),
        _label('Personality'),
        _chipSelector(
          items: _personalities,
          selected: _personality,
          color: const Color(0xFF9C27B0),
          onSelect: (v) => setState(() => _personality = v),
        ),
        const SizedBox(height: 20),
        _label('Voice Tone'),
        _chipSelector(
          items: _voiceTones,
          selected: _voiceTone,
          color: const Color(0xFF2196F3),
          onSelect: (v) => setState(() => _voiceTone = v),
        ),
        const SizedBox(height: 20),
        _label('Key Traits (comma separated)'),
        _inputField(
            controller: _traitsController,
            hint: 'e.g. Kind, Funny, Smart, Loving',
            icon: Icons.auto_awesome_rounded),
      ],
    );
  }

  // ── Step 2: Backstory & Confirm ──────────────────────────────────────────
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Background Story (optional)'),
        TextField(
          controller: _backgroundController,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            hintText:
                'e.g. "Loves cooking. Has a garden full of flowers. Tells amazing bedtime stories."',
            hintStyle: TextStyle(fontFamily: 'Nunito', color: Colors.grey, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 28),
        // ── Preview card ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFFFFB7C5), Color(0xFFFFE4C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Text('Your New Friend',
                  style: TextStyle(fontFamily: 'Nunito', 
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 12),
              _previewRow(Icons.person_rounded, 'Name',
                  _nameController.text.isEmpty ? '—' : _nameController.text),
              _previewRow(Icons.favorite_rounded, 'Relationship', _relationship),
              _previewRow(Icons.cake_rounded, 'Age', '${_ageController.text} years old'),
              _previewRow(Icons.wc_rounded, 'Gender', _gender),
              _previewRow(Icons.psychology_rounded, 'Personality', _personality),
              _previewRow(Icons.record_voice_over_rounded, 'Voice', _voiceTone),
              _previewRow(Icons.language_rounded, 'Language', _language),
              if (_traitsController.text.isNotEmpty)
                _previewRow(Icons.star_rounded, 'Traits', _traitsController.text),
            ],
          ),
        ),
      ],
    );
  }

  Widget _previewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(fontFamily: 'Nunito', 
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
          Expanded(
            child: Text(value,
                style: TextStyle(fontFamily: 'Nunito', 
                    fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    side: const BorderSide(color: Color(0xFFFF6B9D))),
                child: Text('Back',
                    style: TextStyle(fontFamily: 'Nunito', 
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF6B9D))),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B9D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 6,
                shadowColor: const Color(0xFFFF6B9D).withOpacity(0.5),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      _currentStep < 2 ? 'Next →' : '✨ Create Friend!',
                      style: TextStyle(fontFamily: 'Nunito', 
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNext() async {
    if (_currentStep == 0 && !_step0Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a name for your friend!')));
      return;
    }
    if (_currentStep == 1 && !_step1Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an age for your friend!')));
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      return;
    }

    // Final save
    setState(() => _isLoading = true);
    try {
      final finalId = widget.editingPersona?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final finalBytes = _photoBytes ?? widget.editingPersona?.imageBytes;
      final finalB64 = finalBytes != null ? base64Encode(finalBytes) : widget.editingPersona?.imageBase64;
      
      final persona = CustomPersona(
        id: finalId,
        name: _nicknameController.text.isEmpty ? _nameController.text : _nicknameController.text,
        traits: '$_personality · $_voiceTone · ${_traitsController.text}',
        age: _ageController.text,
        gender: _gender,
        colorValue: _gender == "Boy" ? Colors.blue[100]!.value : Colors.pink[100]!.value,
        language: _language,
        role: _relationship,
        faceZoom: _faceZoom,
        faceYOffset: _faceYOffset,
        imageBase64: finalB64,
        imageBytes: finalBytes,
      );

      // Save to backend first
      await PersonaService.savePersona(persona);

      // Save to local state
      if (widget.editingPersona != null) {
        await PersonaState.updatePersona(persona);
      } else {
        await PersonaState.addPersona(persona);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_nameController.text} is ready to talk! 🎉',
                  style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w700))),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print("Error creating/saving friend: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create friend: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: TextStyle(fontFamily: 'Nunito', 
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF444444))),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontFamily: 'Nunito', color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFFF6B9D)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _chipSelector({
    required List<String> items,
    required String selected,
    required Color color,
    required ValueChanged<String> onSelect,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final sel = selected == item;
          return GestureDetector(
            onTap: () => onSelect(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? color : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: sel ? color : Colors.grey.shade300, width: 1.5),
                boxShadow: sel
                    ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Text(item,
                  style: TextStyle(fontFamily: 'Nunito', 
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: sel ? Colors.white : Colors.grey.shade600)),
            ),
          );
        }).toList(),
      );
}

// ─── Step Indicator ───────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final labels = ['Identity', 'Personality', 'Confirm'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: List.generate(total, (i) {
          final active = i == current;
          final done = i < current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 4,
                        decoration: BoxDecoration(
                          color: done || active
                              ? const Color(0xFFFF6B9D)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[i],
                        style: TextStyle(fontFamily: 'Nunito', 
                          fontSize: 11,
                          fontWeight:
                              active ? FontWeight.w800 : FontWeight.w600,
                          color: active
                              ? const Color(0xFFFF6B9D)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < total - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}



