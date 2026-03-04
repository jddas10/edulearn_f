import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../auth/api_service.dart';

// ─── MODEL ────────────────────────────────────────────────────────────────────

class _SubjectResult {
  final int    subjectId;
  final String name;
  final String icon;
  final Color  color;
  final int    marks;
  final int    totalMarks;
  final double classAverage;
  final String examType;

  const _SubjectResult({
    required this.subjectId,
    required this.name,
    required this.icon,
    required this.color,
    required this.marks,
    required this.totalMarks,
    required this.classAverage,
    required this.examType,
  });

  double get percentage => totalMarks > 0 ? (marks / totalMarks) * 100 : 0;

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

// ─── COLOR HELPER ─────────────────────────────────────────────────────────────

const _kColors = [
  Color(0xFF6C63FF), Color(0xFF00D4AA), Color(0xFFFF6584),
  Color(0xFFFFB347), Color(0xFF00D4FF), Color(0xFFFF8C42),
];

Color _colorFromHex(String? hex, int index) {
  if (hex != null && hex.startsWith('#') && hex.length == 7) {
    try {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    } catch (_) {}
  }
  return _kColors[index % _kColors.length];
}

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
  late Animation<double>   _headerAnim;
  late Animation<double>   _scoreAnim;

  List<_SubjectResult> _results = [];
  bool _isLoading = true;

  // ── Computed stats ──────────────────────────────────────────────────────────
  int    get _totalObtained => _results.fold(0, (s, r) => s + r.marks);
  int    get _totalMax      => _results.fold(0, (s, r) => s + r.totalMarks);
  double get _overallPct    => _totalMax > 0 ? (_totalObtained / _totalMax) * 100 : 0;

  String get _overallGrade {
    if (_overallPct >= 90) return 'A+';
    if (_overallPct >= 80) return 'A';
    if (_overallPct >= 70) return 'B+';
    if (_overallPct >= 60) return 'B';
    return 'C';
  }

  Color get _overallGradeColor {
    if (_overallPct >= 90) return const Color(0xFF00D4AA);
    if (_overallPct >= 80) return const Color(0xFF6C63FF);
    if (_overallPct >= 70) return const Color(0xFF00D4FF);
    if (_overallPct >= 60) return const Color(0xFFFFB347);
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
    _fetchMarks();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    _scoreCtrl.dispose();
    super.dispose();
  }

  // ── API ─────────────────────────────────────────────────────────────────────

