import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../auth/api_service.dart';

// ─── MODELS ──────────────────────────────────────────────────────────────────

class StudentMark {
  final int id;
  final String name;
  final String username;
  final String avatar;
  int marks;
  final int totalMarks;
  final String examType;
  bool isEdited;

  StudentMark({
    required this.id,
    required this.name,
    required this.username,
    required this.avatar,
    required this.marks,
    required this.totalMarks,
    required this.examType,
    this.isEdited = false,
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
    if (percentage >= 80) return const Color(0xFF00D4AA);
    if (percentage >= 60) return const Color(0xFFFFB347);
    if (percentage >= 50) return const Color(0xFF6C63FF);
    return const Color(0xFFFF6584);
  }

  // initials from name
  String get initials => name
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0] : '')
      .take(2)
      .join()
      .toUpperCase();
}

class SubjectInfo {
  final int id;
  final String name;
  final String icon;
  final Color color;
  final int totalMarks;
  final int studentCount;
  final double average;
  final int? classId;

  SubjectInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.totalMarks,
    required this.studentCount,
    required this.average,
    this.classId,
  });
}

// ─── COLOR / ICON HELPERS ─────────────────────────────────────────────────────

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
// ───────────────────────────���─────────────────────────────────────────────────

class TeacherMarksScreen extends StatefulWidget {
  const TeacherMarksScreen({super.key});

  @override
  State<TeacherMarksScreen> createState() => _TeacherMarksScreenState();
}

