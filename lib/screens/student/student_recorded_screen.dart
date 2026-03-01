import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:edulearn/screens/auth/api_service.dart';

// pubspec.yaml mein ye add karo:
// video_player: ^2.8.3
// chewie: ^1.7.5

// ─────────────────────────────────────────────────────────────────────────────
// COLOR PALETTE — subjects ko colors assign karne ke liye
// ─────────────────────────────────────────────────────────────────────────────
const _kColors = [
  Color(0xFF6C63FF), Color(0xFF00D4AA), Color(0xFFFF6584),
  Color(0xFFFFB347), Color(0xFF00D4FF), Color(0xFFFF8C42),
  Color(0xFF9C59B6), Color(0xFF27AE60),
];
const _kIcons = ['📐','🔬','📖','🌍','💻','✍️','🔭','📊'];

// ─────────────────────────────────────────────────────────────────────────────
// SUBJECT GROUP — lectures ko subject wise group karta hai
// ─────────────────────────────────────────────────────────────────────────────
class _Group {
  final String name;
  final Color  color;
  final String icon;
  final List<Map<String, dynamic>> lectures;
  _Group({required this.name, required this.color, required this.icon, required this.lectures});
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class StudentRecordedScreen extends StatefulWidget {
  const StudentRecordedScreen({super.key});
  @override
  State<StudentRecordedScreen> createState() => _StudentRecordedScreenState();
}

class _StudentRecordedScreenState extends State<StudentRecordedScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtl, _listCtl;
  late Animation<double>   _listAnim;

  bool   _loading     = true;
  String? _error;
  bool   _isSearching = false;
  String _searchQuery = '';
  final  _searchCtrl  = TextEditingController();

  // Real data from server
  List<Map<String, dynamic>> _allLectures    = [];
  List<Map<String, dynamic>> _bookmarked     = [];
  List<_Group>               _groups         = [];
  _Group?                    _selectedGroup;

  static const _accent = Color(0xFFFF6B2B);

  @override
  void initState() {
    super.initState();
    _bgCtl   = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _listCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _listAnim = CurvedAnimation(parent: _listCtl, curve: Curves.easeOutCubic);
    _listCtl.forward();
    _loadData();
  }

  @override
  void dispose() {
    _bgCtl.dispose(); _listCtl.dispose(); _searchCtrl.dispose(); super.dispose();
  }

