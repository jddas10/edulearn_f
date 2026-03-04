import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/routes.dart';
import 'student_attendance_screen.dart';
import 'student_homework_screen.dart';
import 'student_marks_screen.dart';
import 'student_quiz_screen.dart';
import 'student_live_lecture_screen.dart';
import 'student_recorded_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbCtl;

  @override
  void initState() {
    super.initState();
    _orbCtl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    const bg = Color(0xFF030810);

    return Scaffold(
      backgroundColor: bg,
      drawer: _buildDrawer(context, accent),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _orbCtl,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _DarkBgPainter(progress: _orbCtl.value),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 18, 8, 4),
                  child: Row(
                    children: [
                      Builder(
                        builder: (ctx) => IconButton(
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                          icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                        ),
                      ),
                      const Icon(Icons.school_rounded, color: accent, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'EduLearn Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 26, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WelcomeCard(accent: accent),
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _QuickActionsGrid(accent: accent),
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActivityCard(
                          title: "Student's Progress",
                          subtitle: 'Progress: 75% completed',
                          progress: 0.75,
                          accent: accent,
                        ),
                        const SizedBox(height: 10),
                        _ActivityCard(
                          title: 'Attendance Summary',
                          subtitle: 'Overall: 92% present',
                          progress: 0.92,
                          accent: const Color(0xFF00BFA5),
                        ),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildDrawer(BuildContext context, Color accent) {
    return Drawer(
      backgroundColor: const Color(0xFF080F1A),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _DrawerItem(label: 'Settings', icon: Icons.settings_outlined),
            const Spacer(),
            const Divider(color: Colors.white12, indent: 16, endIndent: 16),
            _DrawerItem(
              label: 'Logout',
              icon: Icons.logout_rounded,
              iconColor: accent,
              onTap: () => context.go(AppRoutes.role),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final Color accent;
  const _WelcomeCard({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back, Jaydatt!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Courses Completed: 75%',
                  style: TextStyle(
                      fontSize: 13, color: accent, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Next Live: Tomorrow @ 10 AM',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2E48),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.blueAccent, size: 34),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final Color accent;
  const _QuickActionsGrid({required this.accent});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        label: 'Attendance',
        icon: Icons.calendar_today_rounded,
        color: const Color(0xFF5B2D8E),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentAttendanceScreen()),
        ),
      ),
      _ActionItem(
        label: 'Recorded',
        icon: Icons.video_library_rounded,
        color: const Color(0xFFB84A00),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentRecordedScreen()),
        ),
      ),
      _ActionItem(
        label: 'Live Classes',
        icon: Icons.videocam_rounded,
        color: const Color(0xFF1565C0),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentLiveLectureScreen()),
        ),
      ),
      _ActionItem(
        label: 'Quiz',
        icon: Icons.quiz_rounded,
        color: const Color(0xFFC62828),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentQuizScreen()),
        ),
      ),
      _ActionItem(
        label: 'Marks',
        icon: Icons.bar_chart_rounded,
        color: const Color(0xFF2E7D32),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentMarksScreen()),
        ),
      ),
      _ActionItem(
        label: 'Homework',
        icon: Icons.assignment_rounded,
        color: const Color(0xFF006064),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeworkScreen()),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, i) {
        final a = actions[i];
        return GestureDetector(
          onTap: a.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: a.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(a.icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  a.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;
  final Color accent;
  const _ActivityCard({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 5),
          Text(subtitle,
              style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  const _DrawerItem({
    required this.label,
    required this.icon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white70, size: 22),
      title: Text(label,
          style: TextStyle(
              color: iconColor ?? Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _ActionItem({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class _DarkBgPainter extends CustomPainter {
  final double progress;
  _DarkBgPainter({required this.progress});

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(opacity),
          color.withOpacity(opacity * 0.4),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeInOut.transform(progress);

    _drawOrb(canvas, Offset(size.width * 0.88, size.height * 0.06 - ease * 8),
        size.width * 0.65, const Color(0xFF003A45), 0.50);
    _drawOrb(canvas, Offset(-size.width * 0.1 + ease * 6, size.height * 0.45),
        size.width * 0.55, const Color(0xFF002830), 0.45);
    _drawOrb(canvas, Offset(size.width * 0.92, size.height * 0.88 + ease * 6),
        size.width * 0.50, const Color(0xFF002030), 0.40);

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.018)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const lineCount = 26;
    const waveAmplitude = 18.0;
    const waveFreq = 2.2;

    for (int i = 0; i < lineCount; i++) {
      final yBase = (size.height / (lineCount - 1)) * i;
      final path = Path();
      const steps = 120;
      for (int s = 0; s <= steps; s++) {
        final x = (size.width / steps) * s;
        final y = yBase +
            waveAmplitude * sin((x / size.width) * pi * waveFreq + i * 0.3 + ease * 0.4) +
            (waveAmplitude * 0.4) *
                sin((x / size.width) * pi * waveFreq * 2.1 + i * 0.15);
        s == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DarkBgPainter old) => old.progress != progress;
}