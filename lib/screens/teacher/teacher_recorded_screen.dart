import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:edulearn/screens/auth/api_service.dart';

// pubspec.yaml mein ye add karo:
// file_picker: ^8.0.0
// video_player: ^2.8.3
// chewie: ^1.7.5

class TeacherRecordedScreen extends StatefulWidget {
  const TeacherRecordedScreen({super.key});
  @override
  State<TeacherRecordedScreen> createState() => _TeacherRecordedScreenState();
}

class _TeacherRecordedScreenState extends State<TeacherRecordedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgCtl;
  final TextEditingController _searchCtl = TextEditingController();

  bool   _showSearch   = false;
  String _searchQuery  = '';
  bool   _loading      = true;
  String? _error;

  // Real data from API
  List<Map<String, dynamic>> _lectures  = [];
  List<Map<String, dynamic>> _myClasses = [];

  static const _accent = Color(0xFF00E5FF);
  static const _bg     = Color(0xFF030810);

  @override
  void initState() {
    super.initState();
    _bgCtl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _loadAll();
  }

  @override
  void dispose() {
    _bgCtl.dispose();
    _searchCtl.dispose();
    super.dispose();
  }

  // ─── DATA LOADING ──────────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        LectureApi.getLectures(),
        TeacherApi.getMyClasses(),
      ]);
      final lectureRes = results[0];
      final classRes   = results[1];

      if (!mounted) return;
      if (lectureRes['success'] == true) {
        _lectures = List<Map<String, dynamic>>.from(lectureRes['lectures'] ?? []);
      }
      if (classRes['success'] == true) {
        _myClasses = List<Map<String, dynamic>>.from(classRes['classes'] ?? []);
      }
    } catch (e) {
      _error = 'Failed to load: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  // ─── FILTERED LIST ─────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filtered => _lectures.where((l) {
    final q = _searchQuery.toLowerCase();
    return (l['title']    ?? '').toString().toLowerCase().contains(q) ||
        (l['subject']  ?? '').toString().toLowerCase().contains(q) ||
        (l['class_name'] ?? '').toString().toLowerCase().contains(q);
  }).toList();

  // ─── UPLOAD DIALOG ─────────────────────────────────────────────────────────

  void _showUploadDialog() {
    final titleCtl    = TextEditingController();
    final subjectCtl  = TextEditingController();
    final categoryCtl = TextEditingController();
    Map<String, dynamic>? selectedClass;
    String? pickedPath;
    String  pickedName    = 'No video selected';
    bool    dialogLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => Dialog(
          backgroundColor: const Color(0xFF0D1B2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.upload_rounded, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Upload Lecture',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 22),

                // CLASS DROPDOWN — real data
                _FieldLabel('Class *'),
                const SizedBox(height: 6),
                if (_myClasses.isEmpty)
                  _WarningBox('No classes assigned. Contact admin.')
                else
                  _ClassDropdown(
                    classes:  _myClasses,
                    value:    selectedClass,
                    onChanged: (v) => setD(() => selectedClass = v),
                    enabled:  !dialogLoading,
                  ),
                const SizedBox(height: 14),

                // TITLE
                _FieldLabel('Title *'),
                const SizedBox(height: 6),
                _DField(controller: titleCtl, hint: 'e.g. OS Chapter 3 - Scheduling', icon: Icons.title_rounded, enabled: !dialogLoading),
                const SizedBox(height: 12),

                // SUBJECT
                _FieldLabel('Subject'),
                const SizedBox(height: 6),
                _DField(controller: subjectCtl, hint: 'e.g. Operating Systems', icon: Icons.book_rounded, enabled: !dialogLoading),
                const SizedBox(height: 12),

                // CATEGORY
                _FieldLabel('Category'),
                const SizedBox(height: 6),
                _DField(controller: categoryCtl, hint: 'e.g. Lecture / Tutorial', icon: Icons.label_rounded, enabled: !dialogLoading),
                const SizedBox(height: 14),

                // VIDEO FILE PICKER — real file picker
                _FieldLabel('Video File *'),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: dialogLoading ? null : () async {
                    final r = await FilePicker.platform.pickFiles(
                      type: FileType.video, allowMultiple: false,
                    );
                    if (r != null && r.files.isNotEmpty) {
                      setD(() {
                        pickedPath = r.files.first.path;
                        pickedName = r.files.first.name;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: pickedPath != null
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(children: [
                      Icon(
                        pickedPath != null ? Icons.check_circle_rounded : Icons.video_file_rounded,
                        color: pickedPath != null ? Colors.green : Colors.white38,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(pickedName, overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: pickedPath != null ? Colors.white70 : Colors.white38,
                              fontSize: 13,
                            )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _accent.withValues(alpha: 0.3)),
                        ),
                        child: const Text('Browse',
                            style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 24),

                // BUTTONS
                if (dialogLoading)
                  const Center(child: Column(children: [
                    CircularProgressIndicator(color: _accent, strokeWidth: 2),
                    SizedBox(height: 10),
                    Text('Uploading video...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  ]))
                else
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    // UPLOAD BUTTON — calls real API
                    GestureDetector(
                      onTap: () async {
                        final title = titleCtl.text.trim();
                        if (title.isEmpty) {
                          _showSnack('Title required', Colors.orange); return;
                        }
                        if (pickedPath == null) {
                          _showSnack('Please select a video file', Colors.orange); return;
                        }
                        if (_myClasses.isNotEmpty && selectedClass == null) {
                          _showSnack('Please select a class', Colors.orange); return;
                        }
                        setD(() => dialogLoading = true);
                        try {
                          final res = await LectureApi.uploadLecture(
                            videoFilePath: pickedPath!,
                            title:         title,
                            subject:       subjectCtl.text.trim(),
                            category:      categoryCtl.text.trim(),
                            classId:       selectedClass?['id'] as int?,
                          );
                          if (res['success'] == true) {
                            if (ctx.mounted) Navigator.pop(ctx);
                            _showSnack('Lecture uploaded successfully!', const Color(0xFF00838F));
                            HapticFeedback.mediumImpact();
                            await _loadAll(); // Refresh list from server
                          } else {
                            _showSnack(res['message'] ?? 'Upload failed', Colors.red);
                          }
                        } catch (e) {
                          _showSnack('Error: $e', Colors.red);
                        }
                        if (ctx.mounted) setD(() => dialogLoading = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                        decoration: BoxDecoration(
                          color: _accent, borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Upload',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
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

  // ─── DELETE ────────────────────────────────────────────────────────────────

  Future<void> _deleteLecture(Map<String, dynamic> lecture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1623),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Lecture?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          '"${lecture['title']}" permanently delete ho jayega.',
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Call real delete API
    final res = await LectureApi.deleteLecture(lecture['id'] as int);
    if (res['success'] == true) {
      setState(() => _lectures.removeWhere((l) => l['id'] == lecture['id']));
      _showSnack('Lecture deleted', Colors.green.shade700);
    } else {
      _showSnack(res['message'] ?? 'Delete failed', Colors.red);
    }
  }

  // ─── OPEN VIDEO PLAYER ────────────────────────────────────────────────────

  void _openPlayer(Map<String, dynamic> lecture) {
    HapticFeedback.lightImpact();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _VideoPlayerScreen(lecture: lecture),
    ));
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(children: [
        AnimatedBuilder(
          animation: _bgCtl,
          builder: (_, __) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _BgPainter(progress: _bgCtl.value),
          ),
        ),
        SafeArea(child: Column(children: [
          _buildTopBar(),
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ])),
      ]),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 8, 4),
    child: Row(children: [
      IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
      ),
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFFB84A00).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB84A00).withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.video_library_rounded, color: Color(0xFFFF7043), size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recorded Lectures',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(
          _loading ? 'Loading...' : '${_lectures.length} lectures uploaded',
          style: const TextStyle(fontSize: 12, color: Colors.white38),
        ),
      ]),
      const Spacer(),
      IconButton(
        onPressed: () => setState(() {
          _showSearch = !_showSearch;
          if (!_showSearch) { _searchQuery = ''; _searchCtl.clear(); }
        }),
        icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded,
            color: Colors.white70, size: 22),
      ),
      IconButton(
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.upload_rounded, color: _accent, size: 22),
      ),
    ]),
  );

  Widget _buildSearchBar() => AnimatedSize(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOutCubic,
    child: _showSearch
        ? Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        controller: _searchCtl, autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: _accent,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by title, subject, class...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
          filled: true, fillColor: const Color(0xFF0A1628),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: _accent.withValues(alpha: 0.4), width: 1)),
        ),
      ),
    )
        : const SizedBox.shrink(),
  );

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.white38)),
        const SizedBox(height: 16),
        TextButton(onPressed: _loadAll, child: const Text('Retry', style: TextStyle(color: _accent))),
      ]));
    }
    final list = _filtered;
    if (list.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.video_library_outlined, size: 64, color: Colors.white12),
        const SizedBox(height: 12),
        Text(_searchQuery.isNotEmpty ? 'No results for "$_searchQuery"' : 'No lectures uploaded yet',
            style: const TextStyle(color: Colors.white38, fontSize: 15)),
        if (_searchQuery.isEmpty) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showUploadDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withValues(alpha: 0.3)),
              ),
              child: const Text('Upload First Lecture',
                  style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]));
    }
    return RefreshIndicator(
      onRefresh: _loadAll, color: _accent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: list.length,
        itemBuilder: (_, i) => _LectureCard(
          lecture:  list[i],
          onTap:    () => _openPlayer(list[i]),
          onDelete: () => _deleteLecture(list[i]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LECTURE CARD — shows real data fields
// ─────────────────────────────────────────────────────────────────────────────

class _LectureCard extends StatelessWidget {
  final Map<String, dynamic> lecture;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _LectureCard({required this.lecture, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Parse real date from server
    final rawDate  = lecture['createdAt']?.toString() ?? '';
    final dt       = DateTime.tryParse(rawDate) ?? DateTime.now();
    final dateStr  = '${dt.day}/${dt.month}/${dt.year}  '
        '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

    final className = lecture['class_name']?.toString() ?? '';
    final subject   = lecture['subject']?.toString()    ?? '';
    final category  = lecture['category']?.toString()   ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16), onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            // Thumbnail icon
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFB84A00).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB84A00).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF7043), size: 30),
            ),
            const SizedBox(width: 14),

            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Title — real value
              Text(lecture['title']?.toString() ?? 'Untitled',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),

              // Class + Subject + Category chips — real values
              Wrap(spacing: 5, runSpacing: 4, children: [
                if (className.isNotEmpty)
                  _Chip(label: className, color: const Color(0xFF6C63FF)),
                if (subject.isNotEmpty)
                  _Chip(label: subject, color: const Color(0xFF00E5FF)),
                if (category.isNotEmpty)
                  _Chip(label: category, color: Colors.white38),
              ]),
              const SizedBox(height: 5),

              // Date — real value from server
              Row(children: [
                const Icon(Icons.access_time_rounded, size: 11, color: Colors.white30),
                const SizedBox(width: 4),
                Text(dateStr, style: const TextStyle(color: Colors.white30, fontSize: 11)),
              ]),
            ])),

            const SizedBox(width: 8),
            // Delete button — calls real API
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIDEO PLAYER SCREEN — real Chewie player
// ─────────────────────────────────────────────────────────────────────────────

