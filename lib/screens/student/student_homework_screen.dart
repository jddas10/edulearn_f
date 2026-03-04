import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../auth/session_store_api2.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════════════════════════════════════

class _StudentHomework {
  final int    id;
  final String title;
  final String description;
  final String subject;
  final String className;
  final Color  color;
  final String icon;
  final DateTime dueDate;
  final DateTime createdAt;
  final List<String> attachments;
  bool     isSubmitted;
  String?  submittedNote;
  String?  submittedFileName;
  DateTime? submittedAt;

  _StudentHomework({
    required this.id,
    required this.title,
    required this.description,
    required this.subject,
    required this.className,
    required this.color,
    required this.icon,
    required this.dueDate,
    required this.createdAt,
    required this.attachments,
    this.isSubmitted      = false,
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
    if (isOverdue)   return 'Overdue';
    if (isDueSoon)   return 'Due Soon';
    return 'Pending';
  }

  Color get statusColor {
    if (isSubmitted) return const Color(0xFF00D4AA);
    if (isOverdue)   return const Color(0xFFFF6584);
    if (isDueSoon)   return const Color(0xFFFFB347);
    return const Color(0xFF6C63FF);
  }

  IconData get statusIcon {
    if (isSubmitted) return Icons.check_circle;
    if (isOverdue)   return Icons.cancel_outlined;
    if (isDueSoon)   return Icons.timer_outlined;
    return Icons.radio_button_unchecked;
  }

  String get daysLeft {
    if (isSubmitted) return 'Done ✓';
    final diff = dueDate.difference(DateTime.now());
    if (diff.isNegative) {
      return '${diff.inDays.abs()}d overdue';
    }
    if (diff.inHours < 24) return '${diff.inHours}h left';
    return '${diff.inDays}d left';
  }
}

// ─── helpers ──────────────────────────────────────────────────────────────────

const _kColors = [
  Color(0xFF6C63FF), Color(0xFF00D4AA), Color(0xFFFF6584),
  Color(0xFFFFB347), Color(0xFF00D4FF), Color(0xFFFF8C42),
];

Color _hexColor(String? hex, int idx) {
  if (hex != null && hex.startsWith('#') && hex.length == 7) {
    try {
      return Color(int.parse('FF${hex.substring(1)}', radix: 16));
    } catch (_) {}
  }
  return _kColors[idx % _kColors.length];
}

String _fmtDate(DateTime dt) {
  const m = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${dt.day} ${m[dt.month - 1]}, ${dt.year}';
}

String _fmtTime(DateTime dt) {
  final h    = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final min  = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  return '$h:$min $ampm, ${_fmtDate(dt)}';
}

// ═══════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════════

class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({super.key});

  @override
  State<StudentHomeworkScreen> createState() =>
      _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState
    extends State<StudentHomeworkScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late Animation<double>   _headerAnim;

  int _selectedFilter = 0;
  final List<String> _filters = [
    'All', 'Pending', 'Submitted', 'Overdue'
  ];

  List<_StudentHomework> _homeworks = [];
  bool _isLoading = true;

  // ── counts ──────────────────────────────────────────────────────────────────
  int get _pendingCount =>
      _homeworks.where((h) => !h.isSubmitted && !h.isOverdue).length;
  int get _submittedCount =>
      _homeworks.where((h) => h.isSubmitted).length;
  int get _overdueCount =>
      _homeworks.where((h) => h.isOverdue).length;

  List<_StudentHomework> get _filtered {
    switch (_selectedFilter) {
      case 1:
        return _homeworks
            .where((h) => !h.isSubmitted && !h.isOverdue)
            .toList();
      case 2:
        return _homeworks.where((h) => h.isSubmitted).toList();
      case 3:
        return _homeworks.where((h) => h.isOverdue).toList();
      default:
        final list = List<_StudentHomework>.from(_homeworks);
        list.sort((a, b) {
          int p(_StudentHomework h) {
            if (h.isOverdue)    return 0;
            if (h.isDueSoon)    return 1;
            if (!h.isSubmitted) return 2;
            return 3;
          }
          return p(a).compareTo(p(b));
        });
        return list;
    }
  }

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800));
    _listCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200));
    _headerAnim = CurvedAnimation(
        parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerCtrl.forward();
    _fetchHomeworks();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  // ── API ─────────────────────────────────────────────────────────────────────

  Future<void> _fetchHomeworks() async {
    setState(() => _isLoading = true);
    try {
      final res = await HomeworkApi.getStudentHomeworks();
      if (res['success'] == true && mounted) {
        final List raw = res['homeworks'] ?? [];
        setState(() {
          _homeworks = List.generate(raw.length, (i) {
            final h = raw[i];

            // attachments can be List<String> or List<Map>
            List<String> attachments = [];
            final rawAtt = h['attachments'];
            if (rawAtt is List) {
              for (final a in rawAtt) {
                if (a is String) {
                  attachments.add(a);
                } else if (a is Map) {
                  attachments.add(
                      (a['file_name'] ?? '').toString());
                }
              }
            }

            return _StudentHomework(
              id:          h['id'] as int,
              title:       h['title'] ?? '',
              description: h['description'] ?? '',
              subject:     h['subject'] ?? '',
              className:   h['class_name'] ?? '',
              color:       _hexColor(h['subject_color'], i),
              icon:        h['icon'] ?? '📚',
              dueDate:     DateTime.parse(h['due_date']),
              createdAt:   DateTime.parse(h['created_at']),
              attachments: attachments,
              isSubmitted:
              h['submission_id'] != null,
              submittedNote:
              h['submitted_note']?.toString(),
              submittedFileName:
              h['submitted_file']?.toString(),
              submittedAt: h['submitted_at'] != null
                  ? DateTime.tryParse(
                  h['submitted_at'].toString())
                  : null,
            );
          });
          _isLoading = false;
        });
        Future.delayed(
          const Duration(milliseconds: 200),
              () {
            if (mounted) {
              _listCtrl
                ..reset()
                ..forward();
            }
          },
        );
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(painter: _HwBgPainter())),
          SafeArea(
            child: FadeTransition(
              opacity: _headerAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  _buildSummaryRow(),
                  _buildFilterTabs(),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
          ),
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
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1)),
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
                  colors: [
                    Color(0xFF00C6FF),
                    Color(0xFFFFB347)
                  ],
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
                'Your class assignments',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              _listCtrl.reset();
              _fetchHomeworks();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB347).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFFB347)
                        .withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.refresh,
                    color: Color(0xFFFFB347), size: 14),
                const SizedBox(width: 5),
                Text(
                  '$_pendingCount due',
                  style: const TextStyle(
                    color: Color(0xFFFFB347),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Row ──────────────────────────────────────────────────────────────

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            const Color(0xFF00C6FF).withOpacity(0.1),
            const Color(0xFF0072FF).withOpacity(0.05),
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF00C6FF).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            _sumItem(
              '${_homeworks.length}',
              'Total',
              const Color(0xFF00C6FF),
            ),
            _sumDiv(),
            _sumItem(
              '$_pendingCount',
              'Pending',
              const Color(0xFF6C63FF),
            ),
            _sumDiv(),
            _sumItem(
              '$_submittedCount',
              'Submitted',
              const Color(0xFF00D4AA),
            ),
            _sumDiv(),
            _sumItem(
              '$_overdueCount',
              'Overdue',
              const Color(0xFFFF6584),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sumItem(String value, String label, Color color) {
    return Expanded(
      child: Column(children: [
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            )),
      ]),
    );
  }

  Widget _sumDiv() => Container(
    width: 1,
    height: 34,
    color: Colors.white.withOpacity(0.08),
  );

  // ── Filter Tabs ──────────────────────────────────────────────────────────────

  Widget _buildFilterTabs() {
    final counts = [
      _homeworks.length,
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
                      ? const LinearGradient(colors: [
                    Color(0xFF00C6FF),
                    Color(0xFF0072FF),
                  ])
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
                child: Row(children: [
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
                        borderRadius:
                        BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${counts[i]}',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Homework List ─────────────────────────────────────────────────────────────

  Widget _buildList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF00C6FF)));
    }

    final list = _filtered;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉',
                style: TextStyle(fontSize: 56)),
            const SizedBox(height: 14),
            Text(
              _selectedFilter == 2
                  ? 'Nothing submitted yet'
                  : 'All clear! No homework here',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHomeworks,
      color: const Color(0xFF00C6FF),
      backgroundColor: const Color(0xFF131929),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        itemCount: list.length,
        itemBuilder: (context, i) {
          return AnimatedBuilder(
            animation: _listCtrl,
            builder: (ctx, child) {
              final delay = i * 0.1;
              final v = math.max(
                0.0,
                math.min(
                  1.0,
                  (_listCtrl.value - delay) / (1.0 - delay),
                ),
              );
              final curve = Curves.easeOutCubic
                  .transform(v.clamp(0.0, 1.0));
              return Opacity(
                opacity: curve,
                child: Transform.translate(
                    offset: Offset(0, 32 * (1 - curve)),
                    child: child),
              );
            },
            child: _HomeworkCard(
              hw:       list[i],
              onSubmit: () => _showSubmitSheet(list[i]),
              onTap:    () => _showDetail(list[i]),
            ),
          );
        },
      ),
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
            hw.isSubmitted       = true;
            hw.submittedNote     = note;
            hw.submittedFileName = fileName;
            hw.submittedAt       = DateTime.now();
          });
          _showSnack(
            '✓ "${hw.title}" submitted!',
            const Color(0xFF00D4AA),
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
  final VoidCallback     onSubmit;
  final VoidCallback     onTap;

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
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          color: hw.color.withOpacity(0.12),
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        child: Center(
                            child: Text(hw.icon,
                                style: const TextStyle(
                                    fontSize: 22))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              hw.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(children: [
                              Text(hw.subject,
                                  style: TextStyle(
                                    color: hw.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  )),
                              Text(' • ',
                                  style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(0.2),
                                      fontSize: 12)),
                              Expanded(
                                child: Text(
                                  hw.className,
                                  style: TextStyle(
                                    color: Colors.white
                                        .withOpacity(0.4),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: hw.statusColor.withOpacity(0.12),
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                              color: hw.statusColor
                                  .withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(hw.statusIcon,
                                color: hw.statusColor,
                                size: 10),
                            const SizedBox(width: 4),
                            Text(hw.statusLabel,
                                style: TextStyle(
                                  color: hw.statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                )),
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
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Attachments from teacher
                  if (hw.attachments.isNotEmpty) ...[
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: hw.attachments
                          .map((a) => _attachChip(a))
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Submitted file chip
                  if (hw.isSubmitted &&
                      hw.submittedFileName != null &&
                      hw.submittedFileName!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA)
                            .withOpacity(0.08),
                        borderRadius:
                        BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF00D4AA)
                                .withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF00D4AA),
                            size: 14),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Submitted: ${hw.submittedFileName}',
                            style: const TextStyle(
                              color: Color(0xFF00D4AA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Bottom row
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: Colors.white.withOpacity(0.3),
                          size: 12),
                      const SizedBox(width: 5),
                      Text(_fmtDate(hw.dueDate),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          )),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                          hw.statusColor.withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Text(hw.daysLeft,
                            style: TextStyle(
                              color: hw.statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            )),
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
                              borderRadius:
                              BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: hw.color
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Row(children: [
                              Icon(Icons.upload_outlined,
                                  color: Colors.white,
                                  size: 14),
                              SizedBox(width: 5),
                              Text('Submit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  )),
                            ]),
                          ),
                        )
                      else if (hw.isOverdue)
                        Row(children: [
                          const Icon(Icons.lock_outline,
                              color: Color(0xFFFF6584),
                              size: 14),
                          const SizedBox(width: 4),
                          Text('Closed',
                              style: TextStyle(
                                color: const Color(0xFFFF6584)
                                    .withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              )),
                        ])
                      else
                        const Row(children: [
                          Icon(Icons.check_circle,
                              color: Color(0xFF00D4AA),
                              size: 14),
                          SizedBox(width: 4),
                          Text('Done',
                              style: TextStyle(
                                color: Color(0xFF00D4AA),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              )),
                        ]),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right,
                          color: Colors.white.withOpacity(0.2),
                          size: 18),
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
    final isPdf = name.toLowerCase().contains('.pdf');
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border:
        Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isPdf
              ? Icons.picture_as_pdf_outlined
              : Icons.attach_file,
          color: isPdf
              ? const Color(0xFFFF6584).withOpacity(0.7)
              : Colors.white.withOpacity(0.4),
          size: 12,
        ),
        const SizedBox(width: 4),
        Text(name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DETAIL SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeworkDetailSheet extends StatelessWidget {
  final _StudentHomework hw;
  final VoidCallback     onSubmitTap;

  const _HomeworkDetailSheet({
    required this.hw,
    required this.onSubmitTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize:     0.94,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(
                    top: 12, bottom: 20),
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
                padding: const EdgeInsets.fromLTRB(
                    24, 0, 24, 40),
                children: [
                  // Subject row
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54, height: 54,
                        decoration: BoxDecoration(
                          color: hw.color.withOpacity(0.15),
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                        child: Center(
                            child: Text(hw.icon,
                                style: const TextStyle(
                                    fontSize: 28))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(hw.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                  height: 1.3,
                                )),
                            const SizedBox(height: 4),
                            Text(
                              '${hw.subject} • ${hw.className}',
                              style: TextStyle(
                                color: hw.color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Status card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hw.statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: hw.statusColor
                              .withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Icon(hw.statusIcon,
                          color: hw.statusColor, size: 26),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(hw.statusLabel,
                              style: TextStyle(
                                color: hw.statusColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              )),
                          Text(
                            hw.isSubmitted &&
                                hw.submittedAt != null
                                ? 'Submitted on ${_fmtDate(hw.submittedAt!)}'
                                : 'Due: ${_fmtDate(hw.dueDate)}',
                            style: TextStyle(
                              color:
                              Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: hw.statusColor.withOpacity(0.15),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Text(hw.daysLeft,
                            style: TextStyle(
                              color: hw.statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            )),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  _secLabel('INSTRUCTIONS'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                          Colors.white.withOpacity(0.06)),
                    ),
                    child: Text(hw.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 14,
                          height: 1.6,
                        )),
                  ),
                  // Teacher attachments
                  if (hw.attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _secLabel("TEACHER'S ATTACHMENTS"),
                    const SizedBox(height: 8),
                    ...hw.attachments.map(
                            (a) => _downloadRow(a)),
                  ],
                  // My submission
                  if (hw.isSubmitted) ...[
                    const SizedBox(height: 16),
                    _secLabel('YOUR SUBMISSION'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4AA)
                            .withOpacity(0.08),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFF00D4AA)
                                .withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.check_circle,
                                color: Color(0xFF00D4AA),
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hw.submittedFileName != null &&
                                    hw.submittedFileName!
                                        .isNotEmpty
                                    ? hw.submittedFileName!
                                    : 'Note submitted',
                                style: const TextStyle(
                                  color: Color(0xFF00D4AA),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                            ),
                          ]),
                          if (hw.submittedNote != null &&
                              hw.submittedNote!
                                  .isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('"${hw.submittedNote}"',
                                style: TextStyle(
                                  color: Colors.white
                                      .withOpacity(0.5),
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                )),
                          ],
                          if (hw.submittedAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Submitted at ${_fmtTime(hw.submittedAt!)}',
                              style: TextStyle(
                                color: Colors.white
                                    .withOpacity(0.35),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!hw.isSubmitted && !hw.isOverdue)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    24, 12, 24, 36),
                child: GestureDetector(
                  onTap: onSubmitTap,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        hw.color,
                        hw.color.withOpacity(0.7),
                      ]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: hw.color.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_outlined,
                            color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text('Submit Homework',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            )),
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

  Widget _secLabel(String l) => Text(l,
      style: TextStyle(
        color: Colors.white.withOpacity(0.35),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ));

  Widget _downloadRow(String name) {
    final isPdf = name.toLowerCase().contains('.pdf');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Icon(
          isPdf
              ? Icons.picture_as_pdf_outlined
              : Icons.insert_drive_file_outlined,
          color: isPdf
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
                fontWeight: FontWeight.w500,
              )),
        ),
        Icon(Icons.download_outlined,
            color: Colors.white.withOpacity(0.3), size: 18),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUBMIT SHEET
// ═══════════════════════════════════════════════════════════════════════════════

class _SubmitHomeworkSheet extends StatefulWidget {
  final _StudentHomework                       hw;
  final Function(String note, String fileName) onSubmitted;

  const _SubmitHomeworkSheet({
    required this.hw,
    required this.onSubmitted,
  });

  @override
  State<_SubmitHomeworkSheet> createState() =>
      _SubmitHomeworkSheetState();
}

class _SubmitHomeworkSheetState
    extends State<_SubmitHomeworkSheet> {
  final _noteCtrl = TextEditingController();
  String? _pickedFilePath;
  String? _pickedFileName;
  bool    _isSubmitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _pickFile() {
    // TODO: Replace with actual FilePicker
    // FilePickerResult? result = await FilePicker.platform.pickFiles(
    //   type: FileType.custom,
    //   allowedExtensions: ['pdf','doc','docx','jpg','png'],
    // );
    // if (result != null && result.files.single.path != null) {
    //   setState(() {
    //     _pickedFilePath = result.files.single.path;
    //     _pickedFileName = result.files.single.name;
    //   });
    // }
    HapticFeedback.lightImpact();
    setState(() {
      _pickedFilePath = '/mock/homework_student.pdf';
      _pickedFileName = 'homework_student.pdf';
    });
  }

  Future<void> _submit() async {
    if (_pickedFilePath == null &&
        _noteCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFFF6584),
        content: const Text(
            'Please attach a file or write a note!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() => _isSubmitting = true);
    HapticFeedback.heavyImpact();

    final res = await HomeworkApi.submitHomework(
      homeworkId: widget.hw.id,
      note:       _noteCtrl.text.trim(),
      filePath:   _pickedFilePath,
    );

    if (mounted) setState(() => _isSubmitting = false);

    if (res['success'] == true && mounted) {
      widget.onSubmitted(
        _noteCtrl.text.trim(),
        _pickedFileName ?? '',
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFFF6584),
        content: Text(res['message'] ?? 'Submit failed'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ));
    }
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
          borderRadius: BorderRadius.vertical(
              top: Radius.circular(28)),
        ),
        padding:
        const EdgeInsets.fromLTRB(24, 12, 24, 36),
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
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: hw.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                    child: Text(hw.icon,
                        style: const TextStyle(
                            fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text('Submit Homework',
                        style: TextStyle(
                          color: hw.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                    Text(hw.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hw.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: hw.statusColor.withOpacity(0.3)),
                ),
                child: Text(hw.daysLeft,
                    style: TextStyle(
                      color: hw.statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    )),
              ),
            ]),
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
                    width:
                    _pickedFileName != null ? 1.5 : 1,
                  ),
                ),
                child: _pickedFileName == null
                    ? Column(children: [
                  Icon(Icons.cloud_upload_outlined,
                      color:
                      Colors.white.withOpacity(0.25),
                      size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to attach your homework',
                    style: TextStyle(
                      color:
                      Colors.white.withOpacity(0.4),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PDF, DOC, Image supported',
                    style: TextStyle(
                      color:
                      Colors.white.withOpacity(0.25),
                      fontSize: 12,
                    ),
                  ),
                ])
                    : Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: hw.color.withOpacity(0.15),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _pickedFileName!.contains('.pdf')
                          ? Icons.picture_as_pdf_outlined
                          : Icons
                          .insert_drive_file_outlined,
                      color: hw.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(_pickedFileName!,
                            style: TextStyle(
                              color: hw.color,
                              fontWeight:
                              FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis),
                        Text('Ready to submit',
                            style: TextStyle(
                              color: Colors.white
                                  .withOpacity(0.4),
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _pickedFilePath = null;
                      _pickedFileName = null;
                    }),
                    child: Icon(Icons.close,
                        color: Colors.white
                            .withOpacity(0.3),
                        size: 18),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            // Note field
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5),
              decoration: InputDecoration(
                hintText:
                'Add a note for your teacher (optional)...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: hw.color, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
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
                  gradient: LinearGradient(colors: [
                    hw.color,
                    hw.color.withOpacity(0.7),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: hw.color.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2))
                      : const Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_outlined,
                          color: Colors.white,
                          size: 20),
                      SizedBox(width: 10),
                      Text('Submit Homework',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          )),
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
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.1), 160, p);
    p.color = const Color(0xFFFFB347).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.5), 130, p);
    p.color = const Color(0xFF6C63FF).withOpacity(0.04);
    canvas.drawCircle(
        Offset(size.width * 0.6, size.height * 0.85), 110, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      false;
}