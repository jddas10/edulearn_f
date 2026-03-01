import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ─── PACKAGES NEEDED (pubspec.yaml) ──────────────────────────────────────────
// file_picker: ^6.2.1
// http: ^1.6.0
// dio: ^5.9.1
// intl: ^0.19.0
// ─────────────────────────────────────────────────────────────────────────────

// ─── TODO: API ENDPOINTS ─────────────────────────────────────────────────────
// const String BASE_URL = 'https://your-server.com/api';
//
// GET    $BASE_URL/classes                          → Teacher ki all classes
// POST   $BASE_URL/classes/create                   → New class banao
// GET    $BASE_URL/students?classId=                → Class ke students (DB se)
// POST   $BASE_URL/homework/send                    → Homework bhejo (multipart)
// GET    $BASE_URL/homework?classId=                → Sent homeworks list
// GET    $BASE_URL/homework/:id/submissions         → Who submitted / who didn't
// DELETE $BASE_URL/homework/:id                     → Delete homework
//
// NOTIFICATION LOGIC (Backend pe):
//   Jab homework POST hota hai → backend sirf us classId ke
//   students ko FCM notification bhejega. Physics ke student ko
//   Math ka notification NAHI aayega. ✅
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class ClassGroup {
  final String id;
  final String name;
  final String subject;
  final String icon;
  final Color color;
  final List<StudentItem> students;
  final int homeworkCount;

  ClassGroup({
    required this.id,
    required this.name,
    required this.subject,
    required this.icon,
    required this.color,
    required this.students,
    required this.homeworkCount,
  });
}

class StudentItem {
  final String id;
  final String name;
  final String rollNo;
  final String avatar;
  bool isSelected;

  StudentItem({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.avatar,
    this.isSelected = true,
  });
}

class HomeworkItem {
  final String id;
  final String title;
  final String description;
  final String classId;
  final String className;
  final String subject;
  final Color subjectColor;
  final DateTime dueDate;
  final DateTime sentAt;
  final int totalStudents;
  final int submitted;
  final List<String> attachments;
  final String status;

  HomeworkItem({
    required this.id,
    required this.title,
    required this.description,
    required this.classId,
    required this.className,
    required this.subject,
    required this.subjectColor,
    required this.dueDate,
    required this.sentAt,
    required this.totalStudents,
    required this.submitted,
    required this.attachments,
    required this.status,
  });

  double get submissionRate => totalStudents == 0 ? 0 : submitted / totalStudents;

