import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes.dart';
import '../../screens/auth/api_service.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _ctl;
  late final AnimationController _sparkleCtl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<double> _contentSlide;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _sparkleCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.7, end: 1.1).animate(
      CurvedAnimation(parent: _ctl, curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack)),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctl, curve: const Interval(0.0, 0.35, curve: Curves.easeIn)),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctl, curve: const Interval(0.5, 0.8, curve: Curves.easeIn)),
    );

    _contentSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _ctl, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _ctl.forward();
      });
    });

    Future.delayed(const Duration(milliseconds: 3100), _goNext);
  }

  void _goNext() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final isLoggedIn = await SessionStore.isLoggedIn;

    if (!mounted) return;

    if (isLoggedIn) {
      final role = await SessionStore.role;
      if (role == 'TEACHER') {
        context.go(AppRoutes.teacherDash);
      } else if (role == 'STUDENT') {
        context.go(AppRoutes.studentDash);
      } else {
        context.go(AppRoutes.role);
      }
    } else {
      context.go(AppRoutes.role);
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    _sparkleCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    return Scaffold(
      backgroundColor: const Color(0xFF040A12),
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _sparkleCtl,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _SparklePainter(progress: _sparkleCtl.value, color: accent),
            ),
          ),
          AnimatedBuilder(
            animation: _ctl,
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(0, _contentSlide.value),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: _logoFade.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(color: accent.withOpacity(0.5), width: 2),
                          ),
                          child: const Icon(Icons.school_rounded, size: 60, color: accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Opacity(
                      opacity: _textFade.value,
                      child: Column(
                        children: [
                          const Text(
                            'EduLearn',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Ignite Your Learning Journey',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.6),
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 40,
            child: AnimatedBuilder(
              animation: _ctl,
              builder: (context, _) => Opacity(
                opacity: _textFade.value,
                child: const Text(
                  'DEVELOPED BY JAYDATT DAVE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final Color color;
  final List<Offset> points = List.generate(40, (i) => Offset(Random(i).nextDouble(), Random(i + 100).nextDouble()));

  _SparklePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      final double opacity = (sin((progress * 2 * pi) + i) + 1) / 2;
      paint.color = color.withOpacity(opacity * 0.5);
      canvas.drawCircle(
        Offset(points[i].dx * size.width, points[i].dy * size.height),
        1.5 * opacity,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}