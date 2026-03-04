import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../auth/api_service.dart';

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF6C63FF).withAlpha(13);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.15), 180, paint);
    paint.color = const Color(0xFF00D4AA).withAlpha(10);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.7), 200, paint);
    paint.color = const Color(0xFFFF6584).withAlpha(8);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.85), 150, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TeacherQuizScreen extends StatefulWidget {
  const TeacherQuizScreen({super.key});
  @override
  State<TeacherQuizScreen> createState() => _TeacherQuizScreenState();
}

class _TeacherQuizScreenState extends State<TeacherQuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _fabController;
  late AnimationController _listController;
  late Animation<double> _headerAnim;
  late Animation<double> _fabAnim;
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _listController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _headerAnim =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic);
    _fabAnim =
        CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);
    _headerController.forward();
    Future.delayed(
        const Duration(milliseconds: 600), () => _fabController.forward());
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    setState(() => _isLoading = true);
    try {
      final res = await QuizApi.getTeacherQuizzes();
      if (res['success'] == true && mounted) {
        final List raw = res['quizzes'] ?? [];
        const colors = [
          Color(0xFF6C63FF),
          Color(0xFF00D4AA),
          Color(0xFFFF6584),
          Color(0xFFFFB347),
        ];
        const icons = ['📐', '🔬', '📝', '🌍'];
        setState(() {
          _quizzes = List.generate(raw.length, (i) {
            final q = raw[i];
            return {
              'id': q['id'],
              'title': q['title'] ?? 'Untitled',
              'subject': '',
              'questions': q['question_count'] ?? 0,
              'totalMarks': q['total_marks'] ?? 0,
              'status': 'Active',
              'submissions': q['submission_count'] ?? 0,
              'total': 32,
              'color': colors[i % colors.length],
              'icon': icons[i % icons.length],
            };
          });
          _isLoading = false;
        });
        _listController.forward();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _fabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BackgroundPainter())),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStatsRow(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF6C63FF)))
                      : _quizzes.isEmpty
                      ? Center(
                      child: Text('No quizzes yet',
                          style: TextStyle(
                              color: Colors.white.withAlpha(128),
                              fontSize: 15)))
                      : _buildQuizList(),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            right: 24,
            child: ScaleTransition(
              scale: _fabAnim,
              child: _buildCreateFAB(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
            .animate(_headerAnim),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(26)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
                    ).createShader(bounds),
                    child: const Text('Quiz Studio',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5)),
                  ),
                  Text('Manage & Create Quizzes',
                      style: TextStyle(
                          color: Colors.white.withAlpha(128),
                          fontSize: 13,
                          fontWeight: FontWeight.w400)),
                ],
              ),
              const Spacer(),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.filter_list,
                    color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    int totalSubs = 0;
    for (final q in _quizzes) {
      totalSubs += (q['submissions'] as int? ?? 0);
    }
    final active = _quizzes
        .where((q) =>
    (q['submissions'] as int? ?? 0) < (q['total'] as int? ?? 1))
        .length;
    return AnimatedBuilder(
      animation: _headerAnim,
      builder: (context, child) =>
          Opacity(opacity: _headerAnim.value, child: child),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            _statChip(
                '${_quizzes.length}', 'Total Quizzes', const Color(0xFF6C63FF)),
            const SizedBox(width: 10),
            _statChip('$active', 'Active', const Color(0xFF00D4AA)),
            const SizedBox(width: 10),
            _statChip('$totalSubs', 'Submissions', const Color(0xFFFFB347)),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withAlpha(31),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(64), width: 1),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizList() {
    return RefreshIndicator(
      onRefresh: _fetchQuizzes,
      color: const Color(0xFF6C63FF),
      backgroundColor: const Color(0xFF131929),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _quizzes.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _listController,
            builder: (context, child) {
              final delay = index * 0.15;
              final animValue = math.max(
                  0.0,
                  math.min(1.0,
                      (_listController.value - delay) / (1.0 - delay)));
              final curve =
              Curves.easeOutCubic.transform(animValue.clamp(0.0, 1.0));
              return Opacity(
                opacity: curve,
                child: Transform.translate(
                    offset: Offset(0, 40 * (1 - curve)), child: child),
              );
            },
            child: _buildQuizCard(_quizzes[index], index),
          );
        },
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, int index) {
    final color = quiz['color'] as Color;
    final submissions = quiz['submissions'] as int;
    final total = quiz['total'] as int;
    final progress = total > 0 ? submissions / total : 0.0;
    final questions = quiz['questions'] as int;
    final totalMarks = quiz['totalMarks'] as int;

    return GestureDetector(
      onTap: () => _showQuizOptions(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(51), width: 1),
          boxShadow: [
            BoxShadow(
                color: color.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient:
                LinearGradient(colors: [color, color.withAlpha(77)]),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withAlpha(38),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                            child: Text(quiz['icon'],
                                style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(quiz['title'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.help_outline,
                                    color: color, size: 12),
                                const SizedBox(width: 4),
                                Text('$questions Qs',
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 10),
                                Icon(Icons.star_outline,
                                    color: Colors.white.withAlpha(128),
                                    size: 12),
                                const SizedBox(width: 4),
                                Text('$totalMarks Marks',
                                    style: TextStyle(
                                        color: Colors.white.withAlpha(128),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00D4AA).withAlpha(31),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF00D4AA).withAlpha(77)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radio_button_checked,
                                color: Color(0xFF00D4AA), size: 10),
                            SizedBox(width: 4),
                            Text('Active',
                                style: TextStyle(
                                    color: Color(0xFF00D4AA),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withAlpha(15),
                                valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                                '$submissions/$total submitted  •  ${(progress * 100).toInt()}%',
                                style: TextStyle(
                                    color: Colors.white.withAlpha(89),
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20)),
                border:
                Border(top: BorderSide(color: Colors.white.withAlpha(13))),
              ),
              child: Row(
                children: [
                  _footerBtn(
                    icon: Icons.bar_chart_rounded,
                    label: 'Results',
                    color: color,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                          context,
                          PageRouteBuilder(
                              pageBuilder: (_, a, __) => FadeTransition(
                                  opacity: a,
                                  child: QuizResultsViewScreen(quiz: quiz)),
                              transitionDuration:
                              const Duration(milliseconds: 400)));
                    },
                  ),
                  const SizedBox(width: 6),
                  _footerDivider(),
                  const SizedBox(width: 6),
                  _footerBtn(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: Colors.white.withAlpha(153),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                          context,
                          PageRouteBuilder(
                              pageBuilder: (_, a, __) => FadeTransition(
                                  opacity: a,
                                  child: QuizEditorScreen(quiz: quiz)),
                              transitionDuration:
                              const Duration(milliseconds: 400)))
                          .then((_) => _fetchQuizzes());
                    },
                  ),
                  const SizedBox(width: 6),
                  _footerDivider(),
                  const SizedBox(width: 6),
                  _footerBtn(
                    icon: Icons.notifications_outlined,
                    label: 'Notify',
                    color: const Color(0xFF00D4AA),
                    onTap: () => _showQuizOptions(quiz),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _confirmDelete(index),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6584).withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline,
                          color: Color(0xFFFF6584), size: 18),
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

  Widget _footerBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _footerDivider() {
    return Container(
      width: 1,
      height: 14,
      color: Colors.white.withAlpha(20),
    );
  }

  Widget _buildCreateFAB() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
            context,
            PageRouteBuilder(
                pageBuilder: (_, a, __) => FadeTransition(
                    opacity: a, child: const QuizCreatorScreen()),
                transitionDuration: const Duration(milliseconds: 400)))
            .then((_) => _fetchQuizzes());
      },
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF6C63FF).withAlpha(115),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Create Quiz',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }

  void _showQuizOptions(Map<String, dynamic> quiz) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _QuizOptionsSheet(quiz: quiz, onRefresh: _fetchQuizzes),
    );
  }

  void _confirmDelete(int index) {
    HapticFeedback.heavyImpact();
    final quiz = _quizzes[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Quiz',
            style:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this quiz?',
            style: TextStyle(color: Colors.white.withAlpha(153))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF6C63FF)))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await QuizApi.deleteQuiz(quiz['id'] as int);
              if (res['success'] == true) {
                _fetchQuizzes();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(res['message'] ?? 'Delete failed'),
                    backgroundColor: const Color(0xFFFF6584),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))));
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF6584))),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUIZ OPTIONS BOTTOM SHEET
// ============================================================
class _QuizOptionsSheet extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final VoidCallback onRefresh;
  const _QuizOptionsSheet({required this.quiz, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final color = quiz['color'] as Color;
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xFF131929),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Row(children: [
            Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: color.withAlpha(38),
                    borderRadius: BorderRadius.circular(14)),
                child: Center(
                    child: Text(quiz['icon'],
                        style: const TextStyle(fontSize: 24)))),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz['title'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    Text(
                        '${quiz['questions']} Questions  •  ${quiz['totalMarks']} Marks',
                        style: TextStyle(color: color, fontSize: 13)),
                  ]),
            ),
          ]),
          const SizedBox(height: 24),
          _sheetOption(Icons.bar_chart_rounded, 'View Results',
              'See student performance', color, () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                        pageBuilder: (_, a, __) => FadeTransition(
                            opacity: a,
                            child: QuizResultsViewScreen(quiz: quiz)),
                        transitionDuration: const Duration(milliseconds: 400)));
              }),
          _sheetOption(Icons.edit_outlined, 'Edit Quiz',
              'Modify questions or settings', const Color(0xFFFFB347), () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    PageRouteBuilder(
                        pageBuilder: (_, a, __) => FadeTransition(
                            opacity: a, child: QuizEditorScreen(quiz: quiz)),
                        transitionDuration: const Duration(milliseconds: 400)))
                    .then((_) => onRefresh());
              }),
          _sheetOption(
              Icons.notifications_active_outlined,
              'Notify Students',
              'Send push notification to all students',
              const Color(0xFF00D4AA), () async {
            Navigator.pop(context);
            HapticFeedback.mediumImpact();
            final res = await QuizApi.notifyStudents(quiz['id'] as int);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(res['success'] == true
                      ? '🔔 Notification sent to all students!'
                      : res['message'] ?? 'Failed to notify'),
                  backgroundColor: res['success'] == true
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFFFF6584),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))));
            }
          }),
          _sheetOption(Icons.copy_outlined, 'Duplicate Quiz', 'Create a copy',
              Colors.white54, () async {
                Navigator.pop(context);
                HapticFeedback.mediumImpact();
                final res = await QuizApi.duplicateQuiz(quiz['id'] as int);
                if (res['success'] == true) {
                  onRefresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Quiz duplicated! ✅'),
                        backgroundColor: const Color(0xFF00D4AA),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))));
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(res['message'] ?? 'Duplicate failed'),
                      backgroundColor: const Color(0xFFFF6584),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))));
                }
              }),
        ],
      ),
    );
  }

  Widget _sheetOption(IconData icon, String title, String subtitle,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            color: color.withAlpha(18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(38))),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: TextStyle(
                    color: Colors.white.withAlpha(102), fontSize: 12)),
          ]),
          const Spacer(),
          Icon(Icons.chevron_right,
              color: Colors.white.withAlpha(77), size: 20),
        ]),
      ),
    );
  }
}