  Future<void> _fetchMarks() async {
    setState(() => _isLoading = true);
    try {
      final res = await MarksApi.getMyMarks();
      if (res['success'] == true && mounted) {
        final List raw = res['marks'] ?? [];
        setState(() {
          _results = List.generate(raw.length, (i) {
            final m = raw[i];
            return _SubjectResult(
              subjectId:    m['subject_id'] as int,
              name:         m['name'] ?? '',
              icon:         m['icon'] ?? '📚',
              color:        _colorFromHex(m['color'], i),
              marks:        m['marks_obtained'] as int? ?? 0,
              totalMarks:   m['total_marks'] as int? ?? 100,
              classAverage: (m['class_average'] as num?)?.toDouble() ?? 0.0,
              examType:     m['exam_type'] ?? 'Unit Test',
            );
          });
          _isLoading = false;
        });
        Future.delayed(
            const Duration(milliseconds: 200), () => _scoreCtrl.forward());
        Future.delayed(
            const Duration(milliseconds: 400), () => _listCtrl.forward());
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

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
                    child: _isLoading
                        ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF00D4AA)))
                        : _results.isEmpty
                        ? _buildEmpty()
                        : _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('No marks yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Your teacher hasn\'t added marks yet',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _fetchMarks,
      color: const Color(0xFF00D4AA),
      backgroundColor: const Color(0xFF131929),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
        children: [
          _buildOverallScoreCard(),
          const SizedBox(height: 16),
          _buildSectionTitle('Subject-wise Results'),
          _buildSubjectCards(),
          _buildSectionTitle('Performance Insights'),
          _buildInsightsRow(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

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
                  Border.all(color: Colors.white.withOpacity(0.1))),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFFFFB347)])
                      .createShader(b),
                  child: const Text('My Results',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.6)),
                ),
                Text('Your academic performance',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchMarks,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF00D4AA).withOpacity(0.25)),
              ),
              child: const Row(children: [
                Icon(Icons.refresh, color: Color(0xFF00D4AA), size: 16),
                SizedBox(width: 5),
                Text('Refresh',
                    style: TextStyle(
                        color: Color(0xFF00D4AA),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Overall Score Card ───────────────────────────────────────────────────────

  Widget _buildOverallScoreCard() {
    return AnimatedBuilder(
      animation: _scoreAnim,
      builder: (ctx, _) {
        final displayPct =
        (_overallPct * _scoreAnim.value).toStringAsFixed(1);
        final displayMarks =
        (_totalObtained * _scoreAnim.value).toInt();

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
            border: Border.all(
                color: _overallGradeColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                  color: _overallGradeColor.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 12))
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    _overallGradeColor,
                    _overallGradeColor.withOpacity(0.3)
                  ]),
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
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: _overallPct /
                                    100 *
                                    _scoreAnim.value,
                                strokeWidth: 7,
                                backgroundColor:
                                Colors.white.withOpacity(0.06),
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    _overallGradeColor),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(children: [
                              Text(_overallGrade,
                                  style: TextStyle(
                                      color: _overallGradeColor,
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1)),
                              Text('$displayPct%',
                                  style: TextStyle(
                                      color:
                                      Colors.white.withOpacity(0.5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ],
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text('Total Score',
                                  style: TextStyle(
                                      color:
                                      Colors.white.withOpacity(0.4),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: '$displayMarks',
                                    style: TextStyle(
                                        color: _overallGradeColor,
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -2),
                                  ),
                                  TextSpan(
                                    text: ' / $_totalMax',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.3),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ]),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _overallGradeColor
                                      .withOpacity(0.12),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _overallGradeColor
                                          .withOpacity(0.3)),
                                ),
                                child: Text(
                                  _overallPct >= 80
                                      ? '🌟 Excellent Work!'
                                      : _overallPct >= 60
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
                    Row(children: [
                      _miniStat('${_results.length}', 'Subjects',
                          const Color(0xFF6C63FF)),
                      _miniDivider(),
                      _miniStat(
                          '${_results.where((r) => r.aboveAverage).length}',
                          'Above Avg',
                          const Color(0xFF00D4AA)),
                      _miniDivider(),
                      _miniStat(
                          '${_results.where((r) => r.grade == 'A+' || r.grade == 'A').length}',
                          'A Grades',
                          const Color(0xFFFF8C42)),
                    ]),
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
      child: Column(children: [
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
      ]),
    );
  }

  Widget _miniDivider() =>
      Container(width: 1, height: 34, color: Colors.white.withOpacity(0.08));

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5)),
    );
  }

  // ── Subject Cards ─────────────────────────────────────────────────────────────

  Widget _buildSubjectCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: List.generate(_results.length, (i) {
          return AnimatedBuilder(
            animation: _listCtrl,
            builder: (ctx, child) {
              final delay = i * 0.12;
              final v = math.max(
                  0.0,
                  math.min(1.0,
                      (_listCtrl.value - delay) / (1.0 - delay)));
              final curve =
              Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
              return Opacity(
                opacity: curve,
                child: Transform.translate(
                    offset: Offset(0, 30 * (1 - curve)), child: child),
              );
            },
            child: _buildSubjectCard(_results[i]),
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: result.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                            child: Text(result.icon,
                                style: const TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 14),
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
                            Row(children: [
                              Icon(Icons.schedule_outlined,
                                  color:
                                  Colors.white.withOpacity(0.35),
                                  size: 11),
                              const SizedBox(width: 3),
                              Text(result.examType,
                                  style: TextStyle(
                                      color:
                                      Colors.white.withOpacity(0.4),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500)),
                            ]),
                          ],
                        ),
                      ),
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
                                    color:
                                    Colors.white.withOpacity(0.3),
                                    fontSize: 13),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                              result.gradeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: result.gradeColor
                                      .withOpacity(0.35)),
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
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    result.gradeColor),
                                minHeight: 5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(children: [
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
                                      color:
                                      Colors.white.withOpacity(0.2))),
                              const SizedBox(width: 8),
                              Text(result.gradeLabel,
                                  style: TextStyle(
                                      color:
                                      Colors.white.withOpacity(0.4),
                                      fontSize: 11)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
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

  // ── Insights Row ─────────────────────────────────────────────────────────────

  Widget _buildInsightsRow() {
    if (_results.isEmpty) return const SizedBox.shrink();
    final best   = _results.reduce((a, b) => a.percentage > b.percentage ? a : b);
    final lowest = _results.reduce((a, b) => a.percentage < b.percentage ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _InsightCard(
              label: 'Best Subject',
              value: best.name,
              sub:   '${best.marks}/${best.totalMarks}',
              icon:  best.icon,
              color: const Color(0xFF00D4AA),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _InsightCard(
              label: 'Needs Attention',
              value: lowest.name,
              sub:   '${lowest.marks}/${lowest.totalMarks}',
              icon:  lowest.icon,
              color: const Color(0xFFFF6584),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubjectDetail(_SubjectResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SubjectDetailSheet(result: result),
    );
  }
}

// ─── Avg Chip ──────────────────────────────────────────────────────────────��──

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
          size: 13),
    );
  }
}

