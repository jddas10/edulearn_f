import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtl;

  @override
  void initState() {
    super.initState();
    _animCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    const bgColor = Color(0xFF060D16);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _animCtl,
        builder: (context, _) {
          return Stack(
            children: [
              CustomPaint(
                size: size,
                painter: _OrbPainter(progress: _animCtl.value),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Continue as',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 44),
                      _RoleButton(
                        label: 'Student',
                        onTap: () =>
                            context.go('${AppRoutes.login}?role=student'),
                        accent: accent,
                      ),
                      const SizedBox(height: 18),
                      _RoleButton(
                        label: 'Teacher',
                        onTap: () =>
                            context.go('${AppRoutes.login}?role=teacher'),
                        accent: accent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  _OrbPainter({required this.progress});

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color,
      double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.55),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeInOut.transform(progress);

    _drawOrb(
      canvas,
      Offset(size.width * 0.85 + ease * 14, size.height * 0.04 - ease * 10),
      size.width * 0.70,
      const Color(0xFF006673),
      0.98,
    );

    _drawOrb(
      canvas,
      Offset(size.width * 0.04 - ease * 10, size.height * 0.43 + ease * 8),
      size.width * 0.60,
      const Color(0xFF005866),
      0.92,
    );

    _drawOrb(
      canvas,
      Offset(size.width * 0.90 + ease * 8, size.height * 0.90 + ease * 5),
      size.width * 0.54,
      const Color(0xFF004E5C),
      0.88,
    );

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = -3; i < 7; i++) {
      final startX = size.width * 0.22 * i;
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + size.height * 0.65, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.progress != progress;
}

class _RoleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color accent;

  const _RoleButton({
    required this.label,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF060D16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF060D16),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}