// ============================================================
// QUIZ RESULTS VIEW SCREEN
// ============================================================
class QuizResultsViewScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const QuizResultsViewScreen({super.key, required this.quiz});
  @override
  State<QuizResultsViewScreen> createState() => _QuizResultsViewScreenState();
}

class _QuizResultsViewScreenState extends State<QuizResultsViewScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _listController;
  late Animation<double> _entryAnim;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _listController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _entryAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    try {
      final res = await QuizApi.getQuizResults(widget.quiz['id'] as int);
      if (res['success'] == true && mounted) {
        setState(() {
          _results = List<Map<String, dynamic>>.from(res['results'] ?? []);
          _isLoading = false;
        });
        _listController.forward();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportXml() async {
    if (_results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No results to export'),
        backgroundColor: Color(0xFFFF6584),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isExporting = true);
    try {
      final totalMarks = widget.quiz['totalMarks'] as int? ?? 0;
      final title = widget.quiz['title'] ?? 'Quiz';
      final date = DateTime.now();
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln(
          '<QuizResults title="${_escapeXml(title)}" totalMarks="$totalMarks" date="$dateStr" totalStudents="${_results.length}">');

      for (final r in _results) {
        final name = r['name'] ?? 'Student';
        final username = r['username'] ?? '';
        final score = r['score'] as int? ?? 0;
        final cheated = r['cheated'] == 1 || r['cheated'] == true;
        final pct = totalMarks > 0 ? (score / totalMarks * 100).toInt() : 0;

        String grade;
        if (pct >= 90) {
          grade = 'A+';
        } else if (pct >= 75) {
          grade = 'A';
        } else if (pct >= 60) {
          grade = 'B';
        } else {
          grade = 'C';
        }

        buffer.writeln(
            '  <Student name="${_escapeXml(name)}" enrollment="${_escapeXml(username)}" score="$score" totalMarks="$totalMarks" percentage="$pct%" grade="$grade" cheated="$cheated"/>');
      }
      buffer.writeln('</QuizResults>');

      final dir = await getTemporaryDirectory();
      final safeTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File('${dir.path}/${safeTitle}_results_$dateStr.xml');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/xml')],
        subject: '$title - Quiz Results',
        text: 'Quiz results for "$title" — $dateStr',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: const Color(0xFFFF6584),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  @override
  void dispose() {
    _entryController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalMarks = widget.quiz['totalMarks'] as int? ?? 0;
    double avgScore = 0;
    int topScore = 0;
    if (_results.isNotEmpty) {
      int sum = 0;
      for (final r in _results) {
        final s = r['score'] as int? ?? 0;
        sum += s;
        if (s > topScore) topScore = s;
      }
      avgScore = sum / _results.length;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _BackgroundPainter())),
        SafeArea(
          child: FadeTransition(
            opacity: _entryAnim,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: Colors.white.withAlpha(18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withAlpha(26))),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 16)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                              shaderCallback: (bounds) =>
                                  const LinearGradient(colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF00D4FF)
                                  ]).createShader(bounds),
                              child: const Text('Quiz Results',
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.5))),
                          Text(widget.quiz['title'] ?? '',
                              style: TextStyle(
                                  color: Colors.white.withAlpha(128),
                                  fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ]),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isExporting ? null : _exportXml,
                    child: Container(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF00D4AA), Color(0xFF00A878)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color:
                              const Color(0xFF00D4AA).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isExporting
                              ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.download_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          const Text('XML',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _statBox('${_results.length}', 'Students',
                      const Color(0xFF6C63FF)),
                  const SizedBox(width: 10),
                  _statBox('${avgScore.toStringAsFixed(1)}', 'Avg Score',
                      const Color(0xFF00D4AA)),
                  const SizedBox(width: 10),
                  _statBox('$topScore/$totalMarks', 'Top Score',
                      const Color(0xFFFFB347)),
                ]),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF)))
                    : _results.isEmpty
                    ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📭',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text('No submissions yet',
                              style: TextStyle(
                                  color: Colors.white.withAlpha(128),
                                  fontSize: 15)),
                        ]))
                    : RefreshIndicator(
                  onRefresh: _fetchResults,
                  color: const Color(0xFF6C63FF),
                  backgroundColor: const Color(0xFF131929),
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _listController,
                        builder: (context, child) {
                          final d = index * 0.12;
                          final av =
                          ((_listController.value - d) /
                              (1.0 - d))
                              .clamp(0.0, 1.0);
                          final c =
                          Curves.easeOutCubic.transform(av);
                          return Opacity(
                              opacity: c,
                              child: Transform.translate(
                                  offset: Offset(0, 30 * (1 - c)),
                                  child: child));
                        },
                        child: _buildResultCard(
                            _results[index], index, totalMarks),
                      );
                    },
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _statBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: color.withAlpha(31),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withAlpha(64))),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withAlpha(128),
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _buildResultCard(
      Map<String, dynamic> result, int index, int totalMarks) {
    final name = result['name'] ?? 'Student';
    final username = result['username'] ?? '';
    final score = result['score'] as int? ?? 0;
    final pct = totalMarks > 0 ? score / totalMarks : 0.0;
    final cheated = result['cheated'] == 1 || result['cheated'] == true;

    Color scoreColor;
    String grade;
    if (pct >= 0.9) {
      scoreColor = const Color(0xFF00D4AA);
      grade = 'A+';
    } else if (pct >= 0.75) {
      scoreColor = const Color(0xFF6C63FF);
      grade = 'A';
    } else if (pct >= 0.6) {
      scoreColor = const Color(0xFFFFB347);
      grade = 'B';
    } else {
      scoreColor = const Color(0xFFFF6584);
      grade = 'C';
    }

    final initials = name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: cheated
                ? const Color(0xFFFF6584).withAlpha(102)
                : scoreColor.withAlpha(38)),
        boxShadow: [
          BoxShadow(
              color: scoreColor.withAlpha(13),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
              width: 20,
              alignment: Alignment.center,
              child: Text('${index + 1}',
                  style: TextStyle(
                      color: Colors.white.withAlpha(89),
                      fontSize: 13,
                      fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [scoreColor, scoreColor.withAlpha(153)]),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(username,
                      style: TextStyle(
                          color: Colors.white.withAlpha(102), fontSize: 12)),
                ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              Text('$score',
                  style: TextStyle(
                      color: scoreColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
              Text('/$totalMarks',
                  style: TextStyle(
                      color: Colors.white.withAlpha(89),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 2),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: scoreColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(grade,
                  style: TextStyle(
                      color: scoreColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
          ]),
        ]),
        if (cheated) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFFFF6584).withAlpha(26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFF6584).withAlpha(77))),
            child: const Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF6584), size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Cheating Detected — Left the app during quiz',
                      style: TextStyle(
                          color: Color(0xFFFF6584),
                          fontSize: 11,
                          fontWeight: FontWeight.w700))),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ============================================================
