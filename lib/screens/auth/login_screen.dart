import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes.dart';
import '../../screens/auth/api_service.dart';
class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _userFocused = false;
  bool _passFocused = false;

  late final AnimationController _orbCtl;
  late final AnimationController _fadeCtl;
  late final AnimationController _btnCtl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _btnScale;
  late final Animation<double> _btnGlow;

  @override
  void initState() {
    super.initState();

    _orbCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _fadeCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _fadeCtl, curve: Curves.easeOut);

    _btnCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _btnScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.03), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _btnCtl, curve: Curves.easeInOut));
    _btnGlow = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _btnCtl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _orbCtl.dispose();
    _fadeCtl.dispose();
    _btnCtl.dispose();
    super.dispose();
  }

  void _login() async {
    // button animation
    await _btnCtl.forward();
    _btnCtl.reset();

    final username = _user.text.trim();
    final password = _pass.text;

    if (username.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password')),
      );
      return;
    }

    // Optional: loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
    }

    final res = await AuthApi.login(
      username: username,
      password: password,
      role: widget.role,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    if (res['success'] == true) {
      // login ok -> go dashboard
      if (widget.role == 'teacher') {
        context.go(AppRoutes.teacherDash);
      } else {
        context.go(AppRoutes.studentDash);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message']?.toString() ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    const bg = Color(0xFF060D16);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: false, // we handle it manually
      body: Stack(
        children: [
          // Orb background
          AnimatedBuilder(
            animation: _orbCtl,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _OrbPainter(progress: _orbCtl.value),
            ),
          ),

          // Scrollable content — shifts up when keyboard opens
          AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 160),

                        // EduLearn title
                        Text(
                          'EduLearn',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ignite Your Learning Journey',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Glass card
                        _GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Role chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: accent.withOpacity(0.3), width: 1),
                                ),
                                child: Text(
                                  widget.role == 'teacher'
                                      ? '👨‍🏫  Teacher'
                                      : '🎓  Student',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accent.withOpacity(0.9),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Username
                              Focus(
                                onFocusChange: (v) =>
                                    setState(() => _userFocused = v),
                                child: _AnimatedField(
                                  focused: _userFocused,
                                  child: TextField(
                                    controller: _user,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15),
                                    cursorColor: accent,
                                    decoration: InputDecoration(
                                      hintText: 'Username',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.38),
                                        fontSize: 15,
                                      ),
                                      prefixIcon: Icon(Icons.person_outline,
                                          color: _userFocused
                                              ? accent
                                              : Colors.white.withOpacity(0.3),
                                          size: 20),
                                      border: InputBorder.none,
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                          vertical: 16),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Password
                              Focus(
                                onFocusChange: (v) =>
                                    setState(() => _passFocused = v),
                                child: _AnimatedField(
                                  focused: _passFocused,
                                  child: TextField(
                                    controller: _pass,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15),
                                    cursorColor: accent,
                                    obscureText: _obscure,
                                    decoration: InputDecoration(
                                      hintText: 'Password',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.38),
                                        fontSize: 15,
                                      ),
                                      prefixIcon: Icon(Icons.lock_outline,
                                          color: _passFocused
                                              ? accent
                                              : Colors.white.withOpacity(0.3),
                                          size: 20),
                                      border: InputBorder.none,
                                      contentPadding:
                                      const EdgeInsets.symmetric(
                                          vertical: 16),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                                () => _obscure = !_obscure),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: accent.withOpacity(0.7),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Animated LOGIN button
                              AnimatedBuilder(
                                animation: _btnCtl,
                                builder: (context, _) {
                                  return Transform.scale(
                                    scale: _btnScale.value,
                                    child: Container(
                                      width: double.infinity,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withOpacity(
                                                0.25 + _btnGlow.value * 0.45),
                                            blurRadius:
                                            8 + _btnGlow.value * 24,
                                            spreadRadius:
                                            _btnGlow.value * 2,
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: accent,
                                          foregroundColor: Colors.black,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Text(
                                          'LOGIN',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 2,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
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

    _drawOrb(canvas,
        Offset(size.width * 0.85 + ease * 14, size.height * 0.04 - ease * 10),
        size.width * 0.70, const Color(0xFF006673), 0.98);

    _drawOrb(canvas,
        Offset(size.width * 0.04 - ease * 10, size.height * 0.43 + ease * 8),
        size.width * 0.60, const Color(0xFF005866), 0.92);

    _drawOrb(canvas,
        Offset(size.width * 0.90 + ease * 8, size.height * 0.90 + ease * 5),
        size.width * 0.54, const Color(0xFF004E5C), 0.88);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.035)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = -3; i < 7; i++) {
      final startX = size.width * 0.22 * i;
      canvas.drawLine(Offset(startX, 0),
          Offset(startX + size.height * 0.65, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => old.progress != progress;
}

class _AnimatedField extends StatelessWidget {
  final bool focused;
  final Widget child;
  const _AnimatedField({required this.focused, required this.child});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: focused
            ? accent.withOpacity(0.05)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused
              ? accent.withOpacity(0.55)
              : Colors.white.withOpacity(0.1),
          width: 1.2,
        ),
        boxShadow: focused
            ? [BoxShadow(color: accent.withOpacity(0.12), blurRadius: 12)]
            : [],
      ),
      child: child,
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.055),
            borderRadius: BorderRadius.circular(24),
            border:
            Border.all(color: Colors.white.withOpacity(0.09), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}