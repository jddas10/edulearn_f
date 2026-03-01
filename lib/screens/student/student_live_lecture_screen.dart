import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentLiveLectureScreen extends StatefulWidget {
  const StudentLiveLectureScreen({super.key});

  @override
  State<StudentLiveLectureScreen> createState() => _StudentLiveLectureScreenState();
}

class _StudentLiveLectureScreenState extends State<StudentLiveLectureScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  static const String _ytUrl = "https://www.youtube.com/@hitensadaniedu";

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _openYouTube() async {
    final uri = Uri.parse(_ytUrl);
    HapticFeedback.mediumImpact();

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open YouTube'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF030810);
    const accent = Color(0xFF00E5FF);
    const accent2 = Color(0xFF00FFA8);

    // TODO: API se bind kar dena
    const bool isLiveNow = false;
    const String nextLiveText = "Tomorrow @ 10:00 AM";

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _ctl,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _LiveBgPainter(progress: _ctl.value),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70, size: 20),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accent.withOpacity(0.22)),
                        ),
                        child: const Icon(Icons.wifi_tethering_rounded,
                            color: accent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Live Lecture",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      const _LivePill(isLive: isLiveNow, accent: accent2),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 140,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _ctl,
                            builder: (context, _) {
                              final t = Curves.easeInOut.transform(_ctl.value);
                              final glow = 0.10 + (0.10 * t);
                              final shift = (t - 0.5) * 2;

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A1628).withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withOpacity(glow),
                                      blurRadius: 40,
                                      spreadRadius: 2,
                                      offset: Offset(0, 18 + 6 * shift.abs()),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 120,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _PulseRing(
                                            progress: _ctl.value,
                                            color: isLiveNow ? accent2 : accent,
                                          ),
                                          Container(
                                            width: 74,
                                            height: 74,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(18),
                                              color: (isLiveNow ? accent2 : accent).withOpacity(0.14),
                                              border: Border.all(
                                                color: (isLiveNow ? accent2 : accent).withOpacity(0.35),
                                              ),
                                            ),
                                            child: Icon(
                                              isLiveNow ? Icons.play_arrow_rounded : Icons.live_tv_rounded,
                                              color: isLiveNow ? accent2 : accent,
                                              size: 42,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isLiveNow ? "Live Now" : "No Live Session Currently",
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isLiveNow
                                          ? "Tap Join to open live on YouTube"
                                          : "Next live: $nextLiveText",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: (isLiveNow ? accent2 : accent).withOpacity(0.95),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.04),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_rounded,
                                              size: 18, color: Colors.white.withOpacity(0.65)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "Host: Hiten Sadani (YouTube)",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.75),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Icon(Icons.hd_rounded,
                                              size: 18, color: Colors.white.withOpacity(0.55)),
                                          const SizedBox(width: 6),
                                          Text(
                                            "HD",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.70),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
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

                          const SizedBox(height: 20),

                          AnimatedBuilder(
                            animation: _ctl,
                            builder: (context, _) {
                              final t = Curves.easeInOut.transform(_ctl.value);
                              final scale = 1.0 + (isLiveNow ? 0.02 * t : 0.0);

                              return Transform.scale(
                                scale: scale,
                                child: _JoinButton(
                                  onTap: _openYouTube,
                                  enabled: true,
                                  label: isLiveNow ? "Join Live Lecture" : "Open YouTube Channel",
                                  accent: const Color(0xFF00FFA8),
                                  shimmerProgress: _ctl.value,
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Tip: If YouTube app is installed, it will open directly.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  final bool isLive;
  final Color accent;

  const _LivePill({required this.isLive, required this.accent});

  @override
  Widget build(BuildContext context) {
    final color = isLive ? const Color(0xFFFF3B30) : Colors.white24;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isLive ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(isLive ? 0.50 : 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFFFF3B30) : Colors.white30,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isLive ? "LIVE" : "OFFLINE",
            style: TextStyle(
              color: isLive ? const Color(0xFFFFB4AE) : Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final Color accent;
  final double shimmerProgress;

  const _JoinButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.accent,
    required this.shimmerProgress,
  });

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOut.transform(shimmerProgress);
    final shimmerX = (-0.6 + 1.2 * t);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: enabled ? accent : Colors.white12,
          boxShadow: enabled
              ? [
            BoxShadow(
              color: accent.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.0,
                  child: Transform.translate(
                    offset: Offset(MediaQuery.of(context).size.width * shimmerX, 0),
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.22),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final double progress;
  final Color color;

  const _PulseRing({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeInOut.transform(progress);
    final size = 110.0 + 18.0 * t;
    final opacity = 0.25 * (1.0 - t);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(opacity), width: 2),
      ),
    );
  }
}

class _LiveBgPainter extends CustomPainter {
  final double progress;
  _LiveBgPainter({required this.progress});

  void _orb(Canvas canvas, Offset c, double r, Color color, double o) {
    final p = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(o),
          color.withOpacity(o * 0.35),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, p);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeInOut.transform(progress);

    _orb(canvas, Offset(size.width * 0.92, size.height * 0.10 - ease * 12),
        size.width * 0.70, const Color(0xFF003A45), 0.55);
    _orb(canvas, Offset(-size.width * 0.10 + ease * 10, size.height * 0.52),
        size.width * 0.60, const Color(0xFF1A0A00), 0.35);
    _orb(canvas, Offset(size.width * 0.88, size.height * 0.92 + ease * 10),
        size.width * 0.55, const Color(0xFF001B2E), 0.40);

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const lines = 26;
    const steps = 120;

    for (int i = 0; i < lines; i++) {
      final yBase = (size.height / (lines - 1)) * i;
      final path = Path();

      for (int s = 0; s <= steps; s++) {
        final x = (size.width / steps) * s;
        final y = yBase +
            18.0 * sin((x / size.width) * pi * 2.1 + i * 0.27 + ease * 0.55) +
            7.0 * sin((x / size.width) * pi * 4.2 + i * 0.12);

        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiveBgPainter oldDelegate) =>
      oldDelegate.progress != progress;
}