  bool get isOverdue => DateTime.now().isAfter(dueDate);
  bool get isDueSoon =>
      !isOverdue && dueDate.difference(DateTime.now()).inHours < 24;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOCK DATA
// ═══════════════════════════════════════════════════════════════════════════════

final List<StudentItem> _mathStudents = [
  StudentItem(id: 's1', name: 'Rahul Sharma', rollNo: 'R01', avatar: 'RS'),
  StudentItem(id: 's2', name: 'Priya Patel', rollNo: 'R02', avatar: 'PP'),
  StudentItem(id: 's3', name: 'Amit Kumar', rollNo: 'R03', avatar: 'AK'),
  StudentItem(id: 's4', name: 'Sneha Gupta', rollNo: 'R04', avatar: 'SG'),
  StudentItem(id: 's5', name: 'Rohan Mehta', rollNo: 'R05', avatar: 'RM'),
  StudentItem(id: 's6', name: 'Kavya Singh', rollNo: 'R06', avatar: 'KS'),
  StudentItem(id: 's7', name: 'Arjun Verma', rollNo: 'R07', avatar: 'AV'),
  StudentItem(id: 's8', name: 'Pooja Yadav', rollNo: 'R08', avatar: 'PY'),
];

final List<StudentItem> _scienceStudents = [
  StudentItem(id: 's9', name: 'Varun Joshi', rollNo: 'S01', avatar: 'VJ'),
  StudentItem(id: 's10', name: 'Ananya Das', rollNo: 'S02', avatar: 'AD'),
  StudentItem(id: 's11', name: 'Karan Malhotra', rollNo: 'S03', avatar: 'KM'),
  StudentItem(id: 's12', name: 'Riya Chopra', rollNo: 'S04', avatar: 'RC'),
  StudentItem(id: 's13', name: 'Nikhil Sharma', rollNo: 'S05', avatar: 'NS'),
  StudentItem(id: 's14', name: 'Divya Nair', rollNo: 'S06', avatar: 'DN'),
];

final List<StudentItem> _englishStudents = [
  StudentItem(id: 's15', name: 'Saurav Tiwari', rollNo: 'E01', avatar: 'ST'),
  StudentItem(id: 's16', name: 'Mansi Agarwal', rollNo: 'E02', avatar: 'MA'),
  StudentItem(id: 's17', name: 'Deepak Raj', rollNo: 'E03', avatar: 'DR'),
  StudentItem(id: 's18', name: 'Tanya Khanna', rollNo: 'E04', avatar: 'TK'),
];

List<ClassGroup> _mockClasses = [
  ClassGroup(
    id: 'c1', name: 'Math-10A', subject: 'Mathematics',
    icon: '📐', color: const Color(0xFF6C63FF),
    students: _mathStudents, homeworkCount: 4,
  ),
  ClassGroup(
    id: 'c2', name: 'Science-10B', subject: 'Science',
    icon: '🔬', color: const Color(0xFF00D4AA),
    students: _scienceStudents, homeworkCount: 2,
  ),
  ClassGroup(
    id: 'c3', name: 'English-9A', subject: 'English',
    icon: '📖', color: const Color(0xFFFF6584),
    students: _englishStudents, homeworkCount: 3,
  ),
];

List<HomeworkItem> _mockHomeworks = [
  HomeworkItem(
    id: 'h1', title: 'Algebra Chapter 5 Exercise',
    description: 'Complete all questions from Exercise 5.1 to 5.4. Show full working.',
    classId: 'c1', className: 'Math-10A', subject: 'Mathematics',
    subjectColor: const Color(0xFF6C63FF),
    dueDate: DateTime.now().add(const Duration(hours: 18)),
    sentAt: DateTime.now().subtract(const Duration(hours: 6)),
    totalStudents: 8, submitted: 5,
    attachments: ['exercise_5.pdf'],
    status: 'Active',
  ),
  HomeworkItem(
    id: 'h2', title: 'Newton\'s Laws Assignment',
    description: 'Write 500 words on real life applications of Newton\'s 3 laws.',
    classId: 'c2', className: 'Science-10B', subject: 'Science',
    subjectColor: const Color(0xFF00D4AA),
    dueDate: DateTime.now().add(const Duration(days: 3)),
    sentAt: DateTime.now().subtract(const Duration(days: 1)),
    totalStudents: 6, submitted: 2,
    attachments: [],
    status: 'Active',
  ),
  HomeworkItem(
    id: 'h3', title: 'Essay: My Favourite Season',
    description: 'Write a 300 word essay. Focus on descriptive language.',
    classId: 'c3', className: 'English-9A', subject: 'English',
    subjectColor: const Color(0xFFFF6584),
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
    sentAt: DateTime.now().subtract(const Duration(days: 4)),
    totalStudents: 4, submitted: 4,
    attachments: ['essay_guidelines.pdf', 'sample.docx'],
    status: 'Completed',
  ),
  HomeworkItem(
    id: 'h4', title: 'Quadratic Equations Practice',
    description: 'Solve problems 1–20 from the worksheet attached.',
    classId: 'c1', className: 'Math-10A', subject: 'Mathematics',
    subjectColor: const Color(0xFF6C63FF),
    dueDate: DateTime.now().add(const Duration(days: 5)),
    sentAt: DateTime.now().subtract(const Duration(hours: 2)),
    totalStudents: 8, submitted: 0,
    attachments: ['quadratic_worksheet.pdf'],
    status: 'Active',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class TeacherHomeworkScreen extends StatefulWidget {
  const TeacherHomeworkScreen({super.key});

  @override
  State<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends State<TeacherHomeworkScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late Animation<double> _headerAnim;

  int _selectedTab = 0; // 0=Homeworks, 1=Classes

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _selectedTab = _tabController.index));

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _listCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);