class _TeacherMarksScreenState extends State<TeacherMarksScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late Animation<double> _headerAnim;

  List<SubjectInfo> _subjects = [];
  SubjectInfo? _selectedSubject;
  List<StudentMark> _students = [];
  String _searchQuery = '';
  String _sortBy = 'Name';
  bool _isLoadingSubjects = true;
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _headerAnim =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerCtrl.forward();
    Future.delayed(
        const Duration(milliseconds: 300), () => _listCtrl.forward());
    _fetchSubjects();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  // ── API Calls ───────────────────────────────────────────────────────────────

  Future<void> _fetchSubjects() async {
    setState(() => _isLoadingSubjects = true);
    try {
      final res = await MarksApi.getSubjects();
      if (res['success'] == true && mounted) {
        final List raw = res['subjects'] ?? [];
        setState(() {
          _subjects = List.generate(raw.length, (i) {
            final s = raw[i];
            return SubjectInfo(
              id:           s['id'] as int,
              name:         s['name'] ?? '',
              icon:         s['icon'] ?? '📚',
              color:        _colorFromHex(s['color'], i),
              totalMarks:   s['total_marks'] as int? ?? 100,
              studentCount: s['student_count'] as int? ?? 0,
              average:      (s['average'] as num?)?.toDouble() ?? 0.0,
              classId:      s['class_id'] as int?,
            );
          });
          _isLoadingSubjects = false;
        });
        _listCtrl.forward();
      } else {
        if (mounted) setState(() => _isLoadingSubjects = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSubjects = false);
    }
  }

  Future<void> _fetchStudents(SubjectInfo subject) async {
    setState(() {
      _isLoadingStudents = true;
      _students = [];
    });
    try {
      final res = await MarksApi.getStudentsWithMarks(subject.id);
      if (res['success'] == true && mounted) {
        final List raw = res['students'] ?? [];
        setState(() {
          _students = raw.map((s) {
            final name = s['name'] ?? '';
            final initials = name
                .split(' ')
                .map<String>((w) => w.isNotEmpty ? w[0] : '')
                .take(2)
                .join()
                .toUpperCase();
            return StudentMark(
              id:         s['id'] as int,
              name:       name,
              username:   s['username'] ?? '',
              avatar:     initials.isEmpty ? '?' : initials,
              marks:      s['marks_obtained'] as int? ?? 0,
              totalMarks: res['totalMarks'] as int? ?? subject.totalMarks,
              examType:   s['exam_type'] ?? 'Unit Test',
            );
          }).toList();
          _isLoadingStudents = false;
        });
        _listCtrl
          ..reset()
          ..forward();
      } else {
        if (mounted) setState(() => _isLoadingStudents = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _saveMarks(StudentMark student, int newMark,
      SubjectInfo subject) async {
    final res = await MarksApi.updateMark(
      studentId: student.id,
      subjectId: subject.id,
      marks:     newMark,
      examType:  student.examType,
    );
    if (res['success'] == true && mounted) {
      setState(() {
        student.marks    = newMark;
        student.isEdited = true;
      });
      _showSnack('✓ ${student.name}\'s marks updated to $newMark',
          const Color(0xFF00D4AA));
    } else if (mounted) {
      _showSnack(res['message'] ?? 'Update failed', const Color(0xFFFF6584));
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _selectSubject(SubjectInfo subject) {
    HapticFeedback.lightImpact();
    setState(() => _selectedSubject = subject);
    _fetchStudents(subject);
  }

  List<StudentMark> get _filteredStudents {
    var list = _students.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.username.toLowerCase().contains(q);
    }).toList();

    switch (_sortBy) {
      case 'Marks ↑':
        list.sort((a, b) => a.marks.compareTo(b.marks));
        break;
      case 'Marks ↓':
        list.sort((a, b) => b.marks.compareTo(a.marks));
        break;
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          CustomPaint(painter: _BgPainter(), size: Size.infinite),
          SafeArea(
            child: _selectedSubject == null
                ? _buildSubjectGrid()
                : _buildStudentListView(),
          ),
        ],
      ),
    );
  }

  // ── Subject Grid ─────────────────────────────────────────────────────────────

  Widget _buildSubjectGrid() {
    return FadeTransition(
      opacity: _headerAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(showBack: false),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFFF6584)])
                      .createShader(b),
                  child: const Text('Marks Manager',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8)),
                ),
                const SizedBox(height: 4),
                Text('Select subject to view & manage marks',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildOverallStats(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('SUBJECTS',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                const Spacer(),
                // ── Create Subject Button ──
                GestureDetector(
                  onTap: _showCreateSubjectSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFFB347), Color(0xFFFF6584)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('New Subject',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingSubjects
                ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFFFB347)))
                : _subjects.isEmpty
                ? _buildEmptySubjects()
                : GridView.builder(
              padding:
              const EdgeInsets.fromLTRB(20, 0, 20, 30),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:  2,
                crossAxisSpacing: 14,
                mainAxisSpacing:  14,
                childAspectRatio: 1.05,
              ),
              itemCount: _subjects.length,
              itemBuilder: (context, i) {
                final delay = i * 0.1;
                return AnimatedBuilder(
                  animation: _listCtrl,
                  builder: (context, child) {
                    final v = math.max(
                        0.0,
                        math.min(
                            1.0,
                            (_listCtrl.value - delay) /
                                (1.0 - delay)));
                    final curve = Curves.easeOutBack
                        .transform(v.clamp(0.0, 1.0));
                    return Opacity(
                      opacity: v.clamp(0.0, 1.0),
                      child: Transform.scale(
                          scale: 0.85 + (0.15 * curve),
                          child: child),
                    );
                  },
                  child: _buildSubjectCard(_subjects[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySubjects() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📚', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('No subjects yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Tap "New Subject" to create one',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    final totalStudents = _subjects.isNotEmpty
        ? _subjects.map((s) => s.studentCount).reduce(math.max)
        : 0;
    final avgScore = _subjects.isEmpty
        ? 0.0
        : _subjects.map((s) => s.average).reduce((a, b) => a + b) /
        _subjects.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFFFFB347).withOpacity(0.15),
            const Color(0xFFFF6584).withOpacity(0.08)
          ]),
          borderRadius: BorderRadius.circular(20),
          border:
          Border.all(color: const Color(0xFFFFB347).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            _overallStat('${_subjects.length}', 'Subjects',
                const Color(0xFFFFB347)),
            _vDivider(),
            _overallStat('$totalStudents', 'Students',
                const Color(0xFFFF6584)),
            _vDivider(),
            _overallStat('${avgScore.toStringAsFixed(0)}%', 'Avg Score',
                const Color(0xFF00D4AA)),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: Colors.white.withOpacity(0.08));

  Widget _overallStat(String val, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(val,
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

  Widget _buildSubjectCard(SubjectInfo subject) {
    return GestureDetector(
      onTap: () => _selectSubject(subject),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: subject.color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: subject.color.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: subject.color.withOpacity(0.08)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: subject.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12)),
                        child: Center(
                            child: Text(subject.icon,
                                style: const TextStyle(fontSize: 22))),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: subject.color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('${subject.studentCount}',
                            style: TextStyle(
                                color: subject.color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(subject.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                      'Avg: ${subject.average > 0 ? subject.average.toStringAsFixed(1) : "—"}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: subject.totalMarks > 0
                          ? (subject.average / subject.totalMarks)
                          .clamp(0.0, 1.0)
                          : 0,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor:
                      AlwaysStoppedAnimation<Color>(subject.color),
                      minHeight: 4,
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

  // ── Student List ─────────────────────────────────────────────────────────────

  Widget _buildStudentListView() {
    final subject  = _selectedSubject!;
    final students = _filteredStudents;

    return Column(
      children: [
        _buildTopBar(showBack: true),
        _buildSubjectHeader(subject),
        _buildSearchAndSort(),
        if (_isLoadingStudents)
          Expanded(child: _buildLoadingShimmer())
        else if (students.isEmpty)
          Expanded(
            child: Center(
              child: Text('No students found',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 15)),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchStudents(subject),
              color: subject.color,
              backgroundColor: const Color(0xFF131929),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: students.length,
                itemBuilder: (context, i) {
                  return AnimatedBuilder(
                    animation: _listCtrl,
                    builder: (context, child) {
                      final delay = i * 0.05;
                      final v = math.max(
                          0.0,
                          math.min(
                              1.0,
                              (_listCtrl.value - delay) /
                                  (1.0 - delay)));
                      final curve =
                      Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
                      return Opacity(
                        opacity: v.clamp(0.0, 1.0),
                        child: Transform.translate(
                            offset: Offset(30 * (1 - curve), 0),
                            child: child),
                      );
                    },
                    child: _buildStudentCard(students[i], subject),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectHeader(SubjectInfo subject) {
    if (_students.isEmpty) return const SizedBox.shrink();
    final avg = _students.map((s) => s.marks).reduce((a, b) => a + b) /
        _students.length;
    final highest = _students.map((s) => s.marks).reduce(math.max);
    final lowest  = _students.map((s) => s.marks).reduce(math.min);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          subject.color.withOpacity(0.15),
          subject.color.withOpacity(0.05)
        ]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: subject.color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(subject.icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
              Text('Total: ${subject.totalMarks} marks',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.45), fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _miniStat('Avg', avg.toStringAsFixed(1), subject.color),
              const SizedBox(height: 4),
              Row(children: [
                _miniStat('H', '$highest', const Color(0xFF00D4AA)),
                const SizedBox(width: 8),
                _miniStat('L', '$lowest', const Color(0xFFFF6584)),
              ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Row(children: [
      Text('$label: ',
          style: TextStyle(
              color: Colors.white.withOpacity(0.35), fontSize: 11)),
      Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w800, fontSize: 12)),
    ]);
  }

  Widget _buildSearchAndSort() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.white.withOpacity(0.08))),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search student...',
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.25), fontSize: 14),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.white.withOpacity(0.3), size: 18),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.white.withOpacity(0.08))),
              child: Row(children: [
                Icon(Icons.sort,
                    color: Colors.white.withOpacity(0.5), size: 18),
                const SizedBox(width: 6),
                Text(_sortBy,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentMark student, SubjectInfo subject) {
    return GestureDetector(
      onTap: () => _showEditMarksSheet(student, subject),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: student.isEdited
              ? subject.color.withOpacity(0.08)
              : const Color(0xFF131929),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: student.isEdited
                ? subject.color.withOpacity(0.4)
                : Colors.white.withOpacity(0.06),
            width: student.isEdited ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: subject.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(student.avatar,
                    style: TextStyle(
                        color: subject.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(student.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (student.isEdited) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: subject.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('Edited',
                            style: TextStyle(
                                color: subject.color,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ]),
                  Text(student.username,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '${student.marks}',
                      style: TextStyle(
                          color: student.gradeColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                    TextSpan(
                      text: '/${student.totalMarks}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 12),
                    ),
                  ]),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: student.gradeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: student.gradeColor.withOpacity(0.3))),
                  child: Text(student.grade,
                      style: TextStyle(
                          color: student.gradeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Icon(Icons.edit_outlined,
                color: Colors.white.withOpacity(0.2), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      itemCount: 8,
      itemBuilder: (_, __) => _ShimmerCard(),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar({required bool showBack}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (showBack) {
                setState(() {
                  _selectedSubject = null;
                  _students        = [];
                  _searchQuery     = '';
                  _listCtrl.reset();
                  _listCtrl.forward();
                });
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.1))),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const Spacer(),
          if (showBack && _selectedSubject != null)
            GestureDetector(
              onTap: () => _fetchStudents(_selectedSubject!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1))),
                child: Row(children: [
                  Icon(Icons.refresh,
                      color: Colors.white.withOpacity(0.6), size: 16),
                  const SizedBox(width: 6),
                  Text('Refresh',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  // ── Edit Marks Sheet ─────────────────────────────────────────────────────────

  void _showEditMarksSheet(StudentMark student, SubjectInfo subject) {
    HapticFeedback.lightImpact();
    final controller =
    TextEditingController(text: '${student.marks}');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: Color(0xFF131929),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: subject.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(
                        child: Text(student.avatar,
                            style: TextStyle(
                                color: subject.color,
                                fontWeight: FontWeight.w900,
                                fontSize: 16))),
                  ),
                  const SizedBox(width: 14),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        Text(
                            '${student.username}  •  ${subject.name}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13)),
                      ]),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Current Marks',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13)),
                      Text(
                          '${student.marks} / ${student.totalMarks}',
                          style: TextStyle(
                              color: student.gradeColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Enter marks',
                    hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 24),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide:
                        BorderSide(color: subject.color, width: 2)),
                    suffix: Text('/ ${student.totalMarks}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 16)),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14)),
                        child: const Center(
                            child: Text('Cancel',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: isSaving
                          ? null
                          : () async {
                        final newMark = int.tryParse(
                            controller.text.trim()) ??
                            student.marks;
                        if (newMark < 0 ||
                            newMark > student.totalMarks) {
                          _showSnack(
                              'Marks must be 0 – ${student.totalMarks}',
                              const Color(0xFFFF6584));
                          return;
                        }
                        setSheetState(() => isSaving = true);
                        Navigator.pop(ctx);
                        await _saveMarks(
                            student, newMark, subject);
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            subject.color,
                            subject.color.withOpacity(0.7)
                          ]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: subject.color.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: Center(
                          child: isSaving
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                              : const Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save_outlined,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Save Changes',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Create Subject Sheet ─────────────────────────────────────────────────────

  void _showCreateSubjectSheet() {
    final nameCtrl   = TextEditingController();
    final marksCtrl  = TextEditingController(text: '100');
    String icon      = '📚';
    bool   isSaving  = false;

    final icons = ['📚', '📐', '🔬', '📖', '🌍', '💻', '✍️', '🎨', '🏃', '🎵'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: Color(0xFF131929),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFFF6584)])
                      .createShader(b),
                  child: const Text('New Subject',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ),
                const SizedBox(height: 20),
                // Name field
                _glowField(nameCtrl, 'Subject Name', Icons.subject),
                const SizedBox(height: 12),
                // Total marks
                _glowField(marksCtrl, 'Total Marks', Icons.star_outline,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                // Icon picker
                Text('ICON',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: icons.map((ic) {
                    final sel = ic == icon;
                    return GestureDetector(
                      onTap: () => setSheet(() => icon = ic),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: sel
                              ? const Color(0xFFFFB347).withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel
                                  ? const Color(0xFFFFB347)
                                  : Colors.transparent),
                        ),
                        child: Center(
                            child: Text(ic,
                                style: const TextStyle(fontSize: 22))),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Save button
                GestureDetector(
                  onTap: isSaving
                      ? null
                      : () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      _showSnack('Subject name required!',
                          const Color(0xFFFF6584));
                      return;
                    }
                    setSheet(() => isSaving = true);
                    final res = await MarksApi.createSubject(
                      name:       nameCtrl.text.trim(),
                      icon:       icon,
                      totalMarks: int.tryParse(
                          marksCtrl.text.trim()) ??
                          100,
                    );
                    if (res['success'] == true) {
                      Navigator.pop(ctx);
                      _showSnack('Subject created! ✅',
                          const Color(0xFF00D4AA));
                      _fetchSubjects();
                    } else {
                      setSheet(() => isSaving = false);
                      _showSnack(
                          res['message'] ?? 'Failed',
                          const Color(0xFFFF6584));
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFFB347),
                        Color(0xFFFF6584)
                      ]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: isSaving
                          ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Create Subject',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glowField(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(children: [
        Icon(icon, color: Colors.white.withOpacity(0.4), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.3)),
                border: InputBorder.none),
          ),
        ),
      ]),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
            color: Color(0xFF131929),
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ...['Name', 'Marks ↑', 'Marks ↓'].map((opt) =>
                GestureDetector(
                  onTap: () {
                    setState(() => _sortBy = opt);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                        color: _sortBy == opt
                            ? const Color(0xFFFFB347).withOpacity(0.12)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _sortBy == opt
                                ? const Color(0xFFFFB347).withOpacity(0.4)
                                : Colors.white.withOpacity(0.06))),
                    child: Row(children: [
                      Text(opt,
                          style: TextStyle(
                              color: _sortBy == opt
                                  ? const Color(0xFFFFB347)
                                  : Colors.white70,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      if (_sortBy == opt)
                        const Icon(Icons.check,
                            color: Color(0xFFFFB347), size: 18),
                    ]),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Shimmer Card ─────────────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.04),
              Colors.white.withOpacity(0.08),
              Colors.white.withOpacity(0.04),
            ],
            stops: [0.0, _anim.value, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ─── Background Painter ───────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFFFFB347).withOpacity(0.05);
    canvas.drawCircle(
        Offset(size.width * 0.9, size.height * 0.1), 160, p);
    p.color = const Color(0xFFFF6584).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.5), 130, p);
    p.color = const Color(0xFF6C63FF).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.85), 110, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}