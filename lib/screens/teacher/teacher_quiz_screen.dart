import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

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

  final List<Map<String, dynamic>> _quizzes = [
    {
      'title': 'Mathematics - Chapter 5',
      'subject': 'Algebra',
      'questions': 15,
      'totalMarks': 30,
      'status': 'Active',
      'submissions': 18,
      'total': 32,
      'color': const Color(0xFF6C63FF),
      'icon': '📐',
    },
    {
      'title': 'Science Quiz - Newton\'s Laws',
      'subject': 'Physics',
      'questions': 10,
      'totalMarks': 20,
      'status': 'Pending',
      'submissions': 0,
      'total': 32,
      'color': const Color(0xFF00D4AA),
      'icon': '🔬',
    },
    {
      'title': 'English Grammar Test',
      'subject': 'English',
      'questions': 20,
      'totalMarks': 40,
      'status': 'Completed',
      'submissions': 30,
      'total': 32,
      'color': const Color(0xFFFF6584),
      'icon': '📝',
    },
    {
      'title': 'History - World War II',
      'subject': 'History',
      'questions': 12,
      'totalMarks': 24,
      'status': 'Active',
      'submissions': 5,
      'total': 32,
      'color': const Color(0xFFFFB347),
      'icon': '🌍',
    },
  ];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _listController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _headerAnim = CurvedAnimation(
        parent: _headerController, curve: Curves.easeOutCubic);
    _fabAnim =
        CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300),
            () => _listController.forward());
    Future.delayed(
        const Duration(milliseconds: 600), () => _fabController.forward());
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
          // Background mesh gradient
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStatsRow(),
                Expanded(child: _buildQuizList()),
              ],
            ),
          ),
          // FAB
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

  Widget _buildBackground() {
    return CustomPaint(painter: _BackgroundPainter());
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnim,
      child: SlideTransition(
        position: Tween<Offset>(
            begin: const Offset(0, -0.3), end: Offset.zero)
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
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1), width: 1),
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
                    child: const Text(
                      'Quiz Studio',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    'Manage & Create Quizzes',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w400),
                  ),
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
                child:
                const Icon(Icons.filter_list, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return AnimatedBuilder(
      animation: _headerAnim,
      builder: (context, child) => Opacity(
        opacity: _headerAnim.value,
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            _statChip('4', 'Total Quizzes', const Color(0xFF6C63FF)),
            const SizedBox(width: 10),
            _statChip('2', 'Active', const Color(0xFF00D4AA)),
            const SizedBox(width: 10),
            _statChip('53', 'Submissions', const Color(0xFFFFB347)),
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
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
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
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: _quizzes.length,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _listController,
          builder: (context, child) {
            final delay = index * 0.15;
            final animValue = math.max(
                0.0,
                math.min(
                    1.0, (_listController.value - delay) / (1.0 - delay)));
            final curve =
            Curves.easeOutCubic.transform(animValue.clamp(0.0, 1.0));
            return Opacity(
              opacity: curve,
              child: Transform.translate(
                offset: Offset(0, 40 * (1 - curve)),
                child: child,
              ),
            );
          },
          child: _buildQuizCard(_quizzes[index], index),
        );
      },
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, int index) {
    final color = quiz['color'] as Color;
    final status = quiz['status'] as String;
    final submissions = quiz['submissions'] as int;
    final total = quiz['total'] as int;
    final progress = submissions / total;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Active':
        statusColor = const Color(0xFF00D4AA);
        statusIcon = Icons.radio_button_checked;
        break;
      case 'Pending':
        statusColor = const Color(0xFFFFB347);
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.white38;
        statusIcon = Icons.check_circle_outline;
    }

    return GestureDetector(
      onTap: () => _showQuizOptions(quiz),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card top bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.3)]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
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
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(quiz['icon'],
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz['title'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              quiz['subject'],
                              style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: statusColor.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 10),
                            const SizedBox(width: 4),
                            Text(status,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _infoChip(
                          '${quiz['questions']} Qs',
                          Icons.help_outline,
                          Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 12),
                      _infoChip(
                          '${quiz['totalMarks']} Marks',
                          Icons.star_outline,
                          Colors.white.withOpacity(0.6)),
                      const Spacer(),
                      Text(
                        '$submissions/$total',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progress * 100).toInt()}% submitted',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
            // Action buttons
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(0.06))),
              ),
              child: Row(
                children: [
                  _actionBtn('View Results', Icons.bar_chart, color),
                  const SizedBox(width: 10),
                  _actionBtn('Edit', Icons.edit_outlined,
                      Colors.white.withOpacity(0.5)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _confirmDelete(index),
                    child: Icon(Icons.delete_outline,
                        color: Colors.white.withOpacity(0.3), size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCreateFAB() {
    return GestureDetector(
      onTap: () => _showCreateQuizSheet(),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
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
      builder: (context) => _QuizOptionsSheet(quiz: quiz),
    );
  }

  void _showCreateQuizSheet() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const QuizCreatorScreen(),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _confirmDelete(int index) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Quiz',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete this quiz?',
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6C63FF))),
          ),
          TextButton(
            onPressed: () {
              setState(() => _quizzes.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFFF6584))),
          ),
        ],
      ),
    );
  }
}

// ─── Background Painter ──────────────────────────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF6C63FF).withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.12), 180, paint);

    paint.color = const Color(0xFF00D4FF).withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.6), 140, paint);

    paint.color = const Color(0xFFFF6584).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.8), 120, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Quiz Options Bottom Sheet ────────────────────────────────────────────────

