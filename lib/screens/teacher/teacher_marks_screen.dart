import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ─── PACKAGES NEEDED (pubspec.yaml mein add karo) ────────────────────────────
// file_picker: ^6.1.1
// excel: ^4.0.2          ← Excel/CSV parsing
// http: ^1.2.0           ← API calls
// dio: ^5.4.0            ← File upload (multipart)
// flutter_animate: ^4.5.0
// ─────────────────────────────────────────────────────────────────────────────

// ─── TODO: API ENDPOINTS (Node.js + MySQL) ───────────────────────────────────
// const String BASE_URL = 'https://your-server.com/api';
// GET    $BASE_URL/marks/subjects          → List of subjects
// GET    $BASE_URL/marks/students?subject= → Students with marks
// GET    $BASE_URL/marks/template          → Download CSV template
// POST   $BASE_URL/marks/upload            → Upload CSV/Excel (multipart)
// PUT    $BASE_URL/marks/update            → Single student mark update
// ─────────────────────────────────────────────────────────────────────────────

// ─── MODELS ──────────────────────────────────────────────────────────────────

class StudentMark {
  final String id;
  final String name;
  final String rollNo;
  final String avatar;
  int marks;
  final int totalMarks;
  bool isEdited;

  StudentMark({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.avatar,
    required this.marks,
    required this.totalMarks,
    this.isEdited = false,
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
    if (percentage >= 80) return const Color(0xFF00D4AA);
    if (percentage >= 60) return const Color(0xFFFFB347);
    if (percentage >= 50) return const Color(0xFF6C63FF);
    return const Color(0xFFFF6584);
  }
}

class SubjectInfo {
  final String name;
  final String icon;
  final Color color;
  final int totalMarks;
  final int studentCount;
  final double average;

  SubjectInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.totalMarks,
    required this.studentCount,
    required this.average,
  });
}

// ─── MOCK DATA ────────────────────────────────────────────────────────────────

final List<SubjectInfo> _mockSubjects = [
  SubjectInfo(name: 'Mathematics', icon: '📐', color: const Color(0xFF6C63FF), totalMarks: 100, studentCount: 32, average: 74.5),
  SubjectInfo(name: 'Science', icon: '🔬', color: const Color(0xFF00D4AA), totalMarks: 100, studentCount: 32, average: 68.2),
  SubjectInfo(name: 'English', icon: '📖', color: const Color(0xFFFF6584), totalMarks: 80, studentCount: 32, average: 61.8),
  SubjectInfo(name: 'History', icon: '🌍', color: const Color(0xFFFFB347), totalMarks: 50, studentCount: 32, average: 38.4),
  SubjectInfo(name: 'Computer', icon: '💻', color: const Color(0xFF00D4FF), totalMarks: 100, studentCount: 32, average: 82.1),
  SubjectInfo(name: 'Hindi', icon: '✍️', color: const Color(0xFFFF8C42), totalMarks: 100, studentCount: 32, average: 71.3),
];

List<StudentMark> _getMockStudents(SubjectInfo subject) {
  final names = [
    ('Rahul Sharma', 'RS'), ('Priya Patel', 'PP'), ('Amit Kumar', 'AK'),
    ('Sneha Gupta', 'SG'), ('Rohan Mehta', 'RM'), ('Kavya Singh', 'KS'),
    ('Arjun Verma', 'AV'), ('Pooja Yadav', 'PY'), ('Varun Joshi', 'VJ'),
    ('Ananya Das', 'AD'), ('Karan Malhotra', 'KM'), ('Riya Chopra', 'RC'),
    ('Nikhil Sharma', 'NS'), ('Divya Nair', 'DN'), ('Saurav Tiwari', 'ST'),
    ('Mansi Agarwal', 'MA'), ('Deepak Raj', 'DR'), ('Tanya Khanna', 'TK'),
  ];

  final rng = math.Random(subject.name.length);
  return List.generate(names.length, (i) {
    final mark = (rng.nextInt(subject.totalMarks - 10) + 10);
    return StudentMark(
      id: '${i + 1}'.padLeft(3, '0'),
      name: names[i].$1,
      rollNo: 'R${(i + 1).toString().padLeft(2, '0')}',
      avatar: names[i].$2,
      marks: mark,
      totalMarks: subject.totalMarks,
    );
  });
}

