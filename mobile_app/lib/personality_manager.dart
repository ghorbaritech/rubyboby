import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'persona_service.dart';
import 'persona_state.dart';

class PersonalityManager extends StatefulWidget {
  const PersonalityManager({super.key});

  @override
  State<PersonalityManager> createState() => _PersonalityManagerState();
}

class _PersonalityManagerState extends State<PersonalityManager> {
  final _nameController = TextEditingController();
  final _traitController = TextEditingController();
  final _ageController = TextEditingController(text: "5");
  String _selectedGender = "Girl";
  XFile? _image;
  Uint8List? _imageBytes;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (selectedImage != null) {
        final bytes = await selectedImage.readAsBytes();
        setState(() {
          _image = selectedImage;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Your Friend'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Image Upload Section
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: Colors.pinkAccent, width: 2),
                  image: _image != null
                      ? DecorationImage(image: NetworkImage(_image!.path), fit: BoxFit.cover)
                      : null,
                ),
                child: _image == null
                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.pinkAccent)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Upload Avatar Photo', style: TextStyle(color: Colors.black54)),
            
            const SizedBox(height: 30),

            // Form Fields
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Friend\'s Name (e.g., Ruby)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 15),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Age (e.g., 5)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(Icons.cake),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    items: ["Girl", "Boy"]
                        .map((label) => DropdownMenuItem(value: label, child: Text(label)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedGender = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            TextField(
              controller: _traitController,
              decoration: InputDecoration(
                labelText: 'Traits (e.g., Happy, Smart, Playful)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                prefixIcon: const Icon(Icons.auto_awesome),
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
                      return;
                    }

                    setState(() => _isLoading = true);

                    bool success = await PersonaService.savePersona(
                      name: _nameController.text,
                      role: 'Custom AI Friend',
                      traits: _traitController.text.split(','),
                      language: 'English/Bangla',
                      imagePath: _image?.path,
                    );

                    if (mounted) {
                      if (success) {
                        await PersonaState.addPersona(
                          name: _nameController.text, 
                          traits: _traitController.text,
                          age: _ageController.text,
                          gender: _selectedGender,
                          language: 'English',
                          role: 'Friend',
                          imageBytes: _imageBytes,
                        );
                        
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Friend Created Successfully!')),
                        );
                        Navigator.pop(context, true);
                      } else {
                        setState(() => _isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to save. Try again!')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Create My Friend', style: TextStyle(fontSize: 18)),
                ),
          ],
        ),
      ),
    );
  }
}
