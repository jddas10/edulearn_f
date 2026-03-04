import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../auth/api_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class HomeworkItem {
  final int    id;
  final String title;
  final String description;
  final int    classId;
  final String className;
  final String subject;
  final Color  subjectColor;
  final String subjectIcon;
  final DateTime dueDate;
  final DateTime createdAt;
  final int    totalStudents;
  final int    submitted;
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
    required this.subjectIcon,
    required this.dueDate,
    required this.createdAt,
    required this.totalStudents,
    required this.submitted,
    required this.attachments,
    required this.status,
  });

  double get submissionRate =>
      totalStudents == 0 ? 0 : submitted / totalStudents;
  bool get isOverdue  => DateTime.now().isAfter(dueDate);
  bool get isDueSoon  =>
      !isOverdue && dueDate.difference(DateTime.now()).inHours < 24;
}

class TeacherClassInfo {
  final int    id;
  final String name;
  final String subject;
  final String icon;
  final Color  color;
  final int    studentCount;

  TeacherClassInfo({
    required this.id,
    required this.name,
    required this.subject,
    required this.icon,
    required this.color,
    required this.studentCount,
  });
}

// ─── helpers ─────────────────────────────────────────────────────────────────

const _kColors = [
  Color(0xFF6C63FF), Color(0xFF00D4AA), Color(0xFFFF6584),
  Color(0xFFFFB347), Color(0xFF00D4FF), Color(0xFFFF8C42),
];

Color _hexColor(String? hex, int idx) {
  if (hex != null && hex.startsWith('#') && hex.length == 7) {
    try { return Color(int.parse('FF${hex.substring(1)}', radix: 16)); }
    catch (_) {}
  }
  return _kColors[idx % _kColors.length];
}