    _headerCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _listCtrl.forward());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          CustomPaint(painter: _BgPainter(), size: Size.infinite),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _HomeworkListTab(
                        homeworks: _mockHomeworks,
                        listCtrl: _listCtrl,
                        onDelete: (hw) => setState(() => _mockHomeworks.remove(hw)),
                      ),
                      _ClassesTab(
                        classes: _mockClasses,
                        listCtrl: _listCtrl,
                        onClassCreated: (cls) => setState(() => _mockClasses.add(cls)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // FAB
          Positioned(
            bottom: 28,
            right: 24,
            child: _buildFAB(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  ).createShader(b),
                  child: const Text('Homework Hub',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: -0.5)),
                ),
                Text('Assign & Track',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
              ],
            ),
            const Spacer(),
            // Stats badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00C6FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00C6FF).withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, color: Color(0xFF00C6FF), size: 14),
                  const SizedBox(width: 5),
                  Text('${_mockHomeworks.length} Active',
                      style: const TextStyle(color: Color(0xFF00C6FF),
                          fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
            borderRadius: BorderRadius.circular(11),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Homeworks (${_mockHomeworks.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Classes (${_mockClasses.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: () => _showSendHomeworkSheet(),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0072FF).withOpacity(0.45),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text('Assign Homework',
                style: TextStyle(color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }

  void _showSendHomeworkSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SendHomeworkSheet(
        classes: _mockClasses,
        onSend: (hw) => setState(() => _mockHomeworks.insert(0, hw)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — HOMEWORK LIST
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeworkListTab extends StatefulWidget {
  final List<HomeworkItem> homeworks;
  final AnimationController listCtrl;
  final Function(HomeworkItem) onDelete;

  const _HomeworkListTab({
    required this.homeworks,
    required this.listCtrl,
    required this.onDelete,
  });

  @override
  State<_HomeworkListTab> createState() => _HomeworkListTabState();
}

class _HomeworkListTabState extends State<_HomeworkListTab> {
  String _filter = 'All';

  List<HomeworkItem> get _filtered {
    if (_filter == 'All') return widget.homeworks;
    if (_filter == 'Active') return widget.homeworks.where((h) => !h.isOverdue).toList();
    if (_filter == 'Overdue') return widget.homeworks.where((h) => h.isOverdue).toList();
    if (_filter == 'Done') return widget.homeworks.where((h) => h.submitted == h.totalStudents).toList();
    return widget.homeworks;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: _filtered.isEmpty
              ? _buildEmpty()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            itemCount: _filtered.length,
            itemBuilder: (context, i) {
              return AnimatedBuilder(
                animation: widget.listCtrl,
                builder: (context, child) {
                  final delay = i * 0.08;
                  final v = math.max(0.0, math.min(1.0,
                      (widget.listCtrl.value - delay) / (1.0 - delay)));
                  final curve = Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
                  return Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: Transform.translate(
                        offset: Offset(0, 30 * (1 - curve)), child: child),
                  );
                },
                child: _HomeworkCard(
                  hw: _filtered[i],
                  onDelete: () => widget.onDelete(_filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 0, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['All', 'Active', 'Overdue', 'Done'].map((f) {
            final selected = _filter == f;
            return GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)])
                      : null,
                  color: selected ? null : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? Colors.transparent : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(f,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    )),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📭', style: const TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text('No homeworks here',
              style: TextStyle(color: Colors.white.withOpacity(0.4),
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Homework Card ────────────────────────────────────────────────────────────

class _HomeworkCard extends StatelessWidget {
  final HomeworkItem hw;
  final VoidCallback onDelete;

  const _HomeworkCard({required this.hw, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final pending = hw.totalStudents - hw.submitted;
    final dueBadgeColor = hw.isOverdue
        ? const Color(0xFFFF6584)
        : hw.isDueSoon
        ? const Color(0xFFFFB347)
        : const Color(0xFF00D4AA);
    final dueText = hw.isOverdue
        ? 'Overdue'
        : hw.isDueSoon
        ? 'Due Soon'
        : 'On Track';

    return GestureDetector(
      onTap: () => _showSubmissionSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hw.subjectColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: hw.subjectColor.withOpacity(0.07),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [hw.subjectColor, hw.subjectColor.withOpacity(0.3)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Subject badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: hw.subjectColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(hw.subject.substring(0, 3).toUpperCase(),
                                style: TextStyle(color: hw.subjectColor,
                                    fontSize: 11, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(hw.className,
                            style: TextStyle(color: Colors.white.withOpacity(0.5),
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      // Due status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: dueBadgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: dueBadgeColor.withOpacity(0.3)),
                        ),
                        child: Text(dueText,
                            style: TextStyle(color: dueBadgeColor,
                                fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(hw.title,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(hw.description,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.4),
                          fontSize: 13, height: 1.4)),
                  const SizedBox(height: 14),
                  // Attachments
                  if (hw.attachments.isNotEmpty) ...[
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: hw.attachments.map((a) => _attachmentChip(a)).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Submission progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${hw.submitted}/${hw.totalStudents} submitted',
                                    style: TextStyle(color: Colors.white.withOpacity(0.6),
                                        fontSize: 12, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text('${(hw.submissionRate * 100).toInt()}%',
                                    style: TextStyle(color: hw.subjectColor,
                                        fontSize: 12, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: hw.submissionRate,
                                backgroundColor: Colors.white.withOpacity(0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(hw.subjectColor),
                                minHeight: 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: Colors.white.withOpacity(0.3), size: 13),
                  const SizedBox(width: 5),
                  Text(_formatDate(hw.dueDate),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  const SizedBox(width: 14),
                  if (pending > 0) ...[
                    Icon(Icons.pending_outlined, color: const Color(0xFFFFB347), size: 13),
                    const SizedBox(width: 4),
                    Text('$pending pending',
                        style: const TextStyle(color: Color(0xFFFFB347),
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ] else ...[
                    const Icon(Icons.check_circle, color: Color(0xFF00D4AA), size: 13),
                    const SizedBox(width: 4),
                    const Text('All submitted',
                        style: TextStyle(color: Color(0xFF00D4AA),
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showSubmissionSheet(context),
                    child: Text('View Details →',
                        style: TextStyle(color: hw.subjectColor,
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline,
                        color: Colors.white.withOpacity(0.2), size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentChip(String name) {
    final isImg = name.contains('.jpg') || name.contains('.png');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isImg ? Icons.image_outlined : Icons.attach_file,
              color: Colors.white.withOpacity(0.4), size: 12),
          const SizedBox(width: 4),
          Text(name,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  void _showSubmissionSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SubmissionSheet(hw: hw),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUBMISSION DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _SubmissionSheet extends StatefulWidget {
  final HomeworkItem hw;
  const _SubmissionSheet({required this.hw});

  @override
  State<_SubmissionSheet> createState() => _SubmissionSheetState();
}

class _SubmissionSheetState extends State<_SubmissionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _tabIdx = 0;

  final List<String> _submitted = ['Rahul Sharma', 'Priya Patel', 'Sneha Gupta',
    'Kavya Singh', 'Arjun Verma'];
  final List<String> _pending = ['Amit Kumar', 'Rohan Mehta', 'Pooja Yadav'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _tabIdx = _tab.index));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hw = widget.hw;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: hw.subjectColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(hw.subject.substring(0, 1),
                        style: TextStyle(color: hw.subjectColor,
                            fontWeight: FontWeight.w900, fontSize: 20))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hw.title,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 16, fontWeight: FontWeight.w800)),
                        Text(hw.className,
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(hw.submissionRate * 100).toInt()}%',
                          style: TextStyle(color: hw.subjectColor,
                              fontSize: 22, fontWeight: FontWeight.w900)),
                      Text('submitted', style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tab bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: hw.subjectColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: hw.subjectColor.withOpacity(0.5)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: hw.subjectColor,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  tabs: [
                    Tab(text: '✓ Submitted (${_submitted.length})'),
                    Tab(text: '⏳ Pending (${_pending.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _studentList(_submitted, const Color(0xFF00D4AA), true),
                  _studentList(_pending, const Color(0xFFFFB347), false),
                ],
              ),
            ),
            // Send reminder button (for pending tab)
            if (_tabIdx == 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: const Color(0xFFFFB347),
                      content: Text('🔔 Reminder sent to ${_pending.length} students!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFFB347), Color(0xFFFF8C42)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFFFB347).withOpacity(0.35),
                            blurRadius: 12, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Send Reminder to ${_pending.length} Students',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _studentList(List<String> names, Color color, bool isSubmitted) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      itemCount: names.length,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(names[i].substring(0, 1),
                    style: TextStyle(color: color, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(names[i],
                  style: const TextStyle(color: Colors.white,
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ),
            Icon(isSubmitted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — CLASSES
// ═══════════════════════════════════════════════════════════════════════════════

class _ClassesTab extends StatelessWidget {
  final List<ClassGroup> classes;
  final AnimationController listCtrl;
  final Function(ClassGroup) onClassCreated;

  const _ClassesTab({
    required this.classes,
    required this.listCtrl,
    required this.onClassCreated,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      itemCount: classes.length + 1,
      itemBuilder: (context, i) {
        if (i == classes.length) {
          return _buildCreateClassCard(context);
        }
        return AnimatedBuilder(
          animation: listCtrl,
          builder: (_, child) {
            final delay = i * 0.1;
            final v = math.max(0.0, math.min(1.0,
                (listCtrl.value - delay) / (1.0 - delay)));
            final curve = Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
            return Opacity(
              opacity: v.clamp(0.0, 1.0),
              child: Transform.translate(
                  offset: Offset(0, 25 * (1 - curve)), child: child),
            );
          },
          child: _ClassCard(cls: classes[i]),
        );
      },
    );
  }

  Widget _buildCreateClassCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCreateClassSheet(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF00C6FF).withOpacity(0.3),
              width: 1.5,
              style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: const Color(0xFF00C6FF).withOpacity(0.6), size: 22),
            const SizedBox(width: 10),
            Text('Create New Class',
                style: TextStyle(color: const Color(0xFF00C6FF).withOpacity(0.7),
                    fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _showCreateClassSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateClassSheet(
        onCreated: onClassCreated,
        allStudents: [..._mathStudents, ..._scienceStudents, ..._englishStudents],
      ),
    );
  }
}

// ─── Class Card ───────────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  final ClassGroup cls;
  const _ClassCard({required this.cls});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF131929),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cls.color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: cls.color.withOpacity(0.08),
              blurRadius: 16, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cls.color, cls.color.withOpacity(0.3)]),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: cls.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(cls.icon, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cls.name,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(cls.subject,
                              style: TextStyle(color: cls.color, fontSize: 13)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${cls.students.length}',
                            style: const TextStyle(color: Colors.white,
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        Text('students',
                            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Student avatars
                Row(
                  children: [
                    SizedBox(
                      height: 28,
                      width: math.min(cls.students.length * 20.0, 100),
                      child: Stack(
                        children: List.generate(
                          math.min(cls.students.length, 5),
                              (i) => Positioned(
                            left: i * 18.0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: cls.color.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF131929), width: 2),
                              ),
                              child: Center(
                                child: Text(cls.students[i].avatar.substring(0, 1),
                                    style: TextStyle(color: cls.color,
                                        fontSize: 9, fontWeight: FontWeight.w900)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (cls.students.length > 5)
                      Text('+${cls.students.length - 5} more',
                          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cls.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${cls.homeworkCount} Homeworks',
                          style: TextStyle(color: cls.color,
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE CLASS SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _CreateClassSheet extends StatefulWidget {
  final Function(ClassGroup) onCreated;
  final List<StudentItem> allStudents;

  const _CreateClassSheet({required this.onCreated, required this.allStudents});

  @override
  State<_CreateClassSheet> createState() => _CreateClassSheetState();
}

class _CreateClassSheetState extends State<_CreateClassSheet> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  String _searchQuery = '';
  late List<StudentItem> _students;

  final _colors = [
    const Color(0xFF6C63FF), const Color(0xFF00D4AA),
    const Color(0xFFFF6584), const Color(0xFFFFB347), const Color(0xFF00D4FF),
  ];
  int _selectedColor = 0;

  final _icons = ['📐', '🔬', '📖', '🌍', '💻', '✍️', '🎨', '🏃'];
  int _selectedIcon = 0;

  @override
  void initState() {
    super.initState();
    // Deep copy so selections don't affect other screens
    _students = widget.allStudents
        .map((s) => StudentItem(
        id: s.id, name: s.name, rollNo: s.rollNo,
        avatar: s.avatar, isSelected: false))
        .toList();
  }

  List<StudentItem> get _filtered => _students.where((s) {
    final q = _searchQuery.toLowerCase();
    return s.name.toLowerCase().contains(q) || s.rollNo.toLowerCase().contains(q);
  }).toList();

  int get _selectedCount => _students.where((s) => s.isSelected).toList().length;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle + header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        ).createShader(b),
                        child: const Text('Create Class',
                            style: TextStyle(color: Colors.white,
                                fontSize: 22, fontWeight: FontWeight.w900)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                children: [
                  // Class name & subject
                  _inputField(_nameCtrl, 'Class Name (e.g. Math-10A)', Icons.class_outlined),
                  const SizedBox(height: 10),
                  _inputField(_subjectCtrl, 'Subject', Icons.subject),
                  const SizedBox(height: 20),
                  // Color picker
                  Text('ACCENT COLOR', style: _labelStyle),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(_colors.length, (i) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: _colors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == i ? Colors.white : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: _selectedColor == i ? [
                            BoxShadow(color: _colors[i].withOpacity(0.5), blurRadius: 10),
                          ] : [],
                        ),
                        child: _selectedColor == i
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    )),
                  ),
                  const SizedBox(height: 20),
                  // Icon picker
                  Text('CLASS ICON', style: _labelStyle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: List.generate(_icons.length, (i) => GestureDetector(
                      onTap: () => setState(() => _selectedIcon = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: _selectedIcon == i
                              ? _colors[_selectedColor].withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedIcon == i
                                ? _colors[_selectedColor]
                                : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Center(child: Text(_icons[i],
                            style: const TextStyle(fontSize: 22))),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),
                  // Student selector
                  Row(
                    children: [
                      Text('ADD STUDENTS', style: _labelStyle),
                      const Spacer(),
                      Text('$_selectedCount selected',
                          style: TextStyle(
                              color: _colors[_selectedColor],
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search students from DB...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.white.withOpacity(0.3), size: 16),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Select all
                  GestureDetector(
                    onTap: () {
                      final allSelected = _filtered.every((s) => s.isSelected);
                      setState(() {
                        for (final s in _filtered) s.isSelected = !allSelected;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.select_all,
                              color: _colors[_selectedColor], size: 16),
                          const SizedBox(width: 6),
                          Text('Select / Deselect All',
                              style: TextStyle(color: _colors[_selectedColor],
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  // Student list
                  ..._filtered.map((s) => GestureDetector(
                    onTap: () => setState(() => s.isSelected = !s.isSelected),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: s.isSelected
                            ? _colors[_selectedColor].withOpacity(0.08)
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: s.isSelected
                              ? _colors[_selectedColor].withOpacity(0.35)
                              : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: _colors[_selectedColor].withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(s.avatar,
                                style: TextStyle(color: _colors[_selectedColor],
                                    fontWeight: FontWeight.w900, fontSize: 11))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 14, fontWeight: FontWeight.w600)),
                                Text(s.rollNo,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.35), fontSize: 12)),
                              ],
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: s.isSelected
                                  ? _colors[_selectedColor]
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: s.isSelected
                                    ? _colors[_selectedColor]
                                    : Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: s.isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
            // Create button
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1623),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: GestureDetector(
                onTap: _selectedCount == 0 ? null : () {
                  if (_nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: const Color(0xFFFF6584),
                      content: const Text('Class name is required!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                    return;
                  }

                  // TODO: POST to API
                  // await http.post(Uri.parse('$BASE_URL/classes/create'),
                  //   body: jsonEncode({
                  //     'name': _nameCtrl.text,
                  //     'subject': _subjectCtrl.text,
                  //     'studentIds': selected.map((s) => s.id).toList(),
                  //   }));

                  final selected = _students.where((s) => s.isSelected).toList();
                  final newClass = ClassGroup(
                    id: 'c${DateTime.now().millisecond}',
                    name: _nameCtrl.text.trim(),
                    subject: _subjectCtrl.text.trim().isEmpty
                        ? 'General' : _subjectCtrl.text.trim(),
                    icon: _icons[_selectedIcon],
                    color: _colors[_selectedColor],
                    students: selected,
                    homeworkCount: 0,
                  );
                  widget.onCreated(newClass);
                  Navigator.pop(context);
                  HapticFeedback.heavyImpact();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: _selectedCount > 0
                        ? LinearGradient(colors: [_colors[_selectedColor],
                      _colors[_selectedColor].withOpacity(0.7)])
                        : const LinearGradient(colors: [Colors.grey, Colors.grey]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _selectedCount > 0 ? [
                      BoxShadow(color: _colors[_selectedColor].withOpacity(0.4),
                          blurRadius: 16, offset: const Offset(0, 6)),
                    ] : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _selectedCount == 0
                            ? 'Select students to create class'
                            : 'Create Class with $_selectedCount Students',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF00C6FF).withOpacity(0.6), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  TextStyle get _labelStyle => TextStyle(
      color: Colors.white.withOpacity(0.35),
      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2);
}

// ═══════════════════════════════════════════════════════════════════════════════
// SEND HOMEWORK SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _SendHomeworkSheet extends StatefulWidget {
  final List<ClassGroup> classes;
  final Function(HomeworkItem) onSend;

  const _SendHomeworkSheet({required this.classes, required this.onSend});

  @override
  State<_SendHomeworkSheet> createState() => _SendHomeworkSheetState();
}

class _SendHomeworkSheetState extends State<_SendHomeworkSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  ClassGroup? _selectedClass;
  DateTime? _dueDate;
  final List<String> _attachments = [];
  bool _isSending = false;

  int get _step {
    if (_selectedClass == null) return 0;
    if (_titleCtrl.text.isEmpty) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        ).createShader(b),
                        child: const Text('Assign Homework',
                            style: TextStyle(color: Colors.white,
                                fontSize: 22, fontWeight: FontWeight.w900)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🔔 Notification will be sent ONLY to selected class students',
                    style: TextStyle(color: Colors.white.withOpacity(0.4),
                        fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                children: [
                  // Step 1: Select Class
                  _sectionLabel('1. SELECT CLASS', const Color(0xFF00C6FF)),
                  const SizedBox(height: 10),
                  ...widget.classes.map((cls) => GestureDetector(
                    onTap: () => setState(() => _selectedClass = cls),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedClass?.id == cls.id
                            ? cls.color.withOpacity(0.1)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedClass?.id == cls.id
                              ? cls.color.withOpacity(0.5)
                              : Colors.white.withOpacity(0.06),
                          width: _selectedClass?.id == cls.id ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(cls.icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cls.name, style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('${cls.students.length} students  •  ${cls.subject}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                            ],
                          ),
                          const Spacer(),
                          if (_selectedClass?.id == cls.id)
                            Icon(Icons.check_circle, color: cls.color, size: 22)
                          else
                            Icon(Icons.radio_button_unchecked,
                                color: Colors.white.withOpacity(0.2), size: 22),
                        ],
                      ),
                    ),
                  )),

                  if (_selectedClass != null) ...[
                    const SizedBox(height: 20),
                    // Step 2: Title + Description
                    _sectionLabel('2. HOMEWORK DETAILS', const Color(0xFF00C6FF)),
                    const SizedBox(height: 10),
                    _hwTextField(_titleCtrl, 'Homework Title', Icons.title, onChanged: (_) => setState((){})),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Instructions / Description...\ne.g. Complete Exercise 5.1 before 24 Aug',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Step 3: Due date
                    _sectionLabel('3. DUE DATE', const Color(0xFF00C6FF)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 3)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 90)),
                          builder: (context, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF00C6FF),
                                surface: Color(0xFF131929),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _dueDate != null
                              ? const Color(0xFF00C6FF).withOpacity(0.08)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _dueDate != null
                                ? const Color(0xFF00C6FF).withOpacity(0.4)
                                : Colors.white.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: _dueDate != null
                                    ? const Color(0xFF00C6FF)
                                    : Colors.white.withOpacity(0.3),
                                size: 18),
                            const SizedBox(width: 12),
                            Text(
                              _dueDate == null
                                  ? 'Set due date (optional)'
                                  : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                              style: TextStyle(
                                color: _dueDate != null
                                    ? const Color(0xFF00C6FF)
                                    : Colors.white.withOpacity(0.3),
                                fontWeight: _dueDate != null ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Step 4: Attachments
                    _sectionLabel('4. ATTACHMENTS (OPTIONAL)', const Color(0xFF00C6FF)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _attachBtn(Icons.picture_as_pdf_outlined, 'PDF/Doc',
                            const Color(0xFFFF6584), () => _addMockAttachment('document.pdf')),
                        const SizedBox(width: 10),
                        _attachBtn(Icons.image_outlined, 'Image',
                            const Color(0xFF6C63FF), () => _addMockAttachment('image.jpg')),
                      ],
                    ),
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _attachments.map((a) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_file,
                                  color: Colors.white.withOpacity(0.4), size: 13),
                              const SizedBox(width: 4),
                              Text(a, style: TextStyle(
                                  color: Colors.white.withOpacity(0.6), fontSize: 12)),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() => _attachments.remove(a)),
                                child: Icon(Icons.close,
                                    color: Colors.white.withOpacity(0.3), size: 14),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            // Send button
            if (_selectedClass != null)
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1623),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                ),
                child: GestureDetector(
                  onTap: _titleCtrl.text.trim().isEmpty ? null : () async {
                    setState(() => _isSending = true);
                    HapticFeedback.heavyImpact();

                    await Future.delayed(const Duration(seconds: 2));

                    // TODO: Dio multipart upload
                    // var request = http.MultipartRequest('POST',
                    //   Uri.parse('$BASE_URL/homework/send'));
                    // request.fields['classId'] = _selectedClass!.id;
                    // request.fields['title'] = _titleCtrl.text;
                    // request.fields['description'] = _descCtrl.text;
                    // request.fields['dueDate'] = _dueDate?.toIso8601String() ?? '';
                    // for (final f in files) request.files.add(...);
                    // Backend will then send FCM ONLY to _selectedClass students ✅

                    final newHw = HomeworkItem(
                      id: 'h${DateTime.now().millisecond}',
                      title: _titleCtrl.text.trim(),
                      description: _descCtrl.text.trim().isEmpty
                          ? 'No description' : _descCtrl.text.trim(),
                      classId: _selectedClass!.id,
                      className: _selectedClass!.name,
                      subject: _selectedClass!.subject,
                      subjectColor: _selectedClass!.color,
                      dueDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
                      sentAt: DateTime.now(),
                      totalStudents: _selectedClass!.students.length,
                      submitted: 0,
                      attachments: _attachments,
                      status: 'Active',
                    );

                    widget.onSend(newHw);
                    if (mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: const Color(0xFF00D4AA),
                      content: Text(
                          '✓ Homework sent! 🔔 Notification delivered to ${_selectedClass!.students.length} students of ${_selectedClass!.name}'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _titleCtrl.text.trim().isEmpty
                          ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                          : const LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _titleCtrl.text.trim().isEmpty ? [] : [
                        BoxShadow(color: const Color(0xFF0072FF).withOpacity(0.4),
                            blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Center(
                      child: _isSending
                          ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_outlined, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            _titleCtrl.text.trim().isEmpty
                                ? 'Enter homework title first'
                                : 'Send to ${_selectedClass!.students.length} Students 🔔',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color color) {
    return Text(label,
        style: TextStyle(color: color.withOpacity(0.7),
            fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2));
  }

  Widget _attachBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 7),
              Text(label, style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hwTextField(TextEditingController ctrl, String hint,
      IconData icon, {Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF00C6FF).withOpacity(0.6), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF00C6FF), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _addMockAttachment(String name) {
    // TODO: Replace with actual FilePicker
    // FilePickerResult? result = await FilePicker.platform.pickFiles();
    setState(() => _attachments.add(name));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF00C6FF).withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.1), 170, p);
    p.color = const Color(0xFF0072FF).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.55), 140, p);
    p.color = const Color(0xFF00D4AA).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.88), 110, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}