// ─── CSV PREVIEW MODEL ────────────────────────────────────────────────────────

class CsvPreviewRow {
  final String rollNo;
  final String name;
  final int marks;
  final int totalMarks;
  bool hasError;
  String? errorMsg;

  CsvPreviewRow({
    required this.rollNo,
    required this.name,
    required this.marks,
    required this.totalMarks,
    this.hasError = false,
    this.errorMsg,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

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

  SubjectInfo? _selectedSubject;
  List<StudentMark> _students = [];
  String _searchQuery = '';
  String _sortBy = 'Roll No';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _listCtrl.forward());
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  void _selectSubject(SubjectInfo subject) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedSubject = subject;
      _isLoading = true;
      _students = [];
    });

    // TODO: Replace with API call
    // final res = await http.get(Uri.parse('$BASE_URL/marks/students?subject=${subject.name}'));
    // _students = (jsonDecode(res.body)['data'] as List).map((e) => StudentMark.fromJson(e)).toList();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _students = _getMockStudents(subject);
          _isLoading = false;
        });
        _listCtrl
          ..reset()
          ..forward();
      }
    });
  }

  List<StudentMark> get _filteredStudents {
    var list = _students.where((s) {
      final q = _searchQuery.toLowerCase();
      return s.name.toLowerCase().contains(q) || s.rollNo.toLowerCase().contains(q);
    }).toList();

    switch (_sortBy) {
      case 'Marks ↑':
        list.sort((a, b) => a.marks.compareTo(b.marks));
        break;
      case 'Marks ↓':
        list.sort((a, b) => b.marks.compareTo(a.marks));
        break;
      case 'Name':
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        list.sort((a, b) => a.rollNo.compareTo(b.rollNo));
    }
    return list;
  }

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

  // ── Subject Selection Screen ────────────────────────────────────────────────

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
                    colors: [Color(0xFFFFB347), Color(0xFFFF6584)],
                  ).createShader(b),
                  child: const Text('Marks Manager',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8)),
                ),
                const SizedBox(height: 4),
                Text('Select subject to view & manage marks',
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildOverallStats(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('SUBJECTS',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
              itemCount: _mockSubjects.length,
              itemBuilder: (context, i) {
                final delay = i * 0.1;
                return AnimatedBuilder(
                  animation: _listCtrl,
                  builder: (context, child) {
                    final v = math.max(0.0, math.min(1.0, (_listCtrl.value - delay) / (1.0 - delay)));
                    final curve = Curves.easeOutBack.transform(v.clamp(0.0, 1.0));
                    return Opacity(
                      opacity: v.clamp(0.0, 1.0),
                      child: Transform.scale(scale: 0.85 + (0.15 * curve), child: child),
                    );
                  },
                  child: _buildSubjectCard(_mockSubjects[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFFFB347).withOpacity(0.15), const Color(0xFFFF6584).withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.25)),
        ),
        child: Row(
          children: [
            _overallStat('6', 'Subjects', const Color(0xFFFFB347)),
            _vDivider(),
            _overallStat('32', 'Students', const Color(0xFFFF6584)),
            _vDivider(),
            _overallStat('71%', 'Avg Score', const Color(0xFF00D4AA)),
            _vDivider(),
            _overallStat('3', 'Pending', const Color(0xFF6C63FF)),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.08));

  Widget _overallStat(String val, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w600)),
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
          boxShadow: [BoxShadow(color: subject.color.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Stack(
          children: [
            // Glow circle background
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: subject.color.withOpacity(0.08),
                ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(subject.icon, style: const TextStyle(fontSize: 22))),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: subject.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${subject.studentCount}',
                            style: TextStyle(color: subject.color, fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(subject.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Avg: ${subject.average.toStringAsFixed(1)}%',
                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: subject.average / 100,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(subject.color),
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

  // ── Student List Screen ─────────────────────────────────────────────────────

  Widget _buildStudentListView() {
    final subject = _selectedSubject!;
    final students = _filteredStudents;

    return Column(
      children: [
        _buildTopBar(showBack: true),
        _buildSubjectHeader(subject),
        _buildSearchAndSort(),
        if (_isLoading)
          Expanded(child: _buildLoadingShimmer())
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: students.length,
              itemBuilder: (context, i) {
                return AnimatedBuilder(
                  animation: _listCtrl,
                  builder: (context, child) {
                    final delay = i * 0.05;
                    final v = math.max(0.0, math.min(1.0, (_listCtrl.value - delay) / (1.0 - delay)));
                    final curve = Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
                    return Opacity(
                      opacity: v.clamp(0.0, 1.0),
                      child: Transform.translate(offset: Offset(30 * (1 - curve), 0), child: child),
                    );
                  },
                  child: _buildStudentCard(students[i], subject),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectHeader(SubjectInfo subject) {
    final students = _students;
    if (students.isEmpty) return const SizedBox.shrink();

    final avg = students.isEmpty ? 0.0 : students.map((s) => s.marks).reduce((a, b) => a + b) / students.length;
    final highest = students.isEmpty ? 0 : students.map((s) => s.marks).reduce(math.max);
    final lowest = students.isEmpty ? 0 : students.map((s) => s.marks).reduce(math.min);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [subject.color.withOpacity(0.15), subject.color.withOpacity(0.05)],
        ),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Text('Total: ${subject.totalMarks} marks',
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _miniStat('Avg', '${avg.toStringAsFixed(1)}', subject.color),
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
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    );
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
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search student...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3), size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Icon(Icons.sort, color: Colors.white.withOpacity(0.5), size: 18),
                  const SizedBox(width: 6),
                  Text(_sortBy, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Upload CSV button
          GestureDetector(
            onTap: () => _showUploadFlow(),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFB347), Color(0xFFFF6584)]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFB347).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text('CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: student.isEdited
              ? subject.color.withOpacity(0.08)
              : const Color(0xFF131929),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: student.isEdited ? subject.color.withOpacity(0.4) : Colors.white.withOpacity(0.06),
            width: student.isEdited ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: subject.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(student.avatar,
                    style: TextStyle(color: subject.color, fontWeight: FontWeight.w900, fontSize: 13)),
              ),
            ),
            const SizedBox(width: 12),
            // Name & Roll
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(student.name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      if (student.isEdited) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: subject.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('Edited',
                              style: TextStyle(color: subject.color, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  Text(student.rollNo,
                      style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
                ],
              ),
            ),
            // Marks + Grade
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${student.marks}',
                        style: TextStyle(
                          color: student.gradeColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextSpan(
                        text: '/${student.totalMarks}',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: student.gradeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: student.gradeColor.withOpacity(0.3)),
                  ),
                  child: Text(student.grade,
                      style: TextStyle(color: student.gradeColor, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Icon(Icons.edit_outlined, color: Colors.white.withOpacity(0.2), size: 18),
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

  // ── Top Bar ─────────────────────────────────────────────────────────────────

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
                  _students = [];
                  _searchQuery = '';
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
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Icon(
                showBack ? Icons.arrow_back_ios_new : Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const Spacer(),
          if (showBack && _selectedSubject != null) ...[
            // Download Template button
            GestureDetector(
              onTap: _downloadTemplate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.download_outlined, color: Colors.white.withOpacity(0.6), size: 16),
                    const SizedBox(width: 6),
                    Text('Template',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Edit Marks Bottom Sheet ──────────────────────────────────────────────────

  void _showEditMarksSheet(StudentMark student, SubjectInfo subject) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: '${student.marks}');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF131929),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: subject.color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(student.avatar,
                        style: TextStyle(color: subject.color, fontWeight: FontWeight.w900, fontSize: 16))),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      Text('${student.rollNo}  •  ${subject.name}',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Current marks display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Marks', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                    Text('${student.marks} / ${student.totalMarks}',
                        style: TextStyle(color: student.gradeColor, fontWeight: FontWeight.w800, fontSize: 15)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // New marks input
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Enter marks',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: subject.color, width: 2),
                  ),
                  suffix: Text('/ ${student.totalMarks}',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(child: Text('Cancel',
                            style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        final newMark = int.tryParse(controller.text.trim()) ?? student.marks;
                        if (newMark < 0 || newMark > student.totalMarks) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: const Color(0xFFFF6584),
                            content: Text('Marks must be 0 – ${student.totalMarks}'),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ));
                          return;
                        }

                        // TODO: API call
                        // await http.put(Uri.parse('$BASE_URL/marks/update'),
                        //   body: jsonEncode({'studentId': student.id, 'subject': subject.name, 'marks': newMark}));

                        setState(() {
                          student.marks = newMark;
                          student.isEdited = true;
                        });
                        Navigator.pop(context);
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          backgroundColor: const Color(0xFF00D4AA),
                          content: Text('✓ ${student.name}\'s marks updated to $newMark'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ));
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [subject.color, subject.color.withOpacity(0.7)]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: subject.color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CSV Upload Flow ──────────────────────────────────────────────────────────

  void _showUploadFlow() {
    HapticFeedback.mediumImpact();
    // TODO: Replace with actual file_picker
    // FilePickerResult? result = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['csv', 'xlsx'],
    // );

    // Simulating picked file → show preview
    final mockCsvData = [
      CsvPreviewRow(rollNo: 'R01', name: 'Rahul Sharma', marks: 88, totalMarks: 100),
      CsvPreviewRow(rollNo: 'R02', name: 'Priya Patel', marks: 95, totalMarks: 100),
      CsvPreviewRow(rollNo: 'R03', name: 'Amit Kumar', marks: 105, totalMarks: 100,
          hasError: true, errorMsg: 'Marks exceed total (100)'),
      CsvPreviewRow(rollNo: 'R04', name: 'Sneha Gupta', marks: 72, totalMarks: 100),
      CsvPreviewRow(rollNo: 'R05', name: 'Rohan Mehta', marks: -5, totalMarks: 100,
          hasError: true, errorMsg: 'Negative marks not allowed'),
      CsvPreviewRow(rollNo: 'R06', name: 'Kavya Singh', marks: 81, totalMarks: 100),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _CsvPreviewSheet(
        data: mockCsvData,
        subject: _selectedSubject!,
        onConfirm: (validRows) {
          // TODO: Upload to server
          // var request = http.MultipartRequest('POST', Uri.parse('$BASE_URL/marks/upload'));
          // request.files.add(await http.MultipartFile.fromPath('file', result.files.single.path!));
          // var res = await request.send();

          setState(() {
            for (final row in validRows) {
              final match = _students.where((s) => s.rollNo == row.rollNo);
              if (match.isNotEmpty) {
                match.first.marks = row.marks;
                match.first.isEdited = true;
              }
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: const Color(0xFF00D4AA),
            content: Text('✓ ${validRows.length} students\' marks updated!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        },
      ),
    );
  }

  void _downloadTemplate() {
    HapticFeedback.lightImpact();
    // TODO: Download CSV template from server
    // final url = '$BASE_URL/marks/template?subject=${_selectedSubject!.name}';
    // Launch URL or save file

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xFF6C63FF),
      content: const Text('📥 Template download started...'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF131929),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ...['Roll No', 'Name', 'Marks ↑', 'Marks ↓'].map((opt) => GestureDetector(
              onTap: () {
                setState(() => _sortBy = opt);
                Navigator.pop(context);
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _sortBy == opt
                      ? const Color(0xFFFFB347).withOpacity(0.12)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _sortBy == opt
                        ? const Color(0xFFFFB347).withOpacity(0.4)
                        : Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Text(opt,
                        style: TextStyle(
                            color: _sortBy == opt ? const Color(0xFFFFB347) : Colors.white70,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (_sortBy == opt)
                      const Icon(Icons.check, color: Color(0xFFFFB347), size: 18),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CSV PREVIEW SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _CsvPreviewSheet extends StatefulWidget {
  final List<CsvPreviewRow> data;
  final SubjectInfo subject;
  final Function(List<CsvPreviewRow>) onConfirm;

  const _CsvPreviewSheet({required this.data, required this.subject, required this.onConfirm});

  @override
  State<_CsvPreviewSheet> createState() => _CsvPreviewSheetState();
}

class _CsvPreviewSheetState extends State<_CsvPreviewSheet> {
  bool _isUploading = false;

  List<CsvPreviewRow> get _validRows => widget.data.where((r) => !r.hasError).toList();
  List<CsvPreviewRow> get _errorRows => widget.data.where((r) => r.hasError).toList();

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Preview Upload',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      Text('${subject.name} • ${widget.data.length} rows found',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                    ],
                  ),
                  const Spacer(),
                  // Stats chips
                  _chip('${_validRows.length} OK', const Color(0xFF00D4AA)),
                  const SizedBox(width: 8),
                  _chip('${_errorRows.length} Errors', const Color(0xFFFF6584)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Column headers
            _tableHeader(),
            // Data rows
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: widget.data.length,
                itemBuilder: (context, i) => _tableRow(widget.data[i], subject),
              ),
            ),
            // Bottom confirm bar
            _buildConfirmBar(subject),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  Widget _tableHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text('Roll No', style: _headerStyle)),
          Expanded(child: Text('Name', style: _headerStyle)),
          SizedBox(width: 70, child: Text('Marks', style: _headerStyle, textAlign: TextAlign.center)),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  TextStyle get _headerStyle =>
      TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8);

  Widget _tableRow(CsvPreviewRow row, SubjectInfo subject) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: row.hasError ? const Color(0xFFFF6584).withOpacity(0.07) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: row.hasError ? const Color(0xFFFF6584).withOpacity(0.25) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 56,
                child: Text(row.rollNo,
                    style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Text(row.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                width: 70,
                child: Text('${row.marks}/${row.totalMarks}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: row.hasError ? const Color(0xFFFF6584) : const Color(0xFF00D4AA),
                        fontWeight: FontWeight.w900,
                        fontSize: 13)),
              ),
              SizedBox(
                width: 28,
                child: Icon(
                  row.hasError ? Icons.error_outline : Icons.check_circle_outline,
                  color: row.hasError ? const Color(0xFFFF6584) : const Color(0xFF00D4AA),
                  size: 18,
                ),
              ),
            ],
          ),
          if (row.hasError && row.errorMsg != null) ...[
            const SizedBox(height: 4),
            Text('⚠ ${row.errorMsg}',
                style: const TextStyle(color: Color(0xFFFF6584), fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _buildConfirmBar(SubjectInfo subject) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1623),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          if (_errorRows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFB347).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFFFB347), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_errorRows.length} rows have errors and will be skipped. ${_validRows.length} valid rows will be uploaded.',
                        style: const TextStyle(color: Color(0xFFFFB347), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(child: Text('Cancel',
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w700))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _validRows.isEmpty ? null : () async {
                    setState(() => _isUploading = true);
                    HapticFeedback.mediumImpact();

                    // Simulate upload delay
                    await Future.delayed(const Duration(seconds: 2));

                    // TODO: Actual Dio multipart upload
                    // var dio = Dio();
                    // FormData formData = FormData.fromMap({
                    //   'file': await MultipartFile.fromFile(filePath, filename: 'marks.csv'),
                    //   'subject': subject.name,
                    // });
                    // await dio.post('$BASE_URL/marks/upload', data: formData);

                    widget.onConfirm(_validRows);
                    if (mounted) Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: _validRows.isEmpty
                          ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                          : const LinearGradient(colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: _validRows.isEmpty ? [] : [
                        BoxShadow(color: const Color(0xFF00D4AA).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Center(
                      child: _isUploading
                          ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text('Upload ${_validRows.length} Rows',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shimmer Loading Card ─────────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
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
      builder: (context, _) => Container(
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
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 160, p);
    p.color = const Color(0xFFFF6584).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.5), 130, p);
    p.color = const Color(0xFF6C63FF).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.85), 110, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}