// QUIZ EDITOR SCREEN
// ============================================================
class QuizEditorScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const QuizEditorScreen({super.key, required this.quiz});
  @override
  State<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<QuizEditorScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _marksController = TextEditingController();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _pointsController = TextEditingController();
  final _timeController = TextEditingController();
  String _correctAnswer = 'A';
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSaving = false;
  late AnimationController _entryController;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final res = await QuizApi.getQuizFull(widget.quiz['id'] as int);
      if (res['success'] == true && mounted) {
        final quiz = res['quiz'];
        final List rawQ = res['questions'] ?? [];
        setState(() {
          _titleController.text = quiz['title'] ?? '';
          _marksController.text = '${quiz['total_marks'] ?? 0}';
          _questions = rawQ
              .map<Map<String, dynamic>>((q) => {
            'question': q['questionText'] ?? '',
            'optionA': q['optA'] ?? '',
            'optionB': q['optB'] ?? '',
            'optionC': q['optC'] ?? '',
            'optionD': q['optD'] ?? '',
            'correct': q['correctOpt'] ?? 'A',
            'points': '${q['marks'] ?? 1}',
            'timeSecs': '${q['timeSecs'] ?? 30}',
          })
              .toList();
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addQuestion() {
    if (_questionController.text.trim().isEmpty) {
      _showSnack('Write a question first!', const Color(0xFFFF6584));
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _questions.add({
        'question': _questionController.text.trim(),
        'optionA': _optionAController.text.trim(),
        'optionB': _optionBController.text.trim(),
        'optionC': _optionCController.text.trim(),
        'optionD': _optionDController.text.trim(),
        'correct': _correctAnswer,
        'points': _pointsController.text.trim().isEmpty
            ? '1'
            : _pointsController.text.trim(),
        'timeSecs': _timeController.text.trim().isEmpty
            ? '30'
            : _timeController.text.trim(),
      });
      _questionController.clear();
      _optionAController.clear();
      _optionBController.clear();
      _optionCController.clear();
      _optionDController.clear();
      _pointsController.clear();
      _timeController.clear();
      _correctAnswer = 'A';
    });
  }

  bool _validatePoints() {
    final totalMarks = int.tryParse(_marksController.text.trim()) ?? 0;
    if (totalMarks == 0) return true;
    final sumPoints = _questions.fold<int>(
        0, (sum, q) => sum + (int.tryParse(q['points'] ?? '1') ?? 1));
    if (sumPoints != totalMarks) {
      _showSnack(
          '⚠️ Total question points ($sumPoints) ≠ Total marks ($totalMarks)!\nPlease adjust points.',
          const Color(0xFFFF6584));
      return false;
    }
    return true;
  }

  Future<void> _saveQuiz() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Title required!', const Color(0xFFFFB347));
      return;
    }
    if (_questions.isEmpty) {
      _showSnack('Add at least one question!', const Color(0xFFFF6584));
      return;
    }
    if (!_validatePoints()) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();
    final aq = _questions
        .map((q) => {
      'questionText': q['question'],
      'optA': q['optionA'],
      'optB': q['optionB'],
      'optC': q['optionC'],
      'optD': q['optionD'],
      'correctOpt': q['correct'],
      'marks': int.tryParse(q['points'] ?? '1') ?? 1,
      'timeSecs': int.tryParse(q['timeSecs'] ?? '30') ?? 30,
    })
        .toList();
    final res = await QuizApi.updateQuiz(
        quizId: widget.quiz['id'] as int,
        title: _titleController.text.trim(),
        totalMarks: int.tryParse(_marksController.text.trim()) ?? 0,
        questions: aq);
    if (mounted) setState(() => _isSaving = false);
    if (res['success'] == true && mounted) {
      _showSnack('Quiz updated! ✅', const Color(0xFF00D4AA));
      Navigator.pop(context);
    } else if (mounted) {
      _showSnack(res['message'] ?? 'Update failed', const Color(0xFFFF6584));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _titleController.dispose();
    _marksController.dispose();
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _pointsController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Color(0xFF0A0E1A),
          body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF))));
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(children: [
        CustomPaint(painter: _BackgroundPainter(), size: Size.infinite),
        SafeArea(
          child: FadeTransition(
            opacity: _entryAnim,
            child: Column(children: [
              _buildTopBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _buildQuizInfoCard(),
                    const SizedBox(height: 16),
                    _buildQuestionsCountBadge(),
                    const SizedBox(height: 12),
                    _buildQuestionForm(),
                    if (_questions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildAddedQuestions(),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildSaveBar()),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(26))),
              child: const Icon(Icons.close, color: Colors.white, size: 18)),
        ),
        const SizedBox(width: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFB347), Color(0xFF6C63FF)])
              .createShader(bounds),
          child: const Text('Edit Quiz',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5)),
        ),
      ]),
    );
  }

  Widget _buildQuizInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6C63FF).withAlpha(51))),
      child: Column(children: [
        _glowTextField(_titleController, 'Quiz Title', Icons.title),
        const SizedBox(height: 12),
        _glowTextField(_marksController, 'Total Marks', Icons.star_outline,
            keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFFFFB347).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border:
              Border.all(color: const Color(0xFFFFB347).withAlpha(51))),
          child: Row(children: [
            const Icon(Icons.info_outline,
                color: Color(0xFFFFB347), size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Sum of all question points must equal Total Marks',
                  style:
                  TextStyle(color: Colors.white.withAlpha(153), fontSize: 11)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildQuestionsCountBadge() {
    final sumPoints = _questions.fold<int>(
        0, (sum, q) => sum + (int.tryParse(q['points'] ?? '1') ?? 1));
    final totalMarks = int.tryParse(_marksController.text.trim()) ?? 0;
    final isValid = totalMarks == 0 || sumPoints == totalMarks;
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFFFFB347).withAlpha(51),
              const Color(0xFF6C63FF).withAlpha(26)
            ]),
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: const Color(0xFFFFB347).withAlpha(77))),
        child: Row(children: [
          const Icon(Icons.quiz_outlined,
              color: Color(0xFFFFB347), size: 16),
          const SizedBox(width: 6),
          Text('Questions: ${_questions.length}',
              style: const TextStyle(
                  color: Color(0xFFFFB347),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: isValid
                ? const Color(0xFF00D4AA).withAlpha(26)
                : const Color(0xFFFF6584).withAlpha(26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isValid
                    ? const Color(0xFF00D4AA).withAlpha(77)
                    : const Color(0xFFFF6584).withAlpha(77))),
        child: Row(children: [
          Icon(isValid ? Icons.check_circle_outline : Icons.warning_outlined,
              color: isValid
                  ? const Color(0xFF00D4AA)
                  : const Color(0xFFFF6584),
              size: 14),
          const SizedBox(width: 6),
          Text('Points: $sumPoints/$totalMarks',
              style: TextStyle(
                  color: isValid
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFFFF6584),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
      ),
    ]);
  }

  Widget _buildQuestionForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFB347).withAlpha(77)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFFFB347).withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: _questionController,
          maxLines: 3,
          style:
          const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          decoration: InputDecoration(
              hintText: 'Write your question here...',
              hintStyle:
              TextStyle(color: Colors.white.withAlpha(64), fontSize: 15),
              border: InputBorder.none),
        ),
        Divider(color: Colors.white.withAlpha(20)),
        const SizedBox(height: 12),
        _optionField('A', _optionAController, const Color(0xFF6C63FF)),
        _optionField('B', _optionBController, const Color(0xFF00D4AA)),
        _optionField('C', _optionCController, const Color(0xFFFFB347)),
        _optionField('D', _optionDController, const Color(0xFFFF6584)),
        const SizedBox(height: 16),
        Text('CORRECT ANSWER',
            style: TextStyle(
                color: Colors.white.withAlpha(102),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
            children: ['A', 'B', 'C', 'D']
                .map((opt) => _answerRadio(opt))
                .toList()),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _glowTextField(_pointsController, 'Points', Icons.bolt,
                keyboardType: TextInputType.number),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _glowTextField(
                _timeController, 'Time (sec)', Icons.timer_outlined,
                keyboardType: TextInputType.number),
          ),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _addQuestion,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFB347), Color(0xFF6C63FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFFFB347).withAlpha(89),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ]),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Add Question',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAddedQuestions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text('Current Questions',
            style: TextStyle(
                color: Colors.white.withAlpha(153),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ),
      ..._questions.asMap().entries.map((entry) {
        final i = entry.key;
        final q = entry.value;
        return Dismissible(
          key: ValueKey('edit-$i-${q['question']}'),
          onDismissed: (_) {
            setState(() => _questions.removeAt(i));
            HapticFeedback.mediumImpact();
          },
          background: Container(
            decoration: BoxDecoration(
                color: const Color(0xFFFF6584).withAlpha(38),
                borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Color(0xFFFF6584)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF131929),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(15))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFB347).withAlpha(38),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Q${i + 1}',
                          style: const TextStyle(
                              color: Color(0xFFFFB347),
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(q['question'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF00D4AA), size: 14),
                    const SizedBox(width: 4),
                    Text(
                        'Ans: ${q['correct']}  •  ${q['points']} pts  •  ⏱ ${q['timeSecs']}s',
                        style: TextStyle(
                            color: Colors.white.withAlpha(115), fontSize: 12)),
                  ]),
                ]),
          ),
        );
      }),
    ]);
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(128),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveQuiz,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF00A878)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF00D4AA).withAlpha(89),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_isSaving)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
            else ...[
              const Icon(Icons.save, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Save Changes',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ]
          ]),
        ),
      ),
    );
  }

  Widget _glowTextField(
      TextEditingController controller, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(20))),
      child: Row(children: [
        Icon(icon, color: Colors.white.withAlpha(128), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withAlpha(77)),
                border: InputBorder.none),
          ),
        ),
      ]),
    );
  }

  Widget _optionField(
      String label, TextEditingController controller, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(77))),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withAlpha(77),
                borderRadius: BorderRadius.circular(8)),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                  hintText: 'Option',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _answerRadio(String opt) {
    final selected = _correctAnswer == opt;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _correctAnswer = opt);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: selected ? const Color(0xFF6C63FF) : Colors.white24,
            borderRadius: BorderRadius.circular(12)),
        child: Text(opt,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ============================================================
// QUIZ CREATOR SCREEN
// ============================================================
class QuizCreatorScreen extends StatefulWidget {
  const QuizCreatorScreen({super.key});
  @override
  State<QuizCreatorScreen> createState() => _QuizCreatorScreenState();
}

class _QuizCreatorScreenState extends State<QuizCreatorScreen>
    with TickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _marksController = TextEditingController();
  final _questionController = TextEditingController();
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _pointsController = TextEditingController();
  final _timeController = TextEditingController();
  String _correctAnswer = 'A';
  List<Map<String, dynamic>> _questions = [];
  bool _isSaving = false;
  late AnimationController _entryController;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _entryAnim =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic);
    _entryController.forward();
  }

  void _addQuestion() {
    if (_questionController.text.trim().isEmpty) {
      _showSnack('Write a question first!', const Color(0xFFFF6584));
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _questions.add({
        'question': _questionController.text.trim(),
        'optionA': _optionAController.text.trim(),
        'optionB': _optionBController.text.trim(),
        'optionC': _optionCController.text.trim(),
        'optionD': _optionDController.text.trim(),
        'correct': _correctAnswer,
        'points': _pointsController.text.trim().isEmpty
            ? '1'
            : _pointsController.text.trim(),
        'timeSecs': _timeController.text.trim().isEmpty
            ? '30'
            : _timeController.text.trim(),
      });
      _questionController.clear();
      _optionAController.clear();
      _optionBController.clear();
      _optionCController.clear();
      _optionDController.clear();
      _pointsController.clear();
      _timeController.clear();
      _correctAnswer = 'A';
    });
  }

  bool _validatePoints() {
    final totalMarks = int.tryParse(_marksController.text.trim()) ?? 0;
    if (totalMarks == 0) return true;
    final sumPoints = _questions.fold<int>(
        0, (sum, q) => sum + (int.tryParse(q['points'] ?? '1') ?? 1));
    if (sumPoints != totalMarks) {
      _showSnack(
          '⚠️ Total question points ($sumPoints) ≠ Total marks ($totalMarks)!\nPlease adjust points.',
          const Color(0xFFFF6584));
      return false;
    }
    return true;
  }

  Future<void> _saveQuiz() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnack('Title required!', const Color(0xFFFFB347));
      return;
    }
    if (_questions.isEmpty) {
      _showSnack('Add at least one question!', const Color(0xFFFF6584));
      return;
    }
    if (!_validatePoints()) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    final aq = _questions
        .map((q) => {
      'questionText': q['question'],
      'optA': q['optionA'],
      'optB': q['optionB'],
      'optC': q['optionC'],
      'optD': q['optionD'],
      'correctOpt': q['correct'],
      'marks': int.tryParse(q['points'] ?? '1') ?? 1,
      'timeSecs': int.tryParse(q['timeSecs'] ?? '30') ?? 30,
    })
        .toList();

    final res = await QuizApi.createQuiz(
        title: _titleController.text.trim(),
        totalMarks: int.tryParse(_marksController.text.trim()) ?? 0,
        questions: aq);

    if (mounted) setState(() => _isSaving = false);

    if (res['success'] == true && mounted) {
      _showSnack('Quiz created! ✅', const Color(0xFF00D4AA));
      Navigator.pop(context);
    } else if (mounted) {
      _showSnack(res['message'] ?? 'Create failed', const Color(0xFFFF6584));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _titleController.dispose();
    _marksController.dispose();
    _questionController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _pointsController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(children: [
        CustomPaint(painter: _BackgroundPainter(), size: Size.infinite),
        SafeArea(
          child: FadeTransition(
            opacity: _entryAnim,
            child: Column(children: [
              _buildTopBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  children: [
                    _buildQuizInfoCard(),
                    const SizedBox(height: 16),
                    _buildQuestionsCountBadge(),
                    const SizedBox(height: 12),
                    _buildQuestionForm(),
                    if (_questions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildAddedQuestions(),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ),
        Positioned(bottom: 0, left: 0, right: 0, child: _buildSaveBar()),
      ]),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: Colors.white.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(26))),
              child: const Icon(Icons.close, color: Colors.white, size: 18)),
        ),
        const SizedBox(width: 16),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)])
              .createShader(bounds),
          child: const Text('Create Quiz',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5)),
        ),
      ]),
    );
  }

  Widget _buildQuizInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6C63FF).withAlpha(51))),
      child: Column(children: [
        _glowTextField(_titleController, 'Quiz Title', Icons.title),
        const SizedBox(height: 12),
        _glowTextField(_marksController, 'Total Marks', Icons.star_outline,
            keyboardType: TextInputType.number),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFFFFB347).withAlpha(20),
              borderRadius: BorderRadius.circular(10),
              border:
              Border.all(color: const Color(0xFFFFB347).withAlpha(51))),
          child: Row(children: [
            const Icon(Icons.info_outline,
                color: Color(0xFFFFB347), size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  'Sum of all question points must equal Total Marks',
                  style: TextStyle(
                      color: Colors.white.withAlpha(153), fontSize: 11)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildQuestionsCountBadge() {
    final sumPoints = _questions.fold<int>(
        0, (sum, q) => sum + (int.tryParse(q['points'] ?? '1') ?? 1));
    final totalMarks = int.tryParse(_marksController.text.trim()) ?? 0;
    final isValid = totalMarks == 0 || sumPoints == totalMarks;
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF6C63FF).withAlpha(51),
              const Color(0xFF00D4FF).withAlpha(26)
            ]),
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: const Color(0xFF6C63FF).withAlpha(77))),
        child: Row(children: [
          const Icon(Icons.quiz_outlined,
              color: Color(0xFF6C63FF), size: 16),
          const SizedBox(width: 6),
          Text('Questions: ${_questions.length}',
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: isValid
                ? const Color(0xFF00D4AA).withAlpha(26)
                : const Color(0xFFFF6584).withAlpha(26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isValid
                    ? const Color(0xFF00D4AA).withAlpha(77)
                    : const Color(0xFFFF6584).withAlpha(77))),
        child: Row(children: [
          Icon(isValid ? Icons.check_circle_outline : Icons.warning_outlined,
              color: isValid
                  ? const Color(0xFF00D4AA)
                  : const Color(0xFFFF6584),
              size: 14),
          const SizedBox(width: 6),
          Text('Points: $sumPoints/$totalMarks',
              style: TextStyle(
                  color: isValid
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFFFF6584),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
      ),
    ]);
  }

  Widget _buildQuestionForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6C63FF).withAlpha(77)),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF6C63FF).withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: _questionController,
          maxLines: 3,
          style:
          const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
          decoration: InputDecoration(
              hintText: 'Write your question here...',
              hintStyle:
              TextStyle(color: Colors.white.withAlpha(64), fontSize: 15),
              border: InputBorder.none),
        ),
        Divider(color: Colors.white.withAlpha(20)),
        const SizedBox(height: 12),
        _optionField('A', _optionAController, const Color(0xFF6C63FF)),
        _optionField('B', _optionBController, const Color(0xFF00D4AA)),
        _optionField('C', _optionCController, const Color(0xFFFFB347)),
        _optionField('D', _optionDController, const Color(0xFFFF6584)),
        const SizedBox(height: 16),
        Text('CORRECT ANSWER',
            style: TextStyle(
                color: Colors.white.withAlpha(102),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Row(
            children: ['A', 'B', 'C', 'D']
                .map((opt) => _answerRadio(opt))
                .toList()),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: _glowTextField(_pointsController, 'Points', Icons.bolt,
                keyboardType: TextInputType.number),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _glowTextField(
                _timeController, 'Time (sec)', Icons.timer_outlined,
                keyboardType: TextInputType.number),
          ),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _addQuestion,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF6C63FF).withAlpha(89),
                      blurRadius: 16,
                      offset: const Offset(0, 6))
                ]),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Add Question',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildAddedQuestions() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text('Added Questions',
            style: TextStyle(
                color: Colors.white.withAlpha(153),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
      ),
      ..._questions.asMap().entries.map((entry) {
        final i = entry.key;
        final q = entry.value;
        return Dismissible(
          key: ValueKey('create-$i-${q['question']}'),
          onDismissed: (_) {
            setState(() => _questions.removeAt(i));
            HapticFeedback.mediumImpact();
          },
          background: Container(
            decoration: BoxDecoration(
                color: const Color(0xFFFF6584).withAlpha(38),
                borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Color(0xFFFF6584)),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFF131929),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withAlpha(15))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withAlpha(38),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('Q${i + 1}',
                          style: const TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(q['question'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF00D4AA), size: 14),
                    const SizedBox(width: 4),
                    Text(
                        'Ans: ${q['correct']}  •  ${q['points']} pts  •  ⏱ ${q['timeSecs']}s',
                        style: TextStyle(
                            color: Colors.white.withAlpha(115), fontSize: 12)),
                  ]),
                ]),
          ),
        );
      }),
    ]);
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(128),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: GestureDetector(
        onTap: _isSaving ? null : _saveQuiz,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF6C63FF).withAlpha(89),
                  blurRadius: 16,
                  offset: const Offset(0, 6))
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_isSaving)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
            else ...[
              const Icon(Icons.rocket_launch_outlined,
                  color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text('Publish Quiz',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ]
          ]),
        ),
      ),
    );
  }

  Widget _glowTextField(
      TextEditingController controller, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withAlpha(20))),
      child: Row(children: [
        Icon(icon, color: Colors.white.withAlpha(128), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withAlpha(77)),
                border: InputBorder.none),
          ),
        ),
      ]),
    );
  }

  Widget _optionField(
      String label, TextEditingController controller, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(77))),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withAlpha(77),
                borderRadius: BorderRadius.circular(8)),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                  hintText: 'Option',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _answerRadio(String opt) {
    final selected = _correctAnswer == opt;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _correctAnswer = opt);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: selected ? const Color(0xFF6C63FF) : Colors.white24,
            borderRadius: BorderRadius.circular(12)),
        child: Text(opt,
            style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}