  // ─── LOAD REAL DATA ───────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      // GET /lectures — returns only this student's class lectures
      final res = await LectureApi.getLectures();
      if (!mounted) return;
      if (res['success'] == true) {
        _allLectures = List<Map<String, dynamic>>.from(res['lectures'] ?? []);
        _buildGroups();

        // Bookmarked lectures
        final bRes = await LectureApi.getBookmarks();
        if (bRes['success'] == true) {
          final bIds = Set<int>.from(
              (bRes['lectures'] as List? ?? []).map((l) => l['id'] as int)
          );
          // Mark bookmarked in allLectures
          _allLectures = _allLectures.map((l) => {
            ...l, 'bookmarked': bIds.contains(l['id']),
          }).toList();
          _buildGroups();
        }
      } else {
        _error = res['message'] ?? 'Failed to load lectures';
      }
    } catch (e) {
      _error = 'Network error: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _buildGroups() {
    final Map<String, List<Map<String, dynamic>>> bySubject = {};

    for (final lec in _allLectures) {
      final key = (lec['subject']?.toString().isNotEmpty == true)
          ? lec['subject'].toString()
          : (lec['class_name']?.toString() ?? 'General');

      bySubject.putIfAbsent(key, () => []).add(lec);
    }

    int idx = 0;

    _groups = bySubject.entries.map((e) {
      final group = _Group(
        name: e.key,
        color: _kColors[idx % _kColors.length],
        icon: _kIcons[idx % _kIcons.length],
        lectures: e.value,
      );
      idx++;
      return group;
    }).toList();
  }

  // ─── BOOKMARK TOGGLE ─────────────────────────────────────────────────────

  Future<void> _toggleBookmark(Map<String, dynamic> lecture) async {
    final id = lecture['id'] as int;
    try {
      final res = await LectureApi.toggleBookmark(id);
      if (res['success'] == true && mounted) {
        final isNowBookmarked = res['bookmarked'] == true;
        setState(() {
          _allLectures = _allLectures.map((l) =>
          l['id'] == id ? {...l, 'bookmarked': isNowBookmarked} : l
          ).toList();
          _buildGroups();
        });
      }
    } catch (_) {}
  }

  // ─── SEARCH ───────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _searchResults {
    final q = _searchQuery.toLowerCase();
    return _allLectures.where((l) =>
    (l['title']      ?? '').toString().toLowerCase().contains(q) ||
        (l['subject']    ?? '').toString().toLowerCase().contains(q) ||
        (l['class_name'] ?? '').toString().toLowerCase().contains(q)
    ).toList();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030810),
      body: Stack(children: [
        AnimatedBuilder(animation: _bgCtl, builder: (_, __) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _BgPainter(progress: _bgCtl.value),
        )),
        SafeArea(child: Column(children: [
          _topBar(),
          if (_isSearching) _searchBar(),
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
              : _error != null
              ? _errorView()
              : RefreshIndicator(
            onRefresh: _loadData, color: _accent,
            child: _isSearching && _searchQuery.isNotEmpty
                ? _searchView()
                : _selectedGroup != null
                ? _groupView(_selectedGroup!)
                : _homeView(),
          )),
        ])),
      ]),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 16, 4),
    child: Row(children: [
      IconButton(
        onPressed: () {
          if (_selectedGroup != null) setState(() => _selectedGroup = null);
          else Navigator.pop(context);
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
      ),
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFFB84A00).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accent.withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.video_library_rounded, color: _accent, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_selectedGroup?.name ?? 'Recorded Lectures',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(_selectedGroup != null
            ? '${_selectedGroup!.lectures.length} lectures'
            : 'Your class lectures',
            style: const TextStyle(fontSize: 12, color: Colors.white38)),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: () => setState(() {
          _isSearching = !_isSearching;
          if (!_isSearching) { _searchQuery = ''; _searchCtrl.clear(); }
        }),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white60, size: 18),
        ),
      ),
    ]),
  );

  Widget _searchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _searchCtrl, autofocus: true,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search lectures, subjects...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.3), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ),
  );

  Widget _errorView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 56),
    const SizedBox(height: 12),
    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 14)),
    const SizedBox(height: 16),
    TextButton(onPressed: _loadData, child: const Text('Retry', style: TextStyle(color: _accent))),
  ]));

  // ─── HOME VIEW ────────────────────────────────────────────────────────────

  Widget _homeView() {
    if (_allLectures.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🎬', style: TextStyle(fontSize: 52)),
        const SizedBox(height: 14),
        const Text('No lectures available yet',
            style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Your teacher has not uploaded lectures\nfor your class yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 13)),
      ]));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        // STATS CARD — real numbers from API
        _statsCard(),
        const SizedBox(height: 24),

        // SUBJECT GROUPS
        _sectionHeader('By Subject', '${_groups.length} subjects'),
        const SizedBox(height: 12),

        ..._groups.asMap().entries.map((e) {
          final i = e.key; final g = e.value;
          return AnimatedBuilder(
            animation: _listAnim,
            builder: (_, child) {
              final delay = i * 0.08;
              final v     = ((_listAnim.value - delay)/(1-delay)).clamp(0.0, 1.0);
              final curve = Curves.easeOutCubic.transform(v);
              return Opacity(opacity: curve,
                  child: Transform.translate(offset: Offset(0, 20*(1-curve)), child: child));
            },
            child: _SubjectCard(
              group: g,
              onTap: () {
                setState(() => _selectedGroup = g);
                _listCtl.reset(); _listCtl.forward();
              },
            ),
          );
        }),
      ],
    );
  }

  // STATS — real numbers: total lectures in my class, subjects count, bookmarked count
  Widget _statsCard() {
    final total      = _allLectures.length;
    final bookmarked = _allLectures.where((l) => l['bookmarked'] == true).length;
    final subjects   = _groups.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFFB84A00).withValues(alpha: 0.2),
          const Color(0xFF6C3483).withValues(alpha: 0.15),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        _sBox('$total',     'Total\nLectures', _accent),
        _vDiv(),
        _sBox('$subjects',  'Subjects',        const Color(0xFF00D4AA)),
        _vDiv(),
        _sBox('$bookmarked','Saved',            const Color(0xFF6C63FF)),
      ]),
    );
  }

  Widget _sBox(String v, String l, Color c) => Expanded(child: Column(children: [
    Text(v, style: TextStyle(color: c, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
    const SizedBox(height: 2),
    Text(l, textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 10, fontWeight: FontWeight.w500, height: 1.3)),
  ]));

  Widget _vDiv() => Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.07));

  Widget _sectionHeader(String title, String sub) => Row(children: [
    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
    const SizedBox(width: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(20)),
      child: Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  ]);

  // ─── GROUP VIEW ───────────────────────────────────────────────────────────

  Widget _groupView(_Group g) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: g.lectures.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) return _groupHeader(g);
        final lec = g.lectures[i-1];
        return AnimatedBuilder(
          animation: _listAnim,
          builder: (_, child) {
            final delay = (i-1)*0.08;
            final v     = ((_listAnim.value - delay)/(1-delay)).clamp(0.0,1.0);
            final curve = Curves.easeOutCubic.transform(v);
            return Opacity(opacity: curve,
                child: Transform.translate(offset: Offset(0, 20*(1-curve)), child: child));
          },
          child: _LectureTile(
            lecture:    lec,
            color:      g.color,
            onTap:      () => _openPlayer(lec),
            onBookmark: () => _toggleBookmark(lec),
          ),
        );
      },
    );
  }

  Widget _groupHeader(_Group g) => Container(
    margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [g.color.withValues(alpha: 0.15), g.color.withValues(alpha: 0.05)]),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: g.color.withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      Text(g.icon, style: const TextStyle(fontSize: 32)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(g.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
        Text('${g.lectures.length} lectures', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
      ])),
      Text('${g.lectures.length}', style: TextStyle(color: g.color, fontSize: 30, fontWeight: FontWeight.w900)),
    ]),
  );

  // ─── SEARCH VIEW ──────────────────────────────────────────────────────────

  Widget _searchView() {
    final results = _searchResults;
    if (results.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🔍', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No lectures found for "$_searchQuery"',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final lec   = results[i];
        final group = _groups.firstWhere(
                (g) => g.lectures.any((l) => l['id'] == lec['id']),
            orElse: () => _Group(name:'', color: _accent, icon:'📚', lectures: []));
        return _LectureTile(
          lecture:    lec,
          color:      group.color,
          onTap:      () => _openPlayer(lec),
          onBookmark: () => _toggleBookmark(lec),
        );
      },
    );
  }

  void _openPlayer(Map<String, dynamic> lec) {
    HapticFeedback.lightImpact();
    Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, anim, __) => FadeTransition(
        opacity: anim,
        child: StudentVideoPlayerScreen(lecture: lec),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUBJECT CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectCard extends StatelessWidget {
  final _Group group;
  final VoidCallback onTap;
  const _SubjectCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bookmarked = group.lectures.where((l) => l['bookmarked'] == true).length;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628), borderRadius: BorderRadius.circular(18),
          border: Border.all(color: group.color.withValues(alpha: 0.2)),
          boxShadow: [BoxShadow(color: group.color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0,4))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: group.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(group.icon, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(group.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [
              Text('${group.lectures.length} lectures',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              if (bookmarked > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$bookmarked saved',
                      style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
          ])),
          const SizedBox(width: 12),
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.25), size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LECTURE TILE
// ─────────────────────────────────────────────────────────────────────────────
class _LectureTile extends StatelessWidget {
  final Map<String, dynamic> lecture;
  final Color        color;
  final VoidCallback onTap;
  final VoidCallback onBookmark;
  const _LectureTile({required this.lecture, required this.color, required this.onTap, required this.onBookmark});

  @override
  Widget build(BuildContext context) {
    final isBookmarked = lecture['bookmarked'] == true;
    final rawDate = lecture['createdAt']?.toString() ?? '';
    final dt      = DateTime.tryParse(rawDate) ?? DateTime.now();
    const months  = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateStr = '${dt.day} ${months[dt.month-1]}';
    final className = lecture['class_name']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(children: [
          // Thumbnail
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.7), color.withValues(alpha: 0.35)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 28)),
          ),
          const SizedBox(width: 12),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Class name badge
            if (className.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6),
                ),
                child: Text(className, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
              ),

            // Title — real from server
            Text(lecture['title']?.toString() ?? '',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 4),

            // Date — real from server
            Row(children: [
              Icon(Icons.calendar_today_outlined, color: Colors.white.withValues(alpha: 0.3), size: 11),
              const SizedBox(width: 3),
              Text(dateStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
              if ((lecture['subject'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(width: 8),
                Icon(Icons.circle, color: Colors.white.withValues(alpha: 0.15), size: 3),
                const SizedBox(width: 8),
                Text(lecture['subject'].toString(),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11)),
              ],
            ]),
          ])),

          const SizedBox(width: 8),
          // Bookmark button — real toggle API
          GestureDetector(
            onTap: onBookmark,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: isBookmarked ? const Color(0xFF6C63FF) : Colors.white38,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2), size: 18),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STUDENT VIDEO PLAYER SCREEN — real Chewie player