class _VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> lecture;
  const _VideoPlayerScreen({required this.lecture});
  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  VideoPlayerController? _vpc;
  ChewieController?      _cc;
  bool _initialized = false;
  bool _error       = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final url = widget.lecture['videoUrl']?.toString() ?? '';
    if (url.isEmpty) { setState(() => _error = true); return; }
    try {
      _vpc = VideoPlayerController.networkUrl(Uri.parse(url));
      await _vpc!.initialize();
      _cc = ChewieController(
        videoPlayerController: _vpc!,
        autoPlay: true, looping: false, allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        materialProgressColors: ChewieProgressColors(
          playedColor:     const Color(0xFF00E5FF),
          handleColor:     const Color(0xFF00E5FF),
          bufferedColor:   Colors.white24,
          backgroundColor: Colors.white12,
        ),
      );
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() { _cc?.dispose(); _vpc?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final title     = widget.lecture['title']?.toString()      ?? '';
    final subject   = widget.lecture['subject']?.toString()    ?? '';
    final className = widget.lecture['class_name']?.toString() ?? '';
    final category  = widget.lecture['category']?.toString()   ?? '';
    final rawDate   = widget.lecture['createdAt']?.toString()  ?? '';
    final dt        = DateTime.tryParse(rawDate) ?? DateTime.now();
    const months    = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateLabel = '${dt.day} ${months[dt.month-1]} ${dt.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF030810),
      appBar: AppBar(
        backgroundColor: const Color(0xFF030810),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
      ),
      body: Column(children: [
        // Real video player
        Container(
          width: double.infinity, height: 240, color: Colors.black,
          child: _error
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            SizedBox(height: 8),
            Text('Could not load video', style: TextStyle(color: Colors.white38)),
          ]))
              : !_initialized
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 2))
              : Chewie(controller: _cc!), // Real Chewie player
        ),

        // Info panel
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Real chips
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (className.isNotEmpty)
                _Chip(label: '🏫 $className', color: const Color(0xFF6C63FF)),
              if (subject.isNotEmpty)
                _Chip(label: subject, color: const Color(0xFF00E5FF)),
              if (category.isNotEmpty)
                _Chip(label: category, color: Colors.white54),
            ]),
            const SizedBox(height: 14),

            // Real title
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20,
                fontWeight: FontWeight.w900, letterSpacing: -0.3, height: 1.3)),
            const SizedBox(height: 10),

            // Real date
            Row(children: [
              const Icon(Icons.calendar_today_outlined, color: Colors.white38, size: 14),
              const SizedBox(width: 5),
              Text(dateLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
            ]),
          ]),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.5),
          fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4));
}

