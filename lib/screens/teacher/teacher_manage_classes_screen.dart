import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../auth/api_service.dart';

class TeacherManageClassesScreen extends StatefulWidget {
  const TeacherManageClassesScreen({super.key});

  @override
  State<TeacherManageClassesScreen> createState() => _TeacherManageClassesScreenState();
}

class _TeacherManageClassesScreenState extends State<TeacherManageClassesScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late Animation<double> _headerAnim;

  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _allStudents = [];
  bool _isLoading = true;
  int? _teacherId;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerCtrl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _teacherId = await SessionStore.userId;
    final classRes = await AdminApi.getClasses();
    final studentRes = await AdminApi.getUsers(role: 'STUDENT');
    if (mounted) {
      setState(() {
        _classes = classRes['success'] == true
            ? List<Map<String, dynamic>>.from(classRes['classes'] ?? [])
            : [];
        _allStudents = studentRes['success'] == true
            ? List<Map<String, dynamic>>.from(studentRes['users'] ?? [])
            : [];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteClass(int classId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131929),
        title: const Text('Delete Class', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure? This cannot be undone.',
            style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6584))),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final res = await AdminApi.deleteClass(classId);
    if (mounted) {
      if (res['success'] == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Class deleted'),
          backgroundColor: Color(0xFF00D4AA),
          behavior: SnackBarBehavior.floating,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['message'] ?? 'Failed'),
          backgroundColor: const Color(0xFFFF6584),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showCreateOrEditSheet({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClassFormSheet(
        existing: existing,
        allStudents: _allStudents,
        teacherId: _teacherId ?? 0,
        onSaved: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  void _showStudentsSheet(Map<String, dynamic> cls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentsSheet(
        cls: cls,
        allStudents: _allStudents,
        teacherId: _teacherId ?? 0,
        onChanged: _loadData,
      ),
    );
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
                _buildTopBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                      : _classes.isEmpty
                      ? _buildEmpty()
                      : _buildClassList(),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 28,
            right: 24,
            child: GestureDetector(
              onTap: () => _showCreateOrEditSheet(),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF6C63FF)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text('New Class',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return FadeTransition(
      opacity: _headerAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 16),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF6C63FF)],
              ).createShader(b),
              child: const Text(
                'Manage Classes',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.class_outlined, color: Colors.white.withOpacity(0.2), size: 64),
          const SizedBox(height: 16),
          Text('No classes yet',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
          const SizedBox(height: 8),
          Text('Tap + New Class to create one',
              style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF131929),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: _classes.length,
        itemBuilder: (context, i) => _buildClassCard(_classes[i]),
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> cls) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00D4AA),
      const Color(0xFFFF6584),
      const Color(0xFFFFB347),
      const Color(0xFF00D4FF),
    ];
    final color = colors[cls['id'] % colors.length];
    final studentCount = cls['student_count'] ?? 0;

    return GestureDetector(
      onTap: () => _showStudentsSheet(cls),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF131929),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(cls['icon'] ?? '📚', style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls['name'] ?? '',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    '${cls['subject'] ?? ''}  •  $studentCount students',
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _showCreateOrEditSheet(existing: cls),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _deleteClass(cls['id'] as int),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6584).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFFF6584), size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassFormSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final List<Map<String, dynamic>> allStudents;
  final int teacherId;
  final VoidCallback onSaved;

  const _ClassFormSheet({
    required this.allStudents,
    required this.teacherId,
    required this.onSaved,
    this.existing,
  });

  @override
  State<_ClassFormSheet> createState() => _ClassFormSheetState();
}

class _ClassFormSheetState extends State<_ClassFormSheet> {
  final _nameCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  String _searchQuery = '';
  late List<Map<String, dynamic>> _students;
  final Set<int> _selectedIds = {};
  bool _isSaving = false;

  final _icons = ['📚', '🔬', '📐', '🌍', '💻', '🎨', '⚗️', '📖'];
  final _colors = ['#6C63FF', '#00D4AA', '#FF6584', '#FFB347', '#00D4FF'];
  int _selectedIcon = 0;
  int _selectedColor = 0;