// ─────────────────────────────────────────────────────────────────────────────
class StudentVideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> lecture;
  const StudentVideoPlayerScreen({super.key, required this.lecture});
  @override
  State<StudentVideoPlayerScreen> createState() => _StudentVideoPlayerScreenState();
}

class _StudentVideoPlayerScreenState extends State<StudentVideoPlayerScreen>
    with TickerProviderStateMixin {
  VideoPlayerController? _vpc;
  ChewieController?      _cc;
  bool _initialized = false;
  bool _error       = false;

  late AnimationController _bgCtl;
  double _speed = 1.0;
  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  static const _accent = Color(0xFFFF6B2B);

  @override
  void initState() {
    super.initState();
    _bgCtl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
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
          playedColor:     _accent,
          handleColor:     _accent,
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
  void dispose() { _bgCtl.dispose(); _cc?.dispose(); _vpc?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lec       = widget.lecture;
    final title     = lec['title']?.toString()      ?? '';
    final subject   = lec['subject']?.toString()    ?? '';
    final className = lec['class_name']?.toString() ?? '';
    final category  = lec['category']?.toString()   ?? '';
    final rawDate   = lec['createdAt']?.toString()  ?? '';
    final dt        = DateTime.tryParse(rawDate) ?? DateTime.now();
    const months    = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final dateLabel = '${dt.day} ${months[dt.month-1]} ${dt.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF030810),
      body: Stack(children: [
        AnimatedBuilder(animation: _bgCtl, builder: (_, __) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _BgPainter(progress: _bgCtl.value),
        )),
        SafeArea(child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
              ),
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
            ]),
          ),

          // Real Chewie video player
          Container(
            width: double.infinity, height: 230, color: Colors.black,
            child: _error
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              SizedBox(height: 8),
              Text('Video load nahi hua', style: TextStyle(color: Colors.white38)),
            ]))
                : !_initialized
                ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
                : Chewie(controller: _cc!), // Real video player
          ),

          // Video info + speed selector
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Real chips from server data
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (className.isNotEmpty)
                  _Tag(label: '🏫 $className', color: const Color(0xFF6C63FF)),
                if (subject.isNotEmpty)
                  _Tag(label: subject, color: _accent),
                if (category.isNotEmpty)
                  _Tag(label: category, color: Colors.white54),
              ]),
              const SizedBox(height: 12),

              // Real title from server
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w900, letterSpacing: -0.3, height: 1.3)),
              const SizedBox(height: 10),

              // Real date from server
              Row(children: [
                Icon(Icons.calendar_today_outlined, color: Colors.white.withValues(alpha: 0.35), size: 14),
                const SizedBox(width: 5),
                Text(dateLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
              ]),

              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.06)),
              const SizedBox(height: 14),

              // SPEED SELECTOR — actually changes video speed via _vpc
              Text('PLAYBACK SPEED',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const SizedBox(height: 10),
              Row(children: _speeds.map((s) {
                final sel = _speed == s;
                return Expanded(child: GestureDetector(
                  onTap: () {
                    setState(() => _speed = s);
                    _vpc?.setPlaybackSpeed(s); // Real speed change
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? _accent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? _accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Text('${s}x', textAlign: TextAlign.center,
                        style: TextStyle(color: sel ? _accent : Colors.white38,
                            fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ));
              }).toList()),
            ]),
          )),
        ])),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color  color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
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
    orb(Offset(size.width*0.85, size.height*0.1 - ease*10), size.width*0.55, const Color(0xFF3A1500), 0.5);
    orb(Offset(-size.width*0.1 + ease*8, size.height*0.5), size.width*0.5, const Color(0xFF1A0030), 0.4);
    orb(Offset(size.width*0.5, size.height*0.9), size.width*0.4, const Color(0xFF001830), 0.3);
    final p = Paint()..color = Colors.white.withValues(alpha: 0.015)..strokeWidth = 0.6..style = PaintingStyle.stroke;
    for (int i = 0; i < 18; i++) {
      final y    = (size.height/17)*i;
      final wave = 3.0*sin(i*0.5 + ease*2);
      canvas.drawLine(Offset(0, y+wave), Offset(size.width, y+wave), p);
    }
  }
  @override
  bool shouldRepaint(covariant _BgPainter o) => o.progress != progress;
}