import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ─── STUDENT MARKS SCREEN ────────────────────────────────────────────────────
// Student sirf apne marks dekh sakta hai — read-only beautiful UI
// Screens:
//   1. StudentMarksScreen      → Subject overview + overall performance card
//   2. _SubjectDetailSheet     → Bottom sheet: subject ke detailed marks + rank
// ─────────────────────────────────────────────────────────────────────────────

// ─── MODELS ──────────────────────────────────────────────────────────────────

class _SubjectResult {
  final String name;
  final String icon;
  final Color color;
  final int marks;
  final int totalMarks;
  final int rank;
  final int totalStudents;
  final double classAverage;
  final String examType; // 'Unit Test', 'Mid Term', 'Final'
  final String date;

  const _SubjectResult({
    required this.name,
    required this.icon,
    required this.color,
    required this.marks,
    required this.totalMarks,
    required this.rank,
    required this.totalStudents,
    required this.classAverage,
    required this.examType,
    required this.date,
  });

  double get percentage => (marks / totalMarks) * 100;

  String get grade {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    return 'F';
  }

  Color get gradeColor {
    if (percentage >= 90) return const Color(0xFF00D4AA);
    if (percentage >= 80) return const Color(0xFF6C63FF);
    if (percentage >= 70) return const Color(0xFF00D4FF);
    if (percentage >= 60) return const Color(0xFFFFB347);
    if (percentage >= 50) return const Color(0xFFFF8C42);
    return const Color(0xFFFF6584);
  }

  String get gradeLabel {
    if (percentage >= 90) return 'Outstanding';
    if (percentage >= 80) return 'Excellent';
    if (percentage >= 70) return 'Very Good';
    if (percentage >= 60) return 'Good';
    if (percentage >= 50) return 'Average';
    return 'Needs Work';
  }

  bool get aboveAverage => marks > classAverage;
}

// ─── MOCK DATA ────────────────────────────────────────────────────────────────

