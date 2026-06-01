import 'dart:typed_data';
import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {
  final String role;
  final String gender;
  final double size;
  final String name;

  const CustomAvatar({
    super.key,
    required this.role,
    required this.gender,
    this.size = 120,
    this.name = '',
    // Kept for backward compatibility to avoid compile errors in callers
    Uint8List? imageBytes,
    double faceZoom = 1.0,
    double faceYOffset = 0.0,
  });

  String _getAvatarAsset() {
    final r = role.toLowerCase();
    final g = gender.toLowerCase();
    final n = name.toLowerCase();
    
    if (r.contains('grandma') || r.contains('grandmother') || n.contains('grandma') || n.contains('dida') || n.contains('nani') || n.contains('dadi') || n.contains('thakuma')) {
      return 'assets/images/avatar_grandma.png';
    }
    if (r.contains('grandpa') || r.contains('grandfather') || n.contains('grandpa') || n.contains('dadu') || n.contains('nana') || n.contains('dada')) {
      return 'assets/images/avatar_grandpa.png';
    }
    if (r.contains('mom') || r.contains('mother') || n.contains('mom') || n.contains('mother') || n.contains('ammi') || n == 'ma' || n == 'maa' || n.split(' ').contains('ma') || n.split(' ').contains('maa')) {
      return 'assets/images/avatar_mom.png';
    }
    if (r.contains('dad') || r.contains('father') || n.contains('dad') || n.contains('father') || n.contains('baba') || n.contains('abba')) {
      return 'assets/images/avatar_dad.png';
    }
    if (r.contains('teacher') || n.contains('teacher') || n.contains('miss')) {
      return 'assets/images/teacher.png';
    }
    
    // Sibling, Friend or other roles
    if (r.contains('sibling') || r.contains('friend') || r.contains('other') || r.contains('brother') || r.contains('sister') || n.contains('brother') || n.contains('sister') || n.contains('bhai') || n.contains('bon')) {
      if (g.contains('boy') || g.contains('male') || r.contains('brother') || n.contains('brother') || n.contains('bhai')) {
        return 'assets/images/avatar_boy.png';
      }
      return 'assets/images/avatar_girl.png';
    }

    // Default fallbacks based on gender
    if (g.contains('boy') || g.contains('male')) {
      return 'assets/images/avatar_boy.png';
    }
    return 'assets/images/avatar_girl.png';
  }

  @override
  Widget build(BuildContext context) {
    final avatarAsset = _getAvatarAsset();

    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        avatarAsset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.face_rounded,
          size: size * 0.6,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }
}
