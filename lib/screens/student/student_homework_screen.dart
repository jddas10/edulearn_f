import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

// ─── STUDENT HOMEWORK SCREEN ─────────────────────────────────────────────────
// Student apna assigned homework dekh sakta hai, submit kar sakta hai
// Screens:
//   1. StudentHomeworkScreen     → List of all homeworks (filter: All/Pending/Submitted/Overdue)
//   2. _HomeworkDetailSheet      → Full detail + submit button + file attach
//   3. _SubmitHomeworkSheet      → File attach + note + submit flow
// ─────────────────────────────────────────────────────────────────────────────

// ─── PACKAGES NEEDED ─────────────────────────────────────────────────────────
// file_picker: ^6.2.1
// http: ^1.6.0
// dio: ^5.9.1
// ─────────────────────────────────────────────────────────────────────────────

// ─── TODO: API ENDPOINTS ─────────────────────────────────────────────────────
// GET  $BASE_URL/homework/student?studentId=   → Student ke liye sirf uski class ka homework
// POST $BASE_URL/homework/:id/submit           → Submit (multipart: file + note)
// GET  $BASE_URL/homework/:id                 → Detail view
// ─────────────────────────────────────────────────────────────────────────────

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class _StudentHomework {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String teacherName;
  final String className;
  final Color color;
  final String icon;
  final DateTime assignedOn;
  final DateTime dueDate;
  final List<String> attachments; // Teacher ne jo bheja
  bool isSubmitted;
  String? submittedNote;
  String? submittedFileName;
  DateTime? submittedAt;

  _StudentHomework({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.teacherName,
    required this.className,
    required this.color,
    required this.icon,
    required this.assignedOn,
    required this.dueDate,
    required this.attachments,
    this.isSubmitted = false,
    this.submittedNote,
    this.submittedFileName,
    this.submittedAt,
  });

  bool get isOverdue =>
      !isSubmitted && DateTime.now().isAfter(dueDate);

  bool get isDueSoon =>
      !isSubmitted &&
          !isOverdue &&
          dueDate.difference(DateTime.now()).inHours < 24;

  String get statusLabel {
    if (isSubmitted) return 'Submitted';
    if (isOverdue) return 'Overdue';
    if (isDueSoon) return 'Due Soon';
    return 'Pending';
  }

  Color get statusColor {
    if (isSubmitted) return const Color(0xFF00D4AA);
    if (isOverdue) return const Color(0xFFFF6584);
    if (isDueSoon) return const Color(0xFFFFB347);
    return const Color(0xFF6C63FF);
  }

  IconData get statusIcon {
    if (isSubmitted) return Icons.check_circle;
    if (isOverdue) return Icons.cancel_outlined;
    if (isDueSoon) return Icons.timer_outlined;
    return Icons.radio_button_unchecked;
  }

  String get daysLeft {
    if (isSubmitted) return 'Done';
    final diff = dueDate.difference(DateTime.now());
    if (diff.isNegative) return '${diff.inDays.abs()}d overdue';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    return '${diff.inDays}d left';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MOCK DATA  (Backend se replace karo — sirf is student ki class ka data aayega)
// ═══════════════════════════════════════════════════════════════════════════════

final List<_StudentHomework> _mockHomeworks = [
  _StudentHomework(
    id: 'h1',
    title: 'Algebra Chapter 5 Exercise',
    description:
    'Complete all questions from Exercise 5.1 to 5.4. Show full working for each step. Marks will be deducted for incomplete steps.',
    subject: 'Mathematics',
    teacherName: 'Mr. Sharma',
    className: 'Math-10A',
    color: const Color(0xFF6C63FF),
    icon: '📐',
    assignedOn: DateTime.now().subtract(const Duration(hours: 6)),
    dueDate: DateTime.now().add(const Duration(hours: 18)),
    attachments: ['exercise_5.pdf'],
    isSubmitted: false,
  ),
  _StudentHomework(
    id: 'h2',
    title: "Newton's Laws Assignment",
    description:
    "Write 500 words on real life applications of Newton's 3 laws with diagrams. Include at least 2 real-world examples per law.",
    subject: 'Science',
    teacherName: 'Mr. Verma',
    className: 'Science-10B',
    color: const Color(0xFF00D4AA),
    icon: '🔬',
    assignedOn: DateTime.now().subtract(const Duration(days: 1)),
    dueDate: DateTime.now().add(const Duration(days: 3)),
    attachments: [],
    isSubmitted: false,
  ),
  _StudentHomework(
    id: 'h3',
    title: 'Essay: My Favourite Season',
    description:
    'Write a 300 word essay. Focus on descriptive language, similes and metaphors.',
    subject: 'English',
    teacherName: 'Ms. Priya',
    className: 'English-9A',
    color: const Color(0xFFFF6584),
    icon: '📖',
    assignedOn: DateTime.now().subtract(const Duration(days: 4)),
    dueDate: DateTime.now().subtract(const Duration(days: 1)),
    attachments: ['essay_guidelines.pdf', 'sample.docx'],
    isSubmitted: true,
    submittedNote: 'I enjoyed writing this! Focused on Winter season.',
    submittedFileName: 'my_essay_rahul.pdf',
    submittedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  _StudentHomework(
    id: 'h4',
    title: 'Quadratic Equations Practice',
    description:
    'Solve problems 1–20 from the worksheet attached. Use the quadratic formula method only.',
    subject: 'Mathematics',
    teacherName: 'Mr. Sharma',
    className: 'Math-10A',
    color: const Color(0xFF6C63FF),
    icon: '📐',
    assignedOn: DateTime.now().subtract(const Duration(hours: 2)),
    dueDate: DateTime.now().add(const Duration(days: 5)),
    attachments: ['quadratic_worksheet.pdf'],
    isSubmitted: false,
  ),
  _StudentHomework(
    id: 'h5',
    title: 'History: World War II Summary',
    description:
    'Write a 400 word summary of the key causes and effects of World War II. Include dates.',
    subject: 'History',
    teacherName: 'Ms. Nair',
    className: 'History-10A',
    color: const Color(0xFFFFB347),
    icon: '🌍',
    assignedOn: DateTime.now().subtract(const Duration(days: 2)),
    dueDate: DateTime.now().subtract(const Duration(hours: 3)),
    attachments: [],
    isSubmitted: false,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({super.key});

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late Animation<double> _headerAnim;

  int _selectedFilter = 0;
  final List<String> _filters = ['All', 'Pending', 'Submitted', 'Overdue'];

  // Summary counts
  int get _pendingCount =>
      _mockHomeworks.where((h) => !h.isSubmitted && !h.isOverdue).length;
  int get _submittedCount =>
      _mockHomeworks.where((h) => h.isSubmitted).length;
  int get _overdueCount =>
      _mockHomeworks.where((h) => h.isOverdue).length;

  List<_StudentHomework> get _filtered {
    switch (_selectedFilter) {
      case 1:
        return _mockHomeworks
            .where((h) => !h.isSubmitted && !h.isOverdue)
            .toList();
      case 2:
        return _mockHomeworks.where((h) => h.isSubmitted).toList();
      case 3:
        return _mockHomeworks.where((h) => h.isOverdue).toList();
      default:
      // Sort: overdue first, then due soon, then pending, then submitted
        final list = List<_StudentHomework>.from(_mockHomeworks);
        list.sort((a, b) {
          int priority(h) {
            if (h.isOverdue) return 0;
            if (h.isDueSoon) return 1;
            if (!h.isSubmitted) return 2;
            return 3;
          }
          return priority(a).compareTo(priority(b));
        });
        return list;
    }
  }

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _headerAnim =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);

    _headerCtrl.forward();
    Future.delayed(
        const Duration(milliseconds: 300), () => _listCtrl.forward());
  }

  @override
  void dispose() {
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
          Positioned.fill(child: CustomPaint(painter: _HwBgPainter())),
          SafeArea(
            child: FadeTransition(
              opacity: _headerAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSummaryRow(),
                  _buildFilterTabs(),
                  Expanded(child: _buildHomeworkList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
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
                  colors: [Color(0xFF00C6FF), Color(0xFFFFB347)],
                ).createShader(b),
                child: const Text(
                  'My Homework',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              Text(
                'Class 10 — Section A',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const Spacer(),
          // Pending badge
          if (_pendingCount > 0)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB347).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFFB347).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pending_outlined,
                      color: Color(0xFFFFB347), size: 14),
                  const SizedBox(width: 5),
                  Text('$_pendingCount pending',
                      style: const TextStyle(
                          color: Color(0xFFFFB347),
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Summary Row ─────────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00C6FF).withOpacity(0.1),
              const Color(0xFF0072FF).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF00C6FF).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            _summaryItem('${_mockHomeworks.length}', 'Total',
                const Color(0xFF00C6FF)),
            _sumDivider(),
            _summaryItem('$_pendingCount', 'Pending',
                const Color(0xFF6C63FF)),
            _sumDivider(),
            _summaryItem('$_submittedCount', 'Submitted',
                const Color(0xFF00D4AA)),
            _sumDivider(),
            _summaryItem('$_overdueCount', 'Overdue',
                const Color(0xFFFF6584)),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
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

  Widget _sumDivider() =>
      Container(width: 1, height: 34, color: Colors.white.withOpacity(0.08));

  // ── Filter Tabs ─────────────────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    final counts = [
      _mockHomeworks.length,
      _pendingCount,
      _submittedCount,
      _overdueCount,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 4),
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
                setState(() {
                  _selectedFilter = i;
                  _listCtrl.reset();
                  _listCtrl.forward();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)])
                      : null,
                  color: selected
                      ? null
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      _filters[i],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.45),
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                    if (counts[i] > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.25)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${counts[i]}',
                          style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Homework List ────────────────────────────────────────────────────────────

  Widget _buildHomeworkList() {
    final list = _filtered;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 14),
            Text(
              _selectedFilter == 2
                  ? 'Nothing submitted yet'
                  : 'All clear! No homework here',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: list.length,
      itemBuilder: (context, i) {
        return AnimatedBuilder(
          animation: _listCtrl,
          builder: (ctx, child) {
            final delay = i * 0.1;
            final v = math.max(
                0.0,
                math.min(1.0,
                    (_listCtrl.value - delay) / (1.0 - delay)));
            final curve =
            Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
            return Opacity(
              opacity: curve,
              child: Transform.translate(
                  offset: Offset(0, 32 * (1 - curve)), child: child),
            );
          },
          child: _HomeworkCard(
            hw: list[i],
            onSubmit: () {
              _showSubmitSheet(list[i]);
            },
            onTap: () => _showDetail(list[i]),
          ),
        );
      },
    );
  }

  void _showDetail(_StudentHomework hw) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HomeworkDetailSheet(
        hw: hw,
        onSubmitTap: () {
          Navigator.pop(context);
          _showSubmitSheet(hw);
        },
      ),
    );
  }

  void _showSubmitSheet(_StudentHomework hw) {
    if (hw.isSubmitted || hw.isOverdue) return;
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SubmitHomeworkSheet(
        hw: hw,
        onSubmitted: (note, fileName) {
          setState(() {
            hw.isSubmitted = true;
            hw.submittedNote = note;
            hw.submittedFileName = fileName;
            hw.submittedAt = DateTime.now();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF00D4AA),
              content: Text('✓ "${hw.title}" submitted successfully!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOMEWORK CARD
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeworkCard extends StatelessWidget {
  final _StudentHomework hw;
  final VoidCallback onSubmit;
  final VoidCallback onTap;

  const _HomeworkCard({
    required this.hw,
    required this.onSubmit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hw.isSubmitted
                ? const Color(0xFF00D4AA).withOpacity(0.25)
                : hw.isOverdue
                ? const Color(0xFFFF6584).withOpacity(0.25)
                : hw.color.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: (hw.isSubmitted
                  ? const Color(0xFF00D4AA)
                  : hw.color)
                  .withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  hw.statusColor,
                  hw.statusColor.withOpacity(0.2),
                ]),
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row
                  Row(
                    children: [
                      // Subject icon
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: hw.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(hw.icon,
                              style: const TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hw.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(hw.subject,
                                    style: TextStyle(
                                        color: hw.color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text(' • ',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.2),
                                        fontSize: 12)),
                                Text(hw.teacherName,
                                    style: TextStyle(
                                        color:
                                        Colors.white.withOpacity(0.4),
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: hw.statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: hw.statusColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(hw.statusIcon,
                                color: hw.statusColor, size: 10),
                            const SizedBox(width: 4),
                            Text(hw.statusLabel,
                                style: TextStyle(
                                    color: hw.statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    hw.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 13,
                        height: 1.4),
                  ),

                  const SizedBox(height: 12),

                  // Attachments (teacher ne diye hue)
                  if (hw.attachments.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: hw.attachments
                          .map((a) => _attachChip(a))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Submission info (if submitted)
                  if (hw.isSubmitted && hw.submittedFileName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF00D4AA).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Color(0xFF00D4AA), size: 14),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Submitted: ${hw.submittedFileName}',
                              style: const TextStyle(
                                  color: Color(0xFF00D4AA),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Bottom info row
                  Row(
                    children: [
                      // Due date
                      Icon(Icons.calendar_today_outlined,
                          color: Colors.white.withOpacity(0.3), size: 12),
                      const SizedBox(width: 5),
                      Text(
                        _formatDate(hw.dueDate),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12),
                      ),
                      const SizedBox(width: 10),
                      // Days left pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: hw.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          hw.daysLeft,
                          style: TextStyle(
                              color: hw.statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      // Action button
                      if (!hw.isSubmitted && !hw.isOverdue)
                        GestureDetector(
                          onTap: onSubmit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                hw.color,
                                hw.color.withOpacity(0.7),
                              ]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                    color: hw.color.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3)),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.upload_outlined,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 5),
                                Text('Submit',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        )
                      else if (hw.isOverdue)
                        Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                color: Color(0xFFFF6584), size: 14),
                            const SizedBox(width: 4),
                            Text('Closed',
                                style: TextStyle(
                                    color: const Color(0xFFFF6584)
                                        .withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF00D4AA), size: 14),
                            const SizedBox(width: 4),
                            const Text('Done',
                                style: TextStyle(
                                    color: Color(0xFF00D4AA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      const SizedBox(width: 8),
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

  Widget _attachChip(String name) {
    final isPdf = name.contains('.pdf');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.attach_file,
            color: isPdf
                ? const Color(0xFFFF6584).withOpacity(0.7)
                : Colors.white.withOpacity(0.4),
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(name,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOMEWORK DETAIL BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeworkDetailSheet extends StatelessWidget {
  final _StudentHomework hw;
  final VoidCallback onSubmitTap;

  const _HomeworkDetailSheet(
      {required this.hw, required this.onSubmitTap});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.94,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                children: [
                  // Subject + title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: hw.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(hw.icon,
                              style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hw.title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    height: 1.3)),
                            const SizedBox(height: 4),
                            Text('${hw.subject} • ${hw.teacherName}',
                                style: TextStyle(
                                    color: hw.color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Status + due date card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hw.statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: hw.statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(hw.statusIcon,
                            color: hw.statusColor, size: 26),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hw.statusLabel,
                                style: TextStyle(
                                    color: hw.statusColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900)),
                            Text(
                              hw.isSubmitted && hw.submittedAt != null
                                  ? 'Submitted on ${_fmt(hw.submittedAt!)}'
                                  : 'Due: ${_fmt(hw.dueDate)}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: hw.statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(hw.daysLeft,
                              style: TextStyle(
                                  color: hw.statusColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Instructions
                  _sectionLabel('INSTRUCTIONS'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Text(
                      hw.description,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14,
                          height: 1.6),
                    ),
                  ),

                  // Teacher's attachments
                  if (hw.attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionLabel('TEACHER\'S ATTACHMENTS'),
                    const SizedBox(height: 8),
                    ...hw.attachments.map((a) => _downloadRow(a)),
                  ],

                  // Submitted work (if done)
                  if (hw.isSubmitted) ...[
                    const SizedBox(height: 16),
                    _sectionLabel('YOUR SUBMISSION'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF00D4AA).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF00D4AA), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  hw.submittedFileName ?? 'Submitted',
                                  style: const TextStyle(
                                      color: Color(0xFF00D4AA),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          if (hw.submittedNote != null &&
                              hw.submittedNote!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '"${hw.submittedNote}"',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4),
                            ),
                          ],
                          if (hw.submittedAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Submitted at ${_fmtTime(hw.submittedAt!)}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Submit button
            if (!hw.isSubmitted && !hw.isOverdue)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
                child: GestureDetector(
                  onTap: onSubmitTap,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [hw.color, hw.color.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: hw.color.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_outlined,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Submit Homework',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
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

  Widget _sectionLabel(String label) => Text(label,
      style: TextStyle(
          color: Colors.white.withOpacity(0.35),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3));

  Widget _downloadRow(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Icon(
            name.contains('.pdf')
                ? Icons.picture_as_pdf_outlined
                : Icons.insert_drive_file_outlined,
            color: name.contains('.pdf')
                ? const Color(0xFFFF6584)
                : const Color(0xFF6C63FF),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Icon(Icons.download_outlined,
              color: Colors.white.withOpacity(0.3), size: 18),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm, ${_fmt(dt)}';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUBMIT HOMEWORK SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _SubmitHomeworkSheet extends StatefulWidget {
  final _StudentHomework hw;
  final Function(String note, String fileName) onSubmitted;

  const _SubmitHomeworkSheet(
      {required this.hw, required this.onSubmitted});

  @override
  State<_SubmitHomeworkSheet> createState() => _SubmitHomeworkSheetState();
}

class _SubmitHomeworkSheetState extends State<_SubmitHomeworkSheet> {
  final _noteCtrl = TextEditingController();
  String? _pickedFileName;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _pickFile() {
    // TODO: Replace with actual FilePicker
    // FilePickerResult? result = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    // );
    // if (result != null) {
    //   setState(() => _pickedFileName = result.files.single.name);
    // }
    HapticFeedback.lightImpact();
    setState(() =>
    _pickedFileName = 'homework_rahul_sharma.pdf'); // mock
  }

  void _removeFile() => setState(() => _pickedFileName = null);

  Future<void> _submit() async {
    if (_pickedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFFF6584),
        content: const Text('Please attach your homework file first!'),
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    // TODO: Dio multipart upload
    // var dio = Dio();
    // FormData formData = FormData.fromMap({
    //   'file': await MultipartFile.fromFile(filePath, filename: _pickedFileName),
    //   'note': _noteCtrl.text.trim(),
    //   'studentId': currentStudentId,
    // });
    // await dio.post('$BASE_URL/homework/${widget.hw.id}/submit', data: formData);

    await Future.delayed(const Duration(seconds: 2));

    widget.onSubmitted(
        _noteCtrl.text.trim(), _pickedFileName!);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hw = widget.hw;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: hw.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(hw.icon,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submit Homework',
                          style: TextStyle(
                              color: hw.color,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      Text(hw.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                // Due badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: hw.statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                    Border.all(color: hw.statusColor.withOpacity(0.3)),
                  ),
                  child: Text(hw.daysLeft,
                      style: TextStyle(
                          color: hw.statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // File picker area
            GestureDetector(
              onTap: _pickedFileName == null ? _pickFile : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _pickedFileName != null
                      ? hw.color.withOpacity(0.08)
                      : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _pickedFileName != null
                        ? hw.color.withOpacity(0.4)
                        : Colors.white.withOpacity(0.1),
                    width: _pickedFileName != null ? 1.5 : 1,
                    style: _pickedFileName == null
                        ? BorderStyle.solid
                        : BorderStyle.solid,
                  ),
                ),
                child: _pickedFileName == null
                    ? Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        color: Colors.white.withOpacity(0.25),
                        size: 36),
                    const SizedBox(height: 8),
                    Text('Tap to attach your homework',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('PDF, DOC, DOCX, JPG, PNG',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 11)),
                  ],
                )
                    : Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: hw.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _pickedFileName!.contains('.pdf')
                            ? Icons.picture_as_pdf_outlined
                            : Icons.insert_drive_file_outlined,
                        color: hw.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_pickedFileName!,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('Ready to submit',
                              style: TextStyle(
                                  color: hw.color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _removeFile,
                      child: Icon(Icons.close,
                          color: Colors.white.withOpacity(0.3),
                          size: 20),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Optional note
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Add a note to your teacher (optional)...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.2), fontSize: 14),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                  BorderSide(color: hw.color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 20),

            // Submit button
            GestureDetector(
              onTap: _isSubmitting ? null : _submit,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 54,
                decoration: BoxDecoration(
                  gradient: _pickedFileName == null
                      ? const LinearGradient(
                      colors: [Colors.grey, Colors.grey])
                      : LinearGradient(
                      colors: [hw.color, hw.color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _pickedFileName == null
                      ? []
                      : [
                    BoxShadow(
                        color: hw.color.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _pickedFileName != null
                            ? Icons.send_outlined
                            : Icons.attach_file,
                        color: Colors.white, size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _pickedFileName == null
                            ? 'Attach a file to submit'
                            : 'Submit to ${hw.teacherName}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// BACKGROUND PAINTER
// ═══════════════════════════════════════════════════════════════════════════════

class _HwBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    p.color = const Color(0xFF00C6FF).withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.1), 170, p);
    p.color = const Color(0xFFFFB347).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.55), 140, p);
    p.color = const Color(0xFF6C63FF).withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.6, size.height * 0.88), 110, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}