// ─── Insight Card ─────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final String label, value, sub, icon;
  final Color  color;
  const _InsightCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    required this.color,
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
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const Spacer(),
            Icon(
              color == const Color(0xFF00D4AA)
                  ? Icons.emoji_events_outlined
                  : Icons.flag_outlined,
              color: color,
              size: 16,
            ),
          ]),
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

// ─── Subject Detail Sheet ─────────────────────────────────────────────────────

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
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                      color: result.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16)),
                  child: Center(
                      child: Text(result.icon,
                          style: const TextStyle(fontSize: 28))),
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
                      Text(result.examType,
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
            // Score display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  result.color.withOpacity(0.12),
                  result.gradeColor.withOpacity(0.06)
                ]),
                borderRadius: BorderRadius.circular(20),
                border:
                Border.all(color: result.color.withOpacity(0.2)),
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
                                  letterSpacing: -2),
                            ),
                            TextSpan(
                              text: ' / ${result.totalMarks}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 20),
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
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: result.percentage / 100,
                          strokeWidth: 7,
                          backgroundColor:
                          Colors.white.withOpacity(0.06),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              result.gradeColor),
                          strokeCap: StrokeCap.round,
                        ),
                        Text('${result.percentage.toInt()}%',
                            style: TextStyle(
                                color: result.gradeColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(children: [
              _detailStat('Class Avg',
                  result.classAverage.toStringAsFixed(1),
                  const Color(0xFF6C63FF)),
              const SizedBox(width: 10),
              _detailStat(
                  'Your Score', '${result.marks}', result.gradeColor),
              const SizedBox(width: 10),
              _detailStat(
                'Difference',
                '${result.marks > result.classAverage ? '+' : ''}${(result.marks - result.classAverage).toStringAsFixed(1)}',
                result.aboveAverage
                    ? const Color(0xFF00D4AA)
                    : const Color(0xFFFF6584),
              ),
            ]),
            const SizedBox(height: 16),
            // Comparison bar
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
        child: Column(children: [
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
        ]),
      ),
    );
  }

  Widget _buildComparisonBar() {
    final yourPct = result.percentage / 100;
    final avgPct  = result.totalMarks > 0
        ? (result.classAverage / result.totalMarks).clamp(0.0, 1.0)
        : 0.0;

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
          _barRow('You', yourPct, '${result.percentage.toInt()}%',
              result.gradeColor),
          const SizedBox(height: 8),
          _barRow(
              'Class',
              avgPct,
              '${(avgPct * 100).toInt()}%',
              const Color(0xFF6C63FF).withOpacity(0.6)),
          const SizedBox(height: 10),
          Row(children: [
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
            Flexible(
              child: Text(
                result.aboveAverage
                    ? '${(result.percentage - avgPct * 100).toStringAsFixed(1)}% above class average'
                    : '${(avgPct * 100 - result.percentage).toStringAsFixed(1)}% below class average',
                style: TextStyle(
                  color: result.aboveAverage
                      ? const Color(0xFF00D4AA)
                      : const Color(0xFFFF6584),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _barRow(
      String label, double value, String pctText, Color color) {
    return Row(children: [
      SizedBox(
        width: 70,
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(pctText,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800)),
    ]);
  }
}

// ─── Background Painter ───────────────────────────────────────────────────────

class _MarkssBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF00D4AA).withOpacity(0.05);
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.1), 170, p);
    p.color = const Color(0xFFFFB347).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.55), 130, p);
    p.color = const Color(0xFF6C63FF).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.82), 110, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}