class _QuizOptionsSheet extends StatelessWidget {
  final Map<String, dynamic> quiz;
  const _QuizOptionsSheet({required this.quiz});

  @override
  Widget build(BuildContext context) {
    final color = quiz['color'] as Color;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF131929),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(quiz['icon'], style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quiz['title'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  Text(quiz['subject'],
                      style: TextStyle(color: color, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sheetOption(Icons.bar_chart_rounded, 'View Results',
              'See student performance', color, () => Navigator.pop(context)),
          _sheetOption(Icons.share_outlined, 'Share Quiz',
              'Share with students', const Color(0xFF00D4AA), () => Navigator.pop(context)),
          _sheetOption(Icons.edit_outlined, 'Edit Quiz',
              'Modify questions or settings', const Color(0xFFFFB347), () => Navigator.pop(context)),
          _sheetOption(Icons.copy_outlined, 'Duplicate Quiz',
              'Create a copy', Colors.white54, () => Navigator.pop(context)),
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
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Quiz Creator Screen ──────────────────────────────────────────────────────

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

  String _correctAnswer = 'A';
  final List<Map<String, dynamic>> _questions = [];
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
    super.dispose();
  }

  void _addQuestion() {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF6584),
          content: const Text('Please write a question first!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
        'points': _pointsController.text.trim(),
      });
      _questionController.clear();
      _optionAController.clear();
      _optionBController.clear();
      _optionCController.clear();
      _optionDController.clear();
      _pointsController.clear();
      _correctAnswer = 'A';
    });
  }

  void _submitQuiz() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFFB347),
          content: const Text('Quiz title is required!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF6584),
          content: const Text('Add at least one question!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🎉 Quiz Created!',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          '"${_titleController.text}" with ${_questions.length} question(s) has been saved successfully.',
          style:
          TextStyle(color: Colors.white.withOpacity(0.65), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF00D4FF)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          CustomPaint(painter: _BackgroundPainter(), size: Size.infinite),
          SafeArea(
            child: FadeTransition(
              opacity: _entryAnim,
              child: Column(
                children: [
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
                ],
              ),
            ),
          ),
          // Submit button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSubmitBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D4FF), Color(0xFF6C63FF)],
            ).createShader(bounds),
            child: const Text(
              'Quiz Creator',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInfoCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _glowTextField(_titleController, 'Quiz Title', Icons.title),
          const SizedBox(height: 12),
          _glowTextField(
              _marksController, 'Total Marks', Icons.star_outline,
              keyboardType: TextInputType.number),
        ],
      ),
    );
  }

  Widget _glowTextField(
      TextEditingController controller, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
        prefixIcon: Icon(icon,
            color: const Color(0xFF6C63FF).withOpacity(0.7), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildQuestionsCountBadge() {
    return Row(
      children: [
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withOpacity(0.2),
                const Color(0xFF00D4FF).withOpacity(0.1)
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.quiz_outlined,
                  color: Color(0xFF6C63FF), size: 16),
              const SizedBox(width: 6),
              Text(
                'Questions Added: ${_questions.length}',
                style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _questionController,
            maxLines: 3,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Write your question here...',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25), fontSize: 15),
              border: InputBorder.none,
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 12),
          ...[
            ['A', _optionAController, const Color(0xFF6C63FF)],
            ['B', _optionBController, const Color(0xFF00D4AA)],
            ['C', _optionCController, const Color(0xFFFFB347)],
            ['D', _optionDController, const Color(0xFFFF6584)],
          ].map((item) => _optionField(
              item[0] as String,
              item[1] as TextEditingController,
              item[2] as Color)),
          const SizedBox(height: 16),
          Text('CORRECT ANSWER',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: ['A', 'B', 'C', 'D']
                .map((opt) => _answerRadio(opt))
                .toList(),
          ),
          const SizedBox(height: 16),
          _glowTextField(
              _pointsController, 'Points for this question', Icons.bolt,
              keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _addQuestion,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00D4FF), Color(0xFF6C63FF)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline,
                      color: Colors.white, size: 20),
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
        ],
      ),
    );
  }

  Widget _optionField(
      String label, TextEditingController controller, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Option $label',
          hintStyle:
          TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _answerRadio(String option) {
    final colors = {
      'A': const Color(0xFF6C63FF),
      'B': const Color(0xFF00D4AA),
      'C': const Color(0xFFFFB347),
      'D': const Color(0xFFFF6584),
    };
    final color = colors[option]!;
    final selected = _correctAnswer == option;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _correctAnswer = option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          height: 44,
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : Colors.white.withOpacity(0.1),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(option,
                style: TextStyle(
                    color: selected ? color : Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          ),
        ),
      ),
    );
  }

  Widget _buildAddedQuestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Added Questions',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ),
        ..._questions.asMap().entries.map((entry) {
          final i = entry.key;
          final q = entry.value;
          return Dismissible(
            key: ValueKey(i),
            onDismissed: (_) {
              setState(() => _questions.removeAt(i));
              HapticFeedback.mediumImpact();
            },
            background: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFF6584).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
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
                border: Border.all(
                    color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Q${i + 1}',
                            style: const TextStyle(
                                color: Color(0xFF6C63FF),
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          q['question'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: const Color(0xFF00D4AA), size: 14),
                      const SizedBox(width: 4),
                      Text('Answer: ${q['correct']}  •  ${q['points']} pts',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Center(
            child: Text('← Swipe to delete →',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 11)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0E1A).withOpacity(0),
            const Color(0xFF0A0E1A),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: _submitQuiz,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9B4DCA)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch_outlined,
                  color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Finalize & Publish',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}