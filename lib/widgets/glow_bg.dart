import 'package:flutter/material.dart';

class GlowBg extends StatelessWidget {
  final Widget child;
  const GlowBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06111C),
            Color(0xFF040A12),
            Color(0xFF050B14),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _EduBgPainter())),
          child,
        ],
      ),
    );
  }
}

class _EduBgPainter extends CustomPainter {
  const _EduBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // big teal circles (top-left & bottom-right)
    final teal = const Color(0xFF00E5FF);

    final circlePaint1 = Paint()..color = teal.withOpacity(0.22);
    final circlePaint2 = Paint()..color = teal.withOpacity(0.18);

    // top-left circle (partially outside)
    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.08),
      size.width * 0.55,
      circlePaint1,
    );

    // bottom-right circle (partially outside)
    canvas.drawCircle(
      Offset(size.width * 1.05, size.height * 1.05),
      size.width * 0.60,
      circlePaint2,
    );

    // diagonal lines
    final linePaint = Paint()
      ..color = teal.withOpacity(0.22)
      ..strokeWidth = 1.2;

    // 3 diagonal lines similar to screenshot
    canvas.drawLine(
      Offset(size.width * 0.10, size.height * 0.35),
      Offset(size.width * 0.92, size.height * 0.62),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.18, size.height * 0.58),
      Offset(size.width * 0.75, size.height * 0.86),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.00, size.height * 0.72),
      Offset(size.width * 0.62, size.height * 0.40),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