String _fmtDate(DateTime dt) {
  const m = ['Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${dt.day} ${m[dt.month-1]}, ${dt.year}';
}

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
  late TabController      _tabController;
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late Animation<double>   _headerAnim;

  int _selectedTab = 0;

  List<HomeworkItem>    _homeworks = [];
  List<TeacherClassInfo> _classes  = [];
  bool _loadingHw      = true;
  bool _loadingClasses = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(
            () => setState(() => _selectedTab = _tabController.index));

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _headerAnim =
        CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);

    _headerCtrl.forward();
    Future.delayed(
        const Duration(milliseconds: 300), () => _listCtrl.forward());

    _fetchHomeworks();
    _fetchClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  // ── API ─────────────────────────────────────────────────────────────────────

  Future<void> _fetchHomeworks() async {
    setState(() => _loadingHw = true);
    try {
      final res = await HomeworkApi.getTeacherHomeworks();
      if (res['success'] == true && mounted) {
        final List raw = res['homeworks'] ?? [];
        setState(() {
          _homeworks = List.generate(raw.length, (i) {
            final h = raw[i];
            return HomeworkItem(
              id:           h['id'] as int,
              title:        h['title'] ?? '',
              description:  h['description'] ?? '',
              classId:      h['class_id'] as int? ?? 0,
              className:    h['class_name'] ?? '',
              subject:      h['subject'] ?? '',
              subjectColor: _hexColor(h['subject_color'], i),
              subjectIcon:  h['icon'] ?? '📚',
              dueDate:      DateTime.parse(h['due_date']),
              createdAt:    DateTime.parse(h['created_at']),
              totalStudents: h['total_students'] as int? ?? 0,
              submitted:     h['submitted_count'] as int? ?? 0,
              attachments:   List<String>.from(h['attachments'] ?? []),
              status:        h['status'] ?? 'Active',
            );
          });
          _loadingHw = false;
        });
        _listCtrl
          ..reset()
          ..forward();
      } else {
        if (mounted) setState(() => _loadingHw = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingHw = false);
    }
  }

  Future<void> _fetchClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final res = await TeacherApi.getMyClasses();
      if (res['success'] == true && mounted) {
        final List raw = res['classes'] ?? [];
        setState(() {
          _classes = List.generate(raw.length, (i) {
            final c = raw[i];
            return TeacherClassInfo(
              id:           c['id'] as int,
              name:         c['name'] ?? '',
              subject:      c['subject'] ?? '',
              icon:         c['icon'] ?? '📚',
              color:        _hexColor(c['color'], i),
              studentCount: c['student_count'] as int? ?? 0,
            );
          });
          _loadingClasses = false;
        });
      } else {
        if (mounted) setState(() => _loadingClasses = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingClasses = false);
    }
  }

  Future<void> _deleteHomework(HomeworkItem hw) async {
    final res = await HomeworkApi.deleteHomework(hw.id);
    if (res['success'] == true && mounted) {
      setState(() => _homeworks.remove(hw));
      _showSnack('Homework deleted', const Color(0xFFFF6584));
    } else if (mounted) {
      _showSnack(res['message'] ?? 'Delete failed', const Color(0xFFFF6584));
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _HomeworkListTab(
                        homeworks:   _homeworks,
                        isLoading:   _loadingHw,
                        listCtrl:    _listCtrl,
                        onDelete:    _deleteHomework,
                        onRefresh:   _fetchHomeworks,
                      ),
                      _ClassesTab(
                        classes:     _classes,
                        isLoading:   _loadingClasses,
                        listCtrl:    _listCtrl,
                        onRefresh:   _fetchClasses,
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
            right:  24,
            child:  _buildFAB(),
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
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                  ).createShader(b),
                  child: const Text('Homework Hub',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5)),
                ),
                Text('Assign & Track',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 13)),
              ],
            ),
            const Spacer(),
            // Refresh
            GestureDetector(
              onTap: () {
                _fetchHomeworks();
                _fetchClasses();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C6FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF00C6FF).withOpacity(0.25)),
                ),
                child: Row(children: [
                  const Icon(Icons.refresh,
                      color: Color(0xFF00C6FF), size: 14),
                  const SizedBox(width: 5),
                  Text('${_homeworks.length} HW',
                      style: const TextStyle(
                          color: Color(0xFF00C6FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ]),
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
            gradient: const LinearGradient(
                colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
            borderRadius: BorderRadius.circular(11),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Homeworks (${_homeworks.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Classes (${_classes.length})'),
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
      onTap: _classes.isEmpty
          ? () => _showSnack(
          'No classes found. Add classes from Admin panel.',
          const Color(0xFFFFB347))
          : () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _SendHomeworkSheet(
            classes: _classes,
            onSent: () => _fetchHomeworks(),
          ),
        );
      },
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0072FF).withOpacity(0.45),
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
            Text('Assign Homework',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — HOMEWORK LIST
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeworkListTab extends StatefulWidget {
  final List<HomeworkItem>  homeworks;
  final bool                isLoading;
  final AnimationController listCtrl;
  final Function(HomeworkItem) onDelete;
  final Future<void> Function() onRefresh;

  const _HomeworkListTab({
    required this.homeworks,
    required this.isLoading,
    required this.listCtrl,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  State<_HomeworkListTab> createState() => _HomeworkListTabState();
}

class _HomeworkListTabState extends State<_HomeworkListTab> {
  String _filter = 'All';

  List<HomeworkItem> get _filtered {
    switch (_filter) {
      case 'Active':
        return widget.homeworks.where((h) => !h.isOverdue).toList();
      case 'Overdue':
        return widget.homeworks.where((h) => h.isOverdue).toList();
      case 'Done':
        return widget.homeworks
            .where((h) => h.submitted == h.totalStudents)
            .toList();
      default:
        return widget.homeworks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(
          child: widget.isLoading
              ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF00C6FF)))
              : _filtered.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: const Color(0xFF00C6FF),
            backgroundColor: const Color(0xFF131929),
            child: ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(20, 8, 20, 120),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                return AnimatedBuilder(
                  animation: widget.listCtrl,
                  builder: (context, child) {
                    final delay = i * 0.08;
                    final v = math.max(
                        0.0,
                        math.min(
                            1.0,
                            (widget.listCtrl.value - delay) /
                                (1.0 - delay)));
                    final c = Curves.easeOutCubic
                        .transform(v.clamp(0.0, 1.0));
                    return Opacity(
                      opacity: v.clamp(0.0, 1.0),
                      child: Transform.translate(
                          offset: Offset(0, 30 * (1 - c)),
                          child: child),
                    );
                  },
                  child: _HomeworkCard(
                    hw:       _filtered[i],
                    onDelete: () =>
                        widget.onDelete(_filtered[i]),
                  ),
                );
              },
            ),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)])
                      : null,
                  color: selected
                      ? null
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(f,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
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
          const Text('📭', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text('No homeworks here',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
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
          border:
          Border.all(color: hw.subjectColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: hw.subjectColor.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  hw.subjectColor,
                  hw.subjectColor.withOpacity(0.3)
                ]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: hw.subjectColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                            hw.subject.isNotEmpty
                                ? hw.subject
                                .substring(
                                0,
                                math.min(
                                    3,
                                    hw.subject.length))
                                .toUpperCase()
                                : 'HW',
                            style: TextStyle(
                                color: hw.subjectColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(hw.className,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: dueBadgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: dueBadgeColor.withOpacity(0.3)),
                        ),
                        child: Text(dueText,
                            style: TextStyle(
                                color: dueBadgeColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(hw.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3)),
                  const SizedBox(height: 4),
                  Text(hw.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 14),
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
                  // Submission progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(
                                  '${hw.submitted}/${hw.totalStudents} submitted',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.6),
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w600)),
                              const Spacer(),
                              Text(
                                  '${(hw.submissionRate * 100).toInt()}%',
                                  style: TextStyle(
                                      color: hw.subjectColor,
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight.w800)),
                            ]),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius:
                              BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: hw.submissionRate,
                                backgroundColor:
                                Colors.white.withOpacity(0.06),
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                    hw.subjectColor),
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20)),
                border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: Colors.white.withOpacity(0.3),
                      size: 13),
                  const SizedBox(width: 5),
                  Text(_fmtDate(hw.dueDate),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12)),
                  const SizedBox(width: 14),
                  if (pending > 0) ...[
                    Icon(Icons.pending_outlined,
                        color: const Color(0xFFFFB347), size: 13),
                    const SizedBox(width: 4),
                    Text('$pending pending',
                        style: const TextStyle(
                            color: Color(0xFFFFB347),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ] else ...[
                    const Icon(Icons.check_circle,
                        color: Color(0xFF00D4AA), size: 13),
                    const SizedBox(width: 4),
                    const Text('All submitted',
                        style: TextStyle(
                            color: Color(0xFF00D4AA),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showSubmissionSheet(context),
                    child: Text('View →',
                        style: TextStyle(
                            color: hw.subjectColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: onDelete,
                    child: Icon(Icons.delete_outline,
                        color: Colors.white.withOpacity(0.2),
                        size: 18),
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
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file,
              color: Colors.white.withOpacity(0.4), size: 12),
          const SizedBox(width: 4),
          Text(name,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11)),
        ],
      ),
    );
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
// SUBMISSION DETAIL SHEET  (with real API)
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

  List<Map<String, dynamic>> _submitted = [];
  List<Map<String, dynamic>> _pending   = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _tabIdx = _tab.index));
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() => _loading = true);
    try {
      final res = await HomeworkApi.getSubmissions(widget.hw.id);
      if (res['success'] == true && mounted) {
        setState(() {
          _submitted = List<Map<String, dynamic>>.from(
              res['submitted'] ?? []);
          _pending = List<Map<String, dynamic>>.from(
              res['pending'] ?? []);
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
      maxChildSize:     0.92,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Container(
                  width: 40,
                  height: 4,
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
                    child: Center(
                        child: Text(hw.subjectIcon,
                            style: const TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(hw.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(hw.className,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          '${(hw.submissionRate * 100).toInt()}%',
                          style: TextStyle(
                              color: hw.subjectColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900)),
                      Text('submitted',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                    border: Border.all(
                        color: hw.subjectColor.withOpacity(0.5)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: hw.subjectColor,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12),
                  tabs: [
                    Tab(text: '✓ Submitted (${_submitted.length})'),
                    Tab(text: '⏳ Pending (${_pending.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF00C6FF)))
                  : TabBarView(
                controller: _tab,
                children: [
                  _studentList(
                      _submitted,
                      const Color(0xFF00D4AA),
                      true),
                  _studentList(
                      _pending,
                      const Color(0xFFFFB347),
                      false),
                ],
              ),
            ),
            // Reminder button
            if (_tabIdx == 1 && _pending.isNotEmpty)
              Padding(
                padding:
                const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(
                      backgroundColor: const Color(0xFFFFB347),
                      content: Text(
                          '🔔 Reminder sent to ${_pending.length} students!'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ));
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFFFB347),
                        Color(0xFFFF8C42)
                      ]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFFFB347)
                                .withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 18),
                        const SizedBox(width: 8),
                        Text(
                            'Send Reminder to ${_pending.length} Students',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14)),
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

  Widget _studentList(List<Map<String, dynamic>> list,
      Color color, bool isSubmitted) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isSubmitted ? 'No submissions yet' : 'Everyone submitted! 🎉',
          style: TextStyle(
              color: Colors.white.withOpacity(0.4), fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final s = list[i];
        final name = s['name'] ?? s['username'] ?? '—';
        final initials = name
            .split(' ')
            .map<String>((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase();
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                    child: Text(initials,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (isSubmitted &&
                        s['submitted_at'] != null)
                      Text(
                          _fmtDate(DateTime.parse(
                              s['submitted_at'])),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11)),
                  ],
                ),
              ),
              Icon(
                isSubmitted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: color,
                size: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — CLASSES (read-only from API)
// ═══════════════════════════════════════════════════════════════════════════════

class _ClassesTab extends StatelessWidget {
  final List<TeacherClassInfo> classes;
  final bool                   isLoading;
  final AnimationController    listCtrl;
  final Future<void> Function() onRefresh;

  const _ClassesTab({
    required this.classes,
    required this.isLoading,
    required this.listCtrl,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
          child:
          CircularProgressIndicator(color: Color(0xFF00C6FF)));
    }
    if (classes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏫', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('No classes yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Ask Admin to create a class for you',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF00C6FF),
      backgroundColor: const Color(0xFF131929),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
        itemCount: classes.length,
        itemBuilder: (context, i) {
          return AnimatedBuilder(
            animation: listCtrl,
            builder: (_, child) {
              final delay = i * 0.1;
              final v = math.max(
                  0.0,
                  math.min(
                      1.0,
                      (listCtrl.value - delay) /
                          (1.0 - delay)));
              final c =
              Curves.easeOutCubic.transform(v.clamp(0.0, 1.0));
              return Opacity(
                opacity: v.clamp(0.0, 1.0),
                child: Transform.translate(
                    offset: Offset(0, 25 * (1 - c)),
                    child: child),
              );
            },
            child: _ClassCard(cls: classes[i]),
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final TeacherClassInfo cls;
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
          BoxShadow(
              color: cls.color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [cls.color, cls.color.withOpacity(0.3)]),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: cls.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                      child: Text(cls.icon,
                          style: const TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                      Text(cls.subject,
                          style: TextStyle(
                              color: cls.color, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${cls.studentCount}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    Text('students',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 11)),
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
// SEND HOMEWORK SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _SendHomeworkSheet extends StatefulWidget {
  final List<TeacherClassInfo> classes;
  final VoidCallback           onSent;

  const _SendHomeworkSheet(
      {required this.classes, required this.onSent});

  @override
  State<_SendHomeworkSheet> createState() => _SendHomeworkSheetState();
}

class _SendHomeworkSheetState extends State<_SendHomeworkSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  TeacherClassInfo? _selectedClass;
  DateTime?         _dueDate;
  final List<String> _attachmentPaths = []; // real file paths
  final List<String> _attachmentNames = []; // display names
  bool _isSending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _pickFile() {
    // TODO: Replace with actual FilePicker
    // FilePickerResult? result = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    // );
    // if (result != null && result.files.single.path != null) {
    //   setState(() {
    //     _attachmentPaths.add(result.files.single.path!);
    //     _attachmentNames.add(result.files.single.name);
    //   });
    // }
    HapticFeedback.lightImpact();
    setState(() {
      _attachmentPaths.add('/mock/document.pdf');
      _attachmentNames.add('document.pdf');
    });
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _selectedClass == null) return;
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFFF6584),
        content: const Text('Please set a due date!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _isSending = true);
    HapticFeedback.heavyImpact();

    final res = await HomeworkApi.createHomework(
      classId:     _selectedClass!.id,
      title:       _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      dueDate:
      '${_dueDate!.toIso8601String().split('T')[0]} 23:59:00',
      filePaths: _attachmentPaths,
    );

    if (mounted) setState(() => _isSending = false);

    if (res['success'] == true && mounted) {
      widget.onSent();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF00D4AA),
        content: Text(
            '✓ Homework assigned to ${_selectedClass!.name}! 🔔 ${_selectedClass!.studentCount} students notified'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFFF6584),
        content: Text(res['message'] ?? 'Failed to assign homework'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize:     0.95,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) =>
                            const LinearGradient(colors: [
                              Color(0xFF00C6FF),
                              Color(0xFF0072FF)
                            ]).createShader(b),
                        child: const Text('Assign Homework',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900)),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close,
                            color: Colors.white.withOpacity(0.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '🔔 Notification sent ONLY to selected class',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scroll,
                padding:
                const EdgeInsets.fromLTRB(24, 0, 24, 120),
                children: [
                  // Select Class
                  _label('1. SELECT CLASS'),
                  const SizedBox(height: 10),
                  ...widget.classes.map((cls) => GestureDetector(
                    onTap: () =>
                        setState(() => _selectedClass = cls),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedClass?.id == cls.id
                            ? cls.color.withOpacity(0.1)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedClass?.id == cls.id
                              ? cls.color.withOpacity(0.5)
                              : Colors.white.withOpacity(0.06),
                          width: _selectedClass?.id == cls.id
                              ? 1.5
                              : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(cls.icon,
                              style:
                              const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(cls.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                        FontWeight.w700,
                                        fontSize: 14)),
                                Text(
                                    '${cls.studentCount} students  •  ${cls.subject}',
                                    style: TextStyle(
                                        color: Colors.white
                                            .withOpacity(0.4),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          if (_selectedClass?.id == cls.id)
                            Icon(Icons.check_circle,
                                color: cls.color, size: 22)
                          else
                            Icon(Icons.radio_button_unchecked,
                                color:
                                Colors.white.withOpacity(0.2),
                                size: 22),
                        ],
                      ),
                    ),
                  )),

                  if (_selectedClass != null) ...[
                    const SizedBox(height: 20),
                    _label('2. HOMEWORK DETAILS'),
                    const SizedBox(height: 10),
                    _hwField(_titleCtrl, 'Homework Title',
                        Icons.title,
                        onChanged: (_) => setState(() {})),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 4,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Instructions...',
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 14),
                        filled: true,
                        fillColor:
                        Colors.white.withOpacity(0.04),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF00C6FF),
                              width: 1.5),
                        ),
                        contentPadding:
                        const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('3. DUE DATE'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final p = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now()
                              .add(const Duration(days: 3)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 90)),
                          builder: (ctx, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme:
                              const ColorScheme.dark(
                                primary: Color(0xFF00C6FF),
                                surface: Color(0xFF131929),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (p != null)
                          setState(() => _dueDate = p);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _dueDate != null
                              ? const Color(0xFF00C6FF)
                              .withOpacity(0.08)
                              : Colors.white.withOpacity(0.04),
                          borderRadius:
                          BorderRadius.circular(14),
                          border: Border.all(
                            color: _dueDate != null
                                ? const Color(0xFF00C6FF)
                                .withOpacity(0.4)
                                : Colors.white
                                .withOpacity(0.08),
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                              Icons.calendar_today_outlined,
                              color: _dueDate != null
                                  ? const Color(0xFF00C6FF)
                                  : Colors.white
                                  .withOpacity(0.3),
                              size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _dueDate == null
                                ? 'Set due date'
                                : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                            style: TextStyle(
                              color: _dueDate != null
                                  ? const Color(0xFF00C6FF)
                                  : Colors.white
                                  .withOpacity(0.3),
                              fontWeight: _dueDate != null
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('4. ATTACHMENTS (OPTIONAL)'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius:
                          BorderRadius.circular(12),
                          border: Border.all(
                              color:
                              Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_file,
                                color: const Color(0xFF00C6FF)
                                    .withOpacity(0.7),
                                size: 18),
                            const SizedBox(width: 8),
                            Text('Attach File',
                                style: TextStyle(
                                    color: const Color(0xFF00C6FF)
                                        .withOpacity(0.7),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    if (_attachmentNames.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _attachmentNames
                            .asMap()
                            .entries
                            .map((e) => Container(
                          padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.06),
                            borderRadius:
                            BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white
                                    .withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_file,
                                  color: Colors.white
                                      .withOpacity(0.4),
                                  size: 13),
                              const SizedBox(width: 4),
                              Text(e.value,
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.6),
                                      fontSize: 12)),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => setState(() {
                                  _attachmentPaths
                                      .removeAt(e.key);
                                  _attachmentNames
                                      .removeAt(e.key);
                                }),
                                child: Icon(Icons.close,
                                    color: Colors.white
                                        .withOpacity(0.3),
                                    size: 14),
                              ),
                            ],
                          ),
                        ))
                            .toList(),
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
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withOpacity(0.06))),
                ),
                child: GestureDetector(
                  onTap: (_titleCtrl.text.trim().isEmpty ||
                      _isSending)
                      ? null
                      : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _titleCtrl.text.trim().isEmpty
                          ? const LinearGradient(
                          colors: [Colors.grey, Colors.grey])
                          : const LinearGradient(colors: [
                        Color(0xFF00C6FF),
                        Color(0xFF0072FF)
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow:
                      _titleCtrl.text.trim().isEmpty
                          ? []
                          : [
                        BoxShadow(
                            color: const Color(0xFF0072FF)
                                .withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2))
                          : Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_outlined,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            _titleCtrl.text.trim().isEmpty
                                ? 'Enter title first'
                                : 'Send to ${_selectedClass!.studentCount} Students 🔔',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14),
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

  Widget _label(String text) => Text(text,
      style: TextStyle(
          color: const Color(0xFF00C6FF).withOpacity(0.7),
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2));

  Widget _hwField(TextEditingController ctrl, String hint,
      IconData icon,
      {Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.25), fontSize: 15),
        prefixIcon: Icon(icon,
            color: const Color(0xFF00C6FF).withOpacity(0.6),
            size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFF00C6FF), width: 1.5)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
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
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.1), 170, p);
    p.color = const Color(0xFF0072FF).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.55), 140, p);
    p.color = const Color(0xFF00D4AA).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.88), 110, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}