class _WarningBox extends StatelessWidget {
  final String msg;
  const _WarningBox(this.msg);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: const TextStyle(color: Colors.orange, fontSize: 12))),
    ]),
  );
}

class _ClassDropdown extends StatelessWidget {
  final List<Map<String, dynamic>> classes;
  final Map<String, dynamic>? value;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final bool enabled;
  const _ClassDropdown({required this.classes, required this.value, required this.onChanged, required this.enabled});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: value != null
          ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.08)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<Map<String, dynamic>>(
        value: value, isExpanded: true,
        dropdownColor: const Color(0xFF0D1B2E),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00E5FF)),
        hint: Text('Choose class...', style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13)),
        items: classes.map((cls) => DropdownMenuItem(
          value: cls,
          child: Row(children: [
            Text(cls['icon']?.toString() ?? '📚', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(cls['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              Text('${cls['subject'] ?? ''} • ${cls['student_count'] ?? 0} students',
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ])),
          ]),
        )).toList(),
        onChanged: enabled ? onChanged : null,
        selectedItemBuilder: (_) => classes.map((cls) => Align(
          alignment: Alignment.centerLeft,
          child: Text('${cls['icon'] ?? '📚'} ${cls['name']}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        )).toList(),
      ),
    ),
  );
}

class _DField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool enabled;
  const _DField({required this.controller, required this.hint, required this.icon, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);
    return TextField(
      controller: controller, enabled: enabled,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent.withValues(alpha: 0.5), width: 1.5)),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.04))),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color  color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class _BgPainter extends CustomPainter {
  final double progress;
  _BgPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeInOut.transform(progress);
    void orb(Offset c, double r, Color col, double op) => canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(colors: [col.withValues(alpha: op), col.withValues(alpha: op*0.3), col.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: r)));
    orb(Offset(size.width*0.85, size.height*0.08 - ease*10), size.width*0.6, const Color(0xFF3A1500), 0.45);
    orb(Offset(-size.width*0.1 + ease*8, size.height*0.5), size.width*0.5, const Color(0xFF1A0A00), 0.40);
    final p = Paint()..color = Colors.white.withValues(alpha: 0.015)..strokeWidth = 0.7..style = PaintingStyle.stroke;
    for (int i = 0; i < 20; i++) {
      final y    = (size.height/19)*i;
      final path = Path();
      for (int s = 0; s <= 100; s++) {
        final x  = (size.width/100)*s;
        final yy = y + 14.0*sin((x/size.width)*pi*2.2 + i*0.3 + ease*0.4) + 6.0*sin((x/size.width)*pi*4.4 + i*0.15);
        s==0 ? path.moveTo(x,yy) : path.lineTo(x,yy);
      }
      canvas.drawPath(path, p);
    }
  }
  @override
  bool shouldRepaint(covariant _BgPainter o) => o.progress != progress;
}