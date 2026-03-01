import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

// ─── Student Quiz Screen (Browse & Start) ───────────────────────────────────

class StudentQuizScreen extends StatefulWidget {
  const StudentQuizScreen({super.key});

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerAnim;

  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Active', 'Completed', 'Missed'];

  final List<Map<String, dynamic>> _quizzes = [
    {
      'title': 'Mathematics - Chapter 5',
      'subject': 'Algebra',
      'teacher': 'Mr. Sharma',
      'questions': 15,
      'totalMarks': 30,
      'duration': 20,
      'status': 'Active',
      'dueDate': 'Due Today, 6:00 PM',
      'color': const Color(0xFF6C63FF),
      'icon': '📐',
      'myScore': null,
      'attempted': false,
    },
    {
      'title': 'English Grammar Test',
      'subject': 'English',
      'teacher': 'Ms. Priya',
      'questions': 20,
      'totalMarks': 40,
      'duration': 30,
      'status': 'Completed',
      'dueDate': 'Submitted Feb 20',
      'color': const Color(0xFFFF6584),
      'icon': '📝',
      'myScore': 35,
      'attempted': true,
    },
    {
      'title': 'Science Quiz - Newton\'s Laws',
      'subject': 'Physics',
      'teacher': 'Mr. Verma',
      'questions': 10,
      'totalMarks': 20,
      'duration': 15,
      'status': 'Active',
      'dueDate': 'Due Feb 24, 5:00 PM',
      'color': const Color(0xFF00D4AA),
      'icon': '🔬',
      'myScore': null,
      'attempted': false,
    },
    {
      'title': 'History - World War II',
      'subject': 'History',
      'teacher': 'Ms. Nair',
      'questions': 12,
      'totalMarks': 24,
      'duration': 18,
      'status': 'Missed',
      'dueDate': 'Expired Feb 18',
      'color': const Color(0xFFFFB347),
      'icon': '🌍',
      'myScore': null,
      'attempted': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredQuizzes {
    if (_selectedFilter == 0) return _quizzes;
    final filter = _filters[_selectedFilter];
    return _quizzes.where((q) => q['status'] == filter).toList();
  }

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _listController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _headerAnim =
        CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic);

    _headerController.forward();
    Future.delayed(
        const Duration(milliseconds: 300), () => _listController.forward());
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildProgressSummary(),
                _buildFilterTabs(),
                Expanded(child: _buildQuizList()),
              ],
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
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                      colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
                    ).createShader(bounds),
                    child: const Text(
                      'My Quizzes',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    'Class 10 — Section A',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              const Spacer(),
              // Avatar
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('AR',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    return AnimatedBuilder(
      animation: _headerAnim,
      builder: (ctx, child) =>
          Opacity(opacity: _headerAnim.value, child: child),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withOpacity(0.18),
                const Color(0xFF00D4AA).withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF6C63FF).withOpacity(0.25), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: _summaryItem('2', 'Pending', const Color(0xFFFFB347)),
              ),
              _divider(),
              Expanded(
                child: _summaryItem('1', 'Completed', const Color(0xFF00D4AA)),
              ),
              _divider(),
              Expanded(
                child: _summaryItem('87%', 'Avg Score', const Color(0xFF6C63FF)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Column(
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
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _divider() {
    return Container(
        width: 1, height: 36, color: Colors.white.withOpacity(0.08));
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 0, 4),
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (context, i) {
            final selected = _selectedFilter == i;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 10),
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  _filters[i],
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withOpacity(0.45),
                    fontSize: 13,
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuizList() {
    final quizzes = _filteredQuizzes;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      itemCount: quizzes.length,
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
          child: _buildQuizCard(quizzes[index]),
        );
      },
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final color = quiz['color'] as Color;
    final status = quiz['status'] as String;
    final attempted = quiz['attempted'] as bool;
    final myScore = quiz['myScore'] as int?;
    final totalMarks = quiz['totalMarks'] as int;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'Active':
        statusColor = const Color(0xFF00D4AA);
        statusLabel = 'Active';
        statusIcon = Icons.radio_button_checked;
        break;
      case 'Completed':
        statusColor = const Color(0xFF6C63FF);
        statusLabel = 'Done';
        statusIcon = Icons.check_circle;
        break;
      case 'Missed':
        statusColor = const Color(0xFFFF6584);
        statusLabel = 'Missed';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.white38;
        statusLabel = status;
        statusIcon = Icons.help_outline;
    }

    return GestureDetector(
      onTap: () {
        if (status == 'Active' && !attempted) {
          _startQuiz(quiz);
        } else if (status == 'Completed') {
          _viewResult(quiz);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.07),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient:
                LinearGradient(colors: [color, color.withOpacity(0.3)]),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
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
                            const SizedBox(height: 2),
                            Text(
                              '${quiz['subject']} • ${quiz['teacher']}',
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
                              color: statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 10),
                            const SizedBox(width: 4),
                            Text(statusLabel,
                                style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Info row
                  Row(
                    children: [
                      _chip(Icons.help_outline,
                          '${quiz['questions']} Questions', color),
                      const SizedBox(width: 14),
                      _chip(Icons.timer_outlined,
                          '${quiz['duration']} mins', color),
                      const SizedBox(width: 14),
                      _chip(Icons.star_outline,
                          '$totalMarks Marks', color),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Due date or score
                  if (status == 'Completed' && myScore != null)
                    _scoreBar(myScore, totalMarks, color)
                  else
                    Row(
                      children: [
                        Icon(
                          status == 'Missed'
                              ? Icons.event_busy
                              : Icons.event_outlined,
                          color: status == 'Missed'
                              ? const Color(0xFFFF6584)
                              : Colors.white.withOpacity(0.4),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          quiz['dueDate'],
                          style: TextStyle(
                            color: status == 'Missed'
                                ? const Color(0xFFFF6584)
                                : Colors.white.withOpacity(0.4),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Bottom CTA
            if (status != 'Missed')
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
                  border: Border(
                      top:
                      BorderSide(color: Colors.white.withOpacity(0.06))),
                ),
                child: Row(
                  children: [
                    if (status == 'Active' && !attempted) ...[
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.7)]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: color.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text('Start Quiz',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ] else if (status == 'Completed') ...[
                      Icon(Icons.visibility_outlined,
                          color: color, size: 16),
                      const SizedBox(width: 6),
                      Text('View Results',
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          color: Colors.white.withOpacity(0.3), size: 18),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 13),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _scoreBar(int score, int total, Color color) {
    final pct = score / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Your Score: ',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12)),
            Text('$score/$total',
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${(pct * 100).toInt()}%',
                style: const TextStyle(
                    color: Color(0xFF00D4AA),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.white.withOpacity(0.06),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  void _startQuiz(Map<String, dynamic> quiz) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: QuizAttemptScreen(quiz: quiz),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _viewResult(Map<String, dynamic> quiz) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: QuizResultScreen(quiz: quiz),
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

// ─── Quiz Attempt Screen ─────────────────────────────────────────────────────

class QuizAttemptScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const QuizAttemptScreen({super.key, required this.quiz});

  @override
  State<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends State<QuizAttemptScreen>
    with TickerProviderStateMixin {
  late AnimationController _questionEntryController;
  late Animation<double> _questionEntryAnim;

  int _currentIndex = 0;
  String? _selectedAnswer;
  final Map<int, String> _answers = {};
  late Timer _timer;
  int _secondsLeft = 0;

  // Demo questions
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is the value of x in the equation 2x + 6 = 14?',
      'options': ['x = 2', 'x = 3', 'x = 4', 'x = 7'],
      'correct': 'x = 4',
      'points': 2,
    },
    {
      'question':
      'Which of the following is the correct expansion of (a + b)²?',
      'options': [
        'a² + b²',
        'a² + 2ab + b²',
        'a² - 2ab + b²',
        '2a + 2b'
      ],
      'correct': 'a² + 2ab + b²',
      'points': 2,
    },
    {
      'question': 'Solve: 5(x - 3) = 2x + 6',
      'options': ['x = 7', 'x = 6', 'x = 5', 'x = 9'],
      'correct': 'x = 7',
      'points': 2,
    },
    {
      'question': 'If f(x) = 3x² - 2x + 1, what is f(2)?',
      'options': ['9', '11', '13', '7'],
      'correct': '9',
      'points': 2,
    },
    {
      'question': 'What is the HCF of 36 and 48?',
      'options': ['6', '9', '12', '18'],
      'correct': '12',
      'points': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _secondsLeft = (widget.quiz['duration'] as int) * 60;

    _questionEntryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _questionEntryAnim = CurvedAnimation(
        parent: _questionEntryController, curve: Curves.easeOutCubic);
    _questionEntryController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
          _submitQuiz();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _questionEntryController.dispose();
    super.dispose();
  }

  String get _timeString {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft > 300) return const Color(0xFF00D4AA);
    if (_secondsLeft > 60) return const Color(0xFFFFB347);
    return const Color(0xFFFF6584);
  }

  void _selectAnswer(String answer) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedAnswer = answer;
      _answers[_currentIndex] = answer;
    });
  }

  void _next() {
    if (_currentIndex < _questions.length - 1) {
      HapticFeedback.lightImpact();
      _questionEntryController.reset();
      setState(() {
        _currentIndex++;
        _selectedAnswer = _answers[_currentIndex];
      });
      _questionEntryController.forward();
    } else {
      _submitQuiz();
    }
  }

  void _prev() {
    if (_currentIndex > 0) {
      HapticFeedback.lightImpact();
      _questionEntryController.reset();
      setState(() {
        _currentIndex--;
        _selectedAnswer = _answers[_currentIndex];
      });
      _questionEntryController.forward();
    }
  }

  void _submitQuiz() {
    _timer.cancel();
    HapticFeedback.heavyImpact();
    // Calculate score
    int score = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i]['correct']) {
        score += (_questions[i]['points'] as int);
      }
    }

    // Build result data
    final resultData = Map<String, dynamic>.from(widget.quiz);
    resultData['myScore'] = score;
    resultData['answers'] = _answers;
    resultData['questions'] = _questions;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: QuizResultScreen(quiz: resultData),
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Submit Quiz?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'You have answered ${_answers.length}/${_questions.length} questions. Submit now?',
          style: TextStyle(
              color: Colors.white.withOpacity(0.6), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6C63FF))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitQuiz();
            },
            child: const Text('Submit',
                style: TextStyle(
                    color: Color(0xFF00D4AA), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _questions[_currentIndex];
    final color = widget.quiz['color'] as Color;
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: Column(
              children: [
                _buildAttemptHeader(color, progress),
                Expanded(
                  child: FadeTransition(
                    opacity: _questionEntryAnim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                          begin: const Offset(0.05, 0), end: Offset.zero)
                          .animate(_questionEntryAnim),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                        children: [
                          _buildQuestionCard(q, color),
                          const SizedBox(height: 16),
                          _buildOptions(q, color),
                          const SizedBox(height: 20),
                          _buildQuestionNav(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom navigation
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomNav(color),
          ),
        ],
      ),
    );
  }

  Widget _buildAttemptHeader(Color color, double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF131929),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: const Text('Exit Quiz?',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                    content: Text('Your progress will be lost.',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Stay',
                              style: TextStyle(color: Color(0xFF6C63FF)))),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text('Exit',
                              style:
                              TextStyle(color: Color(0xFFFF6584)))),
                    ],
                  ),
                ),
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
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.quiz['title'],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Q${_currentIndex + 1} of ${_questions.length}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Timer
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _timerColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: _timerColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: _timerColor, size: 15),
                    const SizedBox(width: 5),
                    Text(_timeString,
                        style: TextStyle(
                            color: _timerColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [
                              FontFeature.tabularFigures()
                            ])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, Color color) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Q${_currentIndex + 1}',
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${q['points']} pts',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            q['question'],
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.5,
                letterSpacing: -0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(Map<String, dynamic> q, Color color) {
    final options = q['options'] as List<String>;
    final labels = ['A', 'B', 'C', 'D'];
    final optColors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D4AA),
      const Color(0xFFFFB347),
      const Color(0xFFFF6584),
    ];

    return Column(
      children: List.generate(options.length, (i) {
        final opt = options[i];
        final selected = _selectedAnswer == opt;
        final optColor = optColors[i];

        return GestureDetector(
          onTap: () => _selectAnswer(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: selected
                  ? optColor.withOpacity(0.15)
                  : const Color(0xFF131929),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? optColor : Colors.white.withOpacity(0.08),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                BoxShadow(
                    color: optColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ]
                  : [],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: selected
                        ? optColor
                        : optColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(labels[i],
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : optColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    opt,
                    style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        height: 1.4),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle,
                      color: optColor, size: 20),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuestionNav() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_questions.length, (i) {
        final answered = _answers.containsKey(i);
        final current = _currentIndex == i;
        return GestureDetector(
          onTap: () {
            _questionEntryController.reset();
            setState(() {
              _currentIndex = i;
              _selectedAnswer = _answers[i];
            });
            _questionEntryController.forward();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: current
                  ? const Color(0xFF6C63FF)
                  : answered
                  ? const Color(0xFF00D4AA).withOpacity(0.2)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: current
                    ? const Color(0xFF6C63FF)
                    : answered
                    ? const Color(0xFF00D4AA)
                    : Colors.white.withOpacity(0.1),
                width: current ? 0 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: TextStyle(
                    color: current
                        ? Colors.white
                        : answered
                        ? const Color(0xFF00D4AA)
                        : Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBottomNav(Color color) {
    final isLast = _currentIndex == _questions.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
      child: Row(
        children: [
          if (_currentIndex > 0)
            GestureDetector(
              onTap: _prev,
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border:
                  Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 16),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: isLast ? _confirmSubmit : _next,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: isLast
                      ? const LinearGradient(colors: [
                    Color(0xFF00D4AA),
                    Color(0xFF00A878)
                  ])
                      : LinearGradient(
                      colors: [color, color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: (isLast
                          ? const Color(0xFF00D4AA)
                          : color)
                          .withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLast
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isLast ? 'Submit Quiz' : 'Next Question',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quiz Result Screen ──────────────────────────────────────────────────────

class QuizResultScreen extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const QuizResultScreen({super.key, required this.quiz});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _scoreController;
  late Animation<double> _entryAnim;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scoreController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _entryAnim = CurvedAnimation(
        parent: _entryController, curve: Curves.easeOutCubic);
    _scoreAnim = CurvedAnimation(
        parent: _scoreController, curve: Curves.easeOutCubic);

    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 400),
            () => _scoreController.forward());
  }

  @override
  void dispose() {
    _entryController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;
    final myScore = quiz['myScore'] as int? ?? 0;
    final totalMarks = quiz['totalMarks'] as int;
    final color = quiz['color'] as Color;
    final pct = myScore / totalMarks;
    final questions =
        quiz['questions'] as List<Map<String, dynamic>>? ?? [];
    final answers = quiz['answers'] as Map<int, String>? ?? {};

    String grade;
    Color gradeColor;
    String emoji;
    if (pct >= 0.9) {
      grade = 'A+';
      gradeColor = const Color(0xFF00D4AA);
      emoji = '🏆';
    } else if (pct >= 0.75) {
      grade = 'A';
      gradeColor = const Color(0xFF6C63FF);
      emoji = '🌟';
    } else if (pct >= 0.6) {
      grade = 'B';
      gradeColor = const Color(0xFFFFB347);
      emoji = '👍';
    } else {
      grade = 'C';
      gradeColor = const Color(0xFFFF6584);
      emoji = '💪';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _BgPainter())),
          SafeArea(
            child: FadeTransition(
              opacity: _entryAnim,
              child: Column(
                children: [
                  _buildResultHeader(color),
                  Expanded(
                    child: ListView(
                      padding:
                      const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      children: [
                        _buildScoreHero(myScore, totalMarks, pct, grade,
                            gradeColor, emoji, color),
                        const SizedBox(height: 20),
                        _buildStatsRow(questions, answers),
                        const SizedBox(height: 20),
                        if (questions.isNotEmpty) ...[
                          _buildSectionTitle('Answer Review'),
                          const SizedBox(height: 12),
                          ...List.generate(
                              questions.length,
                                  (i) => _buildAnswerRow(
                                  i, questions[i], answers[i])),
                        ],
                        const SizedBox(height: 20),
                        _buildDoneButton(color),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultHeader(Color color) {
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
                border:
                Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
            ).createShader(bounds),
            child: const Text(
              'Quiz Result',
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

  Widget _buildScoreHero(int score, int total, double pct, String grade,
      Color gradeColor, String emoji, Color color) {
    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (ctx, child) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradeColor.withOpacity(0.15),
              const Color(0xFF131929),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: gradeColor.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
                color: gradeColor.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(score * _scoreAnim.value).toInt()}',
                  style: TextStyle(
                      color: gradeColor,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '/$total',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 24,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                Border.all(color: gradeColor.withOpacity(0.3)),
              ),
              child: Text(
                'Grade $grade  •  ${(pct * 100).toInt()}%',
                style: TextStyle(
                    color: gradeColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct * _scoreAnim.value,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
      List<Map<String, dynamic>> questions, Map<int, String> answers) {
    int correct = 0;
    int wrong = 0;
    int skipped = 0;
    for (int i = 0; i < questions.length; i++) {
      if (!answers.containsKey(i)) {
        skipped++;
      } else if (answers[i] == questions[i]['correct']) {
        correct++;
      } else {
        wrong++;
      }
    }

    return Row(
      children: [
        _resultStat('$correct', 'Correct', const Color(0xFF00D4AA),
            Icons.check_circle_outline),
        const SizedBox(width: 10),
        _resultStat(
            '$wrong', 'Wrong', const Color(0xFFFF6584), Icons.cancel_outlined),
        const SizedBox(width: 10),
        _resultStat('$skipped', 'Skipped', const Color(0xFFFFB347),
            Icons.remove_circle_outline),
      ],
    );
  }

  Widget _resultStat(
      String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5));
  }

  Widget _buildAnswerRow(
      int i, Map<String, dynamic> q, String? myAnswer) {
    final correct = q['correct'] as String;
    final isCorrect = myAnswer == correct;
    final skipped = myAnswer == null;

    Color indicatorColor;
    IconData indicatorIcon;
    if (skipped) {
      indicatorColor = const Color(0xFFFFB347);
      indicatorIcon = Icons.remove_circle;
    } else if (isCorrect) {
      indicatorColor = const Color(0xFF00D4AA);
      indicatorIcon = Icons.check_circle;
    } else {
      indicatorColor = const Color(0xFFFF6584);
      indicatorIcon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: indicatorColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: indicatorColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text('Q${i + 1}',
                style: TextStyle(
                    color: indicatorColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q['question'],
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                if (!skipped && !isCorrect) ...[
                  Text('Your answer: $myAnswer',
                      style: const TextStyle(
                          color: Color(0xFFFF6584),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                ],
                Text(
                  skipped ? 'Not attempted' : 'Correct: $correct',
                  style: TextStyle(
                      color: skipped
                          ? const Color(0xFFFFB347)
                          : const Color(0xFF00D4AA),
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(indicatorIcon, color: indicatorColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildDoneButton(Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Back to Dashboard',
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
}

// ─── Background Painter ──────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    paint.color = const Color(0xFF6C63FF).withOpacity(0.06);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.12), 180, paint);
    paint.color = const Color(0xFF00D4AA).withOpacity(0.05);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.6), 140, paint);
    paint.color = const Color(0xFFFF6584).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.85), 120, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}