final List<_SubjectResult> _mockResults = [
  _SubjectResult(
    name: 'Mathematics',
    icon: '📐',
    color: const Color(0xFF6C63FF),
    marks: 88,
    totalMarks: 100,
    rank: 4,
    totalStudents: 32,
    classAverage: 74.5,
    examType: 'Mid Term',
    date: 'Feb 15, 2026',
  ),
  _SubjectResult(
    name: 'Science',
    icon: '🔬',
    color: const Color(0xFF00D4AA),
    marks: 72,
    totalMarks: 100,
    rank: 11,
    totalStudents: 32,
    classAverage: 68.2,
    examType: 'Mid Term',
    date: 'Feb 15, 2026',
  ),
  _SubjectResult(
    name: 'English',
    icon: '📖',
    color: const Color(0xFFFF6584),
    marks: 65,
    totalMarks: 80,
    rank: 9,
    totalStudents: 32,
    classAverage: 61.8,
    examType: 'Mid Term',
    date: 'Feb 16, 2026',
  ),
  _SubjectResult(
    name: 'History',
    icon: '🌍',
    color: const Color(0xFFFFB347),
    marks: 38,
    totalMarks: 50,
    rank: 7,
    totalStudents: 32,
    classAverage: 38.4,
    examType: 'Unit Test',
    date: 'Feb 10, 2026',
  ),
  _SubjectResult(
    name: 'Computer',
    icon: '💻',
    color: const Color(0xFF00D4FF),
    marks: 95,
    totalMarks: 100,
    rank: 2,
    totalStudents: 32,
    classAverage: 82.1,
    examType: 'Mid Term',
    date: 'Feb 17, 2026',
  ),
  _SubjectResult(
    name: 'Hindi',
    icon: '✍️',
    color: const Color(0xFFFF8C42),
    marks: 78,
    totalMarks: 100,
    rank: 6,
    totalStudents: 32,
    classAverage: 71.3,
    examType: 'Mid Term',
    date: 'Feb 18, 2026',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class StudentMarksScreen extends StatefulWidget {
  const StudentMarksScreen({super.key});

  @override
  State<StudentMarksScreen> createState() => _StudentMarksScreenState();
}

class _StudentMarksScreenState extends State<StudentMarksScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late AnimationController _scoreCtrl;
  late Animation<double> _headerAnim;
  late Animation<double> _scoreAnim;

  // Computed overall stats
  int get _totalMarksObtained =>
      _mockResults.fold(0, (sum, r) => sum + r.marks);
  int get _totalMarksMax =>
      _mockResults.fold(0, (sum, r) => sum + r.totalMarks);
  double get _overallPercentage =>
      (_totalMarksObtained / _totalMarksMax) * 100;
  double get _bestRankPct =>
      _mockResults.map((r) => r.rank / r.totalStudents).reduce(math.min);

  String get _overallGrade {
    if (_overallPercentage >= 90) return 'A+';
    if (_overallPercentage >= 80) return 'A';
    if (_overallPercentage >= 70) return 'B+';
    if (_overallPercentage >= 60) return 'B';
    return 'C';
  }

  Color get _overallGradeColor {
    if (_overallPercentage >= 90) return const Color(0xFF00D4AA);
    if (_overallPercentage >= 80) return const Color(0xFF6C63FF);
    if (_overallPercentage >= 70) return const Color(0xFF00D4FF);
    if (_overallPercentage >= 60) return const Color(0xFFFFB347);
    return const Color(0xFFFF6584);
  }

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _scoreCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));

    _headerAnim =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _scoreAnim =
        CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic);

    _headerCtrl.forward();
    Future.delayed(
        const Duration(milliseconds: 200), () => _scoreCtrl.forward());
    Future.delayed(
        const Duration(milliseconds: 400), () => _listCtrl.forward());
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MarkssBgPainter())),
          SafeArea(
            child: FadeTransition(
              opacity: _headerAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
                      children: [
                        _buildOverallScoreCard(),
                        _buildExamTypeTag(),
                        _buildSectionTitle('Subject-wise Results'),
                        _buildSubjectCards(),
                        _buildSectionTitle('Performance Insights'),
                        _buildInsightsRow(),
                        const SizedBox(height: 20),
                        _buildRankStrip(),
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

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
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
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFFFFB347)],
                ).createShader(b),
                child: const Text(
                  'My Results',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Text(
                'Mid Term Examination 2025–26',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          // Report download hint
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4AA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF00D4AA).withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.download_outlined,
                    color: Color(0xFF00D4AA), size: 16),
                SizedBox(width: 5),
                Text('Report',
                    style: TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Overall Score Card ─────────────────────────────────────────────────────

  Widget _buildOverallScoreCard() {
    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (ctx, _) {
        final displayPct =
        (_overallPercentage * _scoreAnim.value).toStringAsFixed(1);
        final displayMarks =
        (_totalMarksObtained * _scoreAnim.value).toInt();

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [
                _overallGradeColor.withOpacity(0.2),
                const Color(0xFF131929),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border:
            Border.all(color: _overallGradeColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: _overallGradeColor.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top glow bar
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_overallGradeColor, _overallGradeColor.withOpacity(0.3)]),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Score circle
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: _overallPercentage / 100 * _scoreAnim.value,
                                strokeWidth: 7,
                                backgroundColor: Colors.white.withOpacity(0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _overallGradeColor),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  _overallGrade,
                                  style: TextStyle(
                                    color: _overallGradeColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                                Text(
                                  '$displayPct%',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Score',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$displayMarks',
                                      style: TextStyle(
                                        color: _overallGradeColor,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -2,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' / $_totalMarksMax',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _overallGradeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _overallGradeColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _overallPercentage >= 80
                                      ? '🌟 Excellent Work!'
                                      : _overallPercentage >= 60
                                      ? '👍 Keep it up!'
                                      : '💪 You can do better!',
                                  style: TextStyle(
                                      color: _overallGradeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Mini stats row
                    Row(
                      children: [
                        _miniStat('${_mockResults.length}', 'Subjects',
                            const Color(0xFF6C63FF)),
                        _miniDivider(),
                        _miniStat(
                            '${_mockResults.where((r) => r.aboveAverage).length}',
                            'Above Avg',
                            const Color(0xFF00D4AA)),
                        _miniDivider(),
                        _miniStat(
                            '${_mockResults.map((r) => r.rank).reduce(math.min)}',
                            'Best Rank',
                            const Color(0xFFFFB347)),
                        _miniDivider(),
                        _miniStat(
                            '${_mockResults.where((r) => r.grade == 'A+' || r.grade == 'A').length}',
                            'A Grades',
                            const Color(0xFFFF8C42)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _miniDivider() =>
      Container(width: 1, height: 34, color: Colors.white.withOpacity(0.08));

  // ── Exam type tag ──────────────────────────────────────────────────────────

  Widget _buildExamTypeTag() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFB347).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFFFFB347).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_note_outlined,
                    color: Color(0xFFFFB347), size: 14),
                SizedBox(width: 6),
                Text('Mid Term — Feb 2026',
                    style: TextStyle(
                        color: Color(0xFFFFB347),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border:
              Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline,
                    color: Colors.white.withOpacity(0.4), size: 14),
                const SizedBox(width: 6),
                Text('Class 10 — A',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5),
      ),
    );
  }

  // ── Subject Cards ─────────────────────────────────────────────────────────

  Widget _buildSubjectCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: List.generate(_mockResults.length, (i) {
          return AnimatedBuilder(
            animation: _listCtrl,
            builder: (ctx, child) {
              final delay = i * 0.12;
              final v = math.max(
                  0.0,
                  math.min(
                      1.0,
                      (_listCtrl.value - delay) / (1.0 - delay)));
              final curve =
              Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
              return Opacity(
                opacity: curve,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - curve)),
                  child: child,
                ),
              );
            },
            child: _buildSubjectCard(_mockResults[i]),
          );
        }),
      ),
    );
  }

  Widget _buildSubjectCard(_SubjectResult result) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showSubjectDetail(result);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border:
          Border.all(color: result.color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
                color: result.color.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            // Accent top bar
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [result.color, result.color.withOpacity(0.2)]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Subject icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: result.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(result.icon,
                              style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Subject name + exam type
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(result.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.schedule_outlined,
                                    color: Colors.white.withOpacity(0.35),
                                    size: 11),
                                const SizedBox(width: 3),
                                Text(result.examType,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(width: 8),
                                Text('•',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.2),
                                        fontSize: 10)),
                                const SizedBox(width: 8),
                                Text(result.date,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.35),
                                        fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Marks + Grade badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                text: '${result.marks}',
                                style: TextStyle(
                                    color: result.gradeColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1),
                              ),
                              TextSpan(
                                text: '/${result.totalMarks}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.3),
                                    fontSize: 13),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: result.gradeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                  result.gradeColor.withOpacity(0.35)),
                            ),
                            child: Text(result.grade,
                                style: TextStyle(
                                    color: result.gradeColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar + stats row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: result.percentage / 100,
                                backgroundColor:
                                Colors.white.withOpacity(0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    result.gradeColor),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  '${result.percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      color: result.gradeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                Text('•',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.2))),
                                const SizedBox(width: 8),
                                Text(result.gradeLabel,
                                    style: TextStyle(
                                        color:
                                        Colors.white.withOpacity(0.4),
                                        fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Rank chip
                      _RankChip(
                          rank: result.rank,
                          total: result.totalStudents,
                          color: result.color),
                      const SizedBox(width: 8),
                      // Above/below avg
                      _AvgChip(aboveAverage: result.aboveAverage),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right,
                          color: Colors.white.withOpacity(0.2), size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Insights Row ───────────────────────────────────────────────────────────

  Widget _buildInsightsRow() {
    final best = _mockResults.reduce((a, b) => a.percentage > b.percentage ? a : b);
    final lowest = _mockResults.reduce((a, b) => a.percentage < b.percentage ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _InsightCard(
              label: 'Best Subject',
              value: best.name,
              sub: '${best.marks}/${best.totalMarks}',
              icon: best.icon,
              color: const Color(0xFF00D4AA),
              iconBg: const Color(0xFF00D4AA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InsightCard(
              label: 'Needs Attention',
              value: lowest.name,
              sub: '${lowest.marks}/${lowest.totalMarks}',
              icon: lowest.icon,
              color: const Color(0xFFFF6584),
              iconBg: const Color(0xFFFF6584),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rank Strip ─────────────────────────────────────────────────────────────

  Widget _buildRankStrip() {
    final bestRankSubject = _mockResults
        .reduce((a, b) => a.rank < b.rank ? a : b);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFB347).withOpacity(0.12),
            const Color(0xFF6C63FF).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB347).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🏅', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Class Rank',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '#${bestRankSubject.rank}',
                      style: const TextStyle(
                          color: Color(0xFFFFB347),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                    TextSpan(
                      text:
                      ' in ${bestRankSubject.name}  •  out of ${bestRankSubject.totalStudents}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          Text(
            'Top ${((bestRankSubject.rank / bestRankSubject.totalStudents) * 100).toInt()}%',
            style: const TextStyle(
                color: Color(0xFFFFB347),
                fontSize: 14,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ── Subject Detail Bottom Sheet ────────────────────────────────────────────

  void _showSubjectDetail(_SubjectResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SubjectDetailSheet(result: result),
    );
  }
}

// ─── Rank Chip Widget ─────────────────────────────────────────────────────────

class _RankChip extends StatelessWidget {
  final int rank;
  final int total;
  final Color color;
  const _RankChip(
      {required this.rank, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.leaderboard_outlined, color: color, size: 11),
          const SizedBox(width: 3),
          Text('#$rank',
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── Avg Chip Widget ──────────────────────────────────────────────────────────

class _AvgChip extends StatelessWidget {
  final bool aboveAverage;
  const _AvgChip({required this.aboveAverage});

  @override
  Widget build(BuildContext context) {
    final color = aboveAverage
        ? const Color(0xFF00D4AA)
        : const Color(0xFFFF6584);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Icon(
        aboveAverage ? Icons.trending_up : Icons.trending_down,
        color: color,
        size: 13,
      ),
    );
  }
}

// ─── Insight Card Widget ──────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final String icon;
  final Color color;
  final Color iconBg;

  const _InsightCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const Spacer(),
              Icon(
                color == const Color(0xFF00D4AA)
                    ? Icons.emoji_events_outlined
                    : Icons.flag_outlined,
                color: color,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 1),
          Text(sub,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Subject Detail Bottom Sheet ─────────────────────────────────────────────

class _SubjectDetailSheet extends StatelessWidget {
  final _SubjectResult result;
  const _SubjectDetailSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Subject title row
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: result.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(result.icon,
                        style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      Text('${result.examType} • ${result.date}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: result.gradeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: result.gradeColor.withOpacity(0.35)),
                  ),
                  child: Text(result.grade,
                      style: TextStyle(
                          color: result.gradeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Big score display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    result.color.withOpacity(0.12),
                    result.gradeColor.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: result.color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marks Obtained',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                              text: '${result.marks}',
                              style: TextStyle(
                                color: result.gradeColor,
                                fontSize: 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${result.totalMarks}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 20,
                              ),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Text(result.gradeLabel,
                            style: TextStyle(
                                color: result.gradeColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  // Circular progress
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: result.percentage / 100,
                          strokeWidth: 7,
                          backgroundColor: Colors.white.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              result.gradeColor),
                          strokeCap: StrokeCap.round,
                        ),
                        Text(
                          '${result.percentage.toInt()}%',
                          style: TextStyle(
                              color: result.gradeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats grid
            Row(
              children: [
                _detailStat('Class Avg',
                    '${result.classAverage.toStringAsFixed(1)}',
                    const Color(0xFF6C63FF)),
                const SizedBox(width: 10),
                _detailStat(
                    'Your Score', '${result.marks}', result.gradeColor),
                const SizedBox(width: 10),
                _detailStat('Difference',
                    '${result.marks > result.classAverage ? '+' : ''}${(result.marks - result.classAverage).toStringAsFixed(1)}',
                    result.aboveAverage
                        ? const Color(0xFF00D4AA)
                        : const Color(0xFFFF6584)),
              ],
            ),

            const SizedBox(height: 16),

            // Rank card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Row(
                children: [
                  const Text('🏅', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class Rank',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 12)),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text: '#${result.rank}',
                            style: const TextStyle(
                                color: Color(0xFFFFB347),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5),
                          ),
                          TextSpan(
                            text: ' out of ${result.totalStudents}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 14),
                          ),
                        ]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB347).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFFB347).withOpacity(0.3)),
                    ),
                    child: Text(
                      'Top ${((result.rank / result.totalStudents) * 100).toInt()}%',
                      style: const TextStyle(
                          color: Color(0xFFFFB347),
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Above/below class avg comparison bar
            _buildComparisonBar(),
          ],
        ),
      ),
    );
  }

  Widget _detailStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonBar() {
    final yourPct = result.percentage / 100;
    final avgPct = (result.classAverage / result.totalMarks);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('vs Class Average',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          // Your score bar
          Row(
            children: [
              SizedBox(
                width: 70,
                child: Text('You',
                    style: TextStyle(
                        color: result.gradeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: yourPct,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor:
                    AlwaysStoppedAnimation<Color>(result.gradeColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${result.percentage.toInt()}%',
                  style: TextStyle(
                      color: result.gradeColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          // Class avg bar
          Row(
            children: [
              SizedBox(
                width: 70,
                child: Text('Class',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: avgPct,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF6C63FF).withOpacity(0.6)),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text('${avgPct * 100 ~/ 1}%',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 70),
              Icon(
                result.aboveAverage
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: result.aboveAverage
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFFFF6584),
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                result.aboveAverage
                    ? '${(result.percentage - (result.classAverage / result.totalMarks * 100)).toStringAsFixed(1)}% above class average'
                    : '${((result.classAverage / result.totalMarks * 100) - result.percentage).toStringAsFixed(1)}% below class average',
                style: TextStyle(
                  color: result.aboveAverage
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFFFF6584),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Background Painter ───────────────────────────────────────────────────────

class _MarkssBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF00D4AA).withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.1), 170, p);
    p.color = const Color(0xFFFFB347).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.55), 130, p);
    p.color = const Color(0xFF6C63FF).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.82), 110, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}