  @override
  void initState() {
    super.initState();
    _students = List.from(widget.allStudents);
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameCtrl.text = e['name'] ?? '';
      _subjectCtrl.text = e['subject'] ?? '';
    }
    _loadExistingStudents();
  }

  Future<void> _loadExistingStudents() async {
    if (widget.existing == null) return;
    final classId = widget.existing!['id'] as int;
    final res = await AdminApi.getClasses();
    if (res['success'] == true) {
      final classes = List<Map<String, dynamic>>.from(res['classes'] ?? []);
      final cls = classes.firstWhere((c) => c['id'] == classId, orElse: () => {});
      if (cls.isNotEmpty && cls['students'] != null) {
        final ids = (cls['students'] as List).map((s) => s['id'] as int).toSet();
        if (mounted) setState(() => _selectedIds.addAll(ids));
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) return _students;
    return _students
        .where((s) =>
    (s['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (s['username'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Class name is required'),
        backgroundColor: Color(0xFFFF6584),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isSaving = true);
    Map<String, dynamic> res;
    if (widget.existing == null) {
      res = await AdminApi.createClass(
        name: _nameCtrl.text.trim(),
        teacherId: widget.teacherId,
        subject: _subjectCtrl.text.trim(),
        icon: _icons[_selectedIcon],
        color: _colors[_selectedColor],
        studentIds: _selectedIds.toList(),
      );
    } else {
      res = await AdminApi.updateClass(
        classId: widget.existing!['id'] as int,
        name: _nameCtrl.text.trim(),
        teacherId: widget.teacherId,
        subject: _subjectCtrl.text.trim(),
        icon: _icons[_selectedIcon],
        color: _colors[_selectedColor],
        studentIds: _selectedIds.toList(),
      );
    }
    if (mounted) setState(() => _isSaving = false);
    if (res['success'] == true) {
      widget.onSaved();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Failed'),
        backgroundColor: const Color(0xFFFF6584),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    isEdit ? 'Edit Class' : 'New Class',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _fieldLabel('Class Name *'),
                  const SizedBox(height: 6),
                  _textField(_nameCtrl, 'e.g. 6ITA-1'),
                  const SizedBox(height: 14),
                  _fieldLabel('Subject (optional)'),
                  const SizedBox(height: 6),
                  _textField(_subjectCtrl, 'e.g. Mathematics'),
                  const SizedBox(height: 16),
                  _fieldLabel('Icon'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(_icons.length, (i) => GestureDetector(
                      onTap: () => setState(() => _selectedIcon = i),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _selectedIcon == i
                              ? const Color(0xFF00E5FF).withOpacity(0.15)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedIcon == i
                                ? const Color(0xFF00E5FF)
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                            child: Text(_icons[i], style: const TextStyle(fontSize: 20))),
                      ),
                    )),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('Color'),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(_colors.length, (i) {
                      final c = Color(int.parse(_colors[i].replaceFirst('#', '0xFF')));
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = i),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedColor == i ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: _selectedColor == i
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Add Students'),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by name or enrollment...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 20),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedIds.length} selected',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ..._filteredStudents.map((s) {
                    final id = s['id'] as int;
                    final selected = _selectedIds.contains(id);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (selected) {
                            _selectedIds.remove(id);
                          } else {
                            _selectedIds.add(id);
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF00E5FF).withOpacity(0.08)
                              : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF00E5FF).withOpacity(0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (s['name'] as String).substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                      color: Color(0xFF00E5FF),
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s['name'],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  Text(
                                    s['username'] ?? '',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: selected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white.withOpacity(0.2),
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1623),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
              ),
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF6C63FF)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF00E5FF).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Text(
                      isEdit ? 'Save Changes' : 'Create Class',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700),
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

  Widget _fieldLabel(String text) => Text(
    text,
    style: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 13,
        fontWeight: FontWeight.w600),
  );

  Widget _textField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

class _StudentsSheet extends StatefulWidget {
  final Map<String, dynamic> cls;
  final List<Map<String, dynamic>> allStudents;
  final int teacherId;
  final VoidCallback onChanged;

  const _StudentsSheet({
    required this.cls,
    required this.allStudents,
    required this.teacherId,
    required this.onChanged,
  });

  @override
  State<_StudentsSheet> createState() => _StudentsSheetState();
}

class _StudentsSheetState extends State<_StudentsSheet> {
  List<Map<String, dynamic>> _enrolledStudents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await AdminApi.getClasses();
    if (res['success'] == true && mounted) {
      final classes = List<Map<String, dynamic>>.from(res['classes'] ?? []);
      final cls = classes.firstWhere(
              (c) => c['id'] == widget.cls['id'], orElse: () => {});
      setState(() {
        _enrolledStudents = cls.isNotEmpty && cls['students'] != null
            ? List<Map<String, dynamic>>.from(cls['students'])
            : [];
        _isLoading = false;
      });
    }
  }

  Future<void> _remove(int studentId) async {
    final res = await AdminApi.removeStudentFromClass(
        widget.cls['id'] as int, studentId);
    if (res['success'] == true) {
      _load();
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F1623),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    widget.cls['name'] ?? '',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    '${_enrolledStudents.length} students',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
                  : _enrolledStudents.isEmpty
                  ? Center(
                child: Text(
                  'No students enrolled',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 15),
                ),
              )
                  : ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _enrolledStudents.length,
                itemBuilder: (_, i) {
                  final s = _enrolledStudents[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              (s['name'] as String)
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['name'],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text(
                                s['username'] ?? '',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _remove(s['id'] as int),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                              const Color(0xFFFF6584).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person_remove_outlined,
                                color: Color(0xFFFF6584), size: 18),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF003A45).withOpacity(0.5),
          const Color(0xFF0A0E1A).withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.1),
          radius: size.width * 0.6));
    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.1), size.width * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}