import 'dart:math';
import 'package:flutter/material.dart';
import 'voice_service.dart';

class LipSyncMouth extends StatefulWidget {
  final double size;

  const LipSyncMouth({super.key, this.size = 28.0});

  @override
  State<LipSyncMouth> createState() => _LipSyncMouthState();
}

class _LipSyncMouthState extends State<LipSyncMouth>
    with SingleTickerProviderStateMixin {
  late AnimationController _mouthController;

  @override
  void initState() {
    super.initState();
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Listen to the speaking state
    VoiceService.isSpeaking.addListener(_onSpeakingChanged);
    _onSpeakingChanged(); // Sync initial state
  }

  void _onSpeakingChanged() {
    if (!mounted) return;
    final speaking = VoiceService.isSpeaking.value;
    if (speaking) {
      _mouthController.repeat(reverse: true);
    } else {
      _mouthController.stop();
      _mouthController.reverse(); // Transition back to closed mouth
    }
  }

  @override
  void dispose() {
    VoiceService.isSpeaking.removeListener(_onSpeakingChanged);
    _mouthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: VoiceService.isSpeaking,
      builder: (context, isSpeaking, child) {
        if (!isSpeaking) {
          // Closed mouth (a happy subtle curve)
          return SizedBox(
            width: widget.size,
            height: widget.size * 0.35,
            child: CustomPaint(
              painter: ClosedMouthPainter(),
            ),
          );
        }

        return AnimatedBuilder(
          animation: _mouthController,
          builder: (context, child) {
            // Apply a minor sine fluctuation over time to make mouth movements feel organic
            final timeMs = DateTime.now().millisecondsSinceEpoch;
            final organicFluctuation = 0.7 + 0.3 * sin(timeMs * 0.045).abs();
            final openProgress = _mouthController.value * organicFluctuation;

            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: CartoonMouthPainter(openProgress: openProgress),
              ),
            );
          },
        );
      },
    );
  }
}

class ClosedMouthPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF421C1C)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    // A nice happy curve
    path.moveTo(0, size.height * 0.4);
    path.quadraticBezierTo(
        size.width / 2, size.height * 0.95, size.width, size.height * 0.4);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CartoonMouthPainter extends CustomPainter {
  final double openProgress; // 0.0 to 1.0

  CartoonMouthPainter({required this.openProgress});

  @override
  void paint(Canvas canvas, Size size) {
    if (openProgress <= 0.08) {
      // Very close to closed - draw line
      final paintLine = Paint()
        ..color = const Color(0xFF421C1C)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(size.width * 0.05, size.height / 2);
      path.quadraticBezierTo(
          size.width / 2, size.height * 0.7, size.width * 0.95, size.height / 2);
      canvas.drawPath(path, paintLine);
      return;
    }

    // Mouth cavity fill
    final paintMouth = Paint()
      ..color = const Color(0xFF4A1515)
      ..style = PaintingStyle.fill;

    final mouthRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width,
      height: size.height * openProgress,
    );
    canvas.drawOval(mouthRect, paintMouth);

    // Draw white teeth at the top of the mouth cavity
    if (openProgress > 0.35) {
      final paintTeeth = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.clipPath(Path()..addOval(mouthRect));

      final teethRect = Rect.fromLTWH(
        size.width * 0.15,
        size.height / 2 - (size.height * openProgress * 0.5),
        size.width * 0.7,
        size.height * openProgress * 0.38,
      );
      canvas.drawOval(teethRect, paintTeeth);
      canvas.restore();
    }

    // Draw pink tongue at the bottom of the mouth cavity
    if (openProgress > 0.22) {
      final paintTongue = Paint()
        ..color = const Color(0xFFFF8A80)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.clipPath(Path()..addOval(mouthRect));

      final tongueRect = Rect.fromLTWH(
        size.width * 0.2,
        size.height / 2 + (size.height * openProgress * 0.1),
        size.width * 0.6,
        size.height * openProgress * 0.45,
      );
      canvas.drawOval(tongueRect, paintTongue);
      canvas.restore();
    }

    // Draw border outline around open mouth
    final paintOutline = Paint()
      ..color = const Color(0xFF421C1C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawOval(mouthRect, paintOutline);
  }

  @override
  bool shouldRepaint(covariant CartoonMouthPainter oldDelegate) {
    return oldDelegate.openProgress != openProgress;
  }
}
