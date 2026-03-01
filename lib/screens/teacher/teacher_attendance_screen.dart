import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:edulearn/screens/auth/api_service.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});
  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {

  final TextEditingController _titleCtl = TextEditingController();
  late final AnimationController _bgCtl, _pulseCtl, _qrRevealCtl;
  late final Animation<double> _qrScale, _qrFade;

  bool _sessionActive = false;
  bool _isStarting    = false;
  bool _isClosing     = false;
  bool _isExporting   = false;
  bool _loadingClasses = true;

  String? _sessionId;
  String? _currentQrData;
  int _nonceTtlSeconds  = 20;
  int _qrSecondsLeft    = 0;
  int _markedCount      = 0;

  List<Map<String, dynamic>> _myClasses = [];
  Map<String, dynamic>?      _selectedClass;

  Timer? _qrRefreshTimer, _qrCountdownTimer, _markedCountTimer;
  List<Map<String, dynamic>> _sessions = [];

  static const _accent = Color(0xFF00E5FF);
  static const _bg     = Color(0xFF030810);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bgCtl       = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _pulseCtl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _qrRevealCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _qrScale     = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _qrRevealCtl, curve: Curves.easeOutBack));
    _qrFade      = CurvedAnimation(parent: _qrRevealCtl, curve: Curves.easeIn);
    _loadMyClasses();
    _loadSessions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.detached || state == AppLifecycleState.paused) && _sessionActive) {
      _showCloseConfirmDialog(fromLifecycle: true);
    }
  }

  Future<void> _loadMyClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final data = await TeacherApi.getMyClasses();
      if (data['success'] == true && mounted) {
        setState(() => _myClasses = List<Map<String, dynamic>>.from(data['classes'] ?? []));
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingClasses = false);
  }

  Future<void> _showCloseConfirmDialog({bool fromLifecycle = false}) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1623),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Close Session?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          fromLifecycle
              ? 'App background ja raha hai. Active attendance session close karna chahte hain?'
              : 'Are you sure you want to close this session?',
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Active', style: TextStyle(color: _accent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close Session', style: TextStyle(color: Color(0xFFFF5252))),
          ),
        ],
      ),
    );
    if (confirmed == true) await _closeSession();
  }

  Future<Position> _getLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever)
      throw Exception('Location permission denied');
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _startSession() async {
    if (_titleCtl.text.trim().isEmpty) {
      _showSnack('Please enter a session title', Colors.red.shade700); return;
    }
    if (_selectedClass == null) {
      _showSnack('Please select a class first', Colors.orange); return;
    }
    setState(() => _isStarting = true);
    HapticFeedback.mediumImpact();
    try {
      final pos  = await _getLocation();
      final data = await AttendanceApi.startSession(
        title:           _titleCtl.text.trim(),
        lat:             pos.latitude,
        lng:             pos.longitude,
        classId:         _selectedClass!['id'] as int,
        radiusM:         100,
        accuracyM:       50,
        durationMinutes: 60,
        nonceTtlSeconds: 20,
      );
      if (data['success'] == true) {
        setState(() {
          _sessionActive   = true;
          _sessionId       = data['sessionId'];
          _currentQrData   = data['qr'];
          _nonceTtlSeconds = data['nonceTtlSeconds'] ?? 20;
          _qrSecondsLeft   = _nonceTtlSeconds;
          _markedCount     = 0;
        });
        _qrRevealCtl.forward(from: 0);
        _startTimers();
        _loadSessions();
      } else {
        _showSnack(data['message'] ?? 'Failed to start session', Colors.red.shade700);
      }
    } catch (e) {
      _showSnack('Error: $e', Colors.red.shade700);
    } finally {
      setState(() => _isStarting = false);
    }
  }

  Future<void> _refreshNonce() async {
    if (_sessionId == null || !_sessionActive) return;
    try {
      final data = await AttendanceApi.refreshNonce(sessionId: _sessionId!, ttlSeconds: _nonceTtlSeconds);
      if (data['success'] == true && mounted) {
        setState(() { _currentQrData = data['qr']; _qrSecondsLeft = _nonceTtlSeconds; });
      } else if (data['message'] == 'Expired' || data['message'] == 'Not active') {
        _resetSession();
        _showSnack('Session expired automatically', Colors.orange);
      }
    } catch (_) {}
  }

  Future<void> _closeSession() async {
    if (_sessionId == null) return;
    setState(() => _isClosing = true);
    HapticFeedback.mediumImpact();
    try {
      final data = await AttendanceApi.closeSession(_sessionId!);
      if (data['success'] == true) {
        _resetSession();
        _showSnack('Session closed successfully', const Color(0xFF00838F));
        _loadSessions();
      } else {
        _showSnack(data['message'] ?? 'Failed to close', Colors.red.shade700);
      }
    } catch (e) {
      _showSnack('Error: $e', Colors.red.shade700);
    } finally {
      setState(() => _isClosing = false);
    }
  }

  Future<void> _loadSessions() async {
    try {
      final now = DateTime.now();
      final d   = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
      final data = await AttendanceApi.getSessions(date: d);
      if (data['success'] == true && mounted) {
        setState(() => _sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []));
        if (_sessionId != null) {
          final cur = _sessions.firstWhere((s) => s['id'] == _sessionId, orElse: () => {});
          if (cur.isNotEmpty && mounted) setState(() => _markedCount = cur['markedCount'] ?? 0);
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshMarkedCount() async {
    if (_sessionId == null || !_sessionActive) return;
    try {
      final data = await AttendanceApi.getSessions();
      if (data['success'] == true && mounted) {
        final list = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
        final cur  = list.firstWhere((s) => s['id'] == _sessionId, orElse: () => {});
        if (cur.isNotEmpty && mounted) setState(() => _markedCount = cur['markedCount'] ?? 0);
      }
    } catch (_) {}
  }

  void _startTimers() {
    _qrRefreshTimer?.cancel(); _qrCountdownTimer?.cancel(); _markedCountTimer?.cancel();
    _qrRefreshTimer   = Timer.periodic(Duration(seconds: _nonceTtlSeconds), (_) { if (_sessionActive) _refreshNonce(); });
    _qrCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _qrSecondsLeft = _qrSecondsLeft > 0 ? _qrSecondsLeft - 1 : _nonceTtlSeconds);
    });
    _markedCountTimer = Timer.periodic(const Duration(seconds: 10), (_) { if (_sessionActive) _refreshMarkedCount(); });
  }

  void _resetSession() {
    _qrRefreshTimer?.cancel(); _qrCountdownTimer?.cancel(); _markedCountTimer?.cancel();
    setState(() {
      _sessionActive = false; _sessionId = null; _currentQrData = null;
      _qrSecondsLeft = 0; _markedCount = 0;
    });
    _qrRevealCtl.reverse();
  }

  Future<void> _exportExcel(String sessionId) async {
    setState(() => _isExporting = true);
    try {
      final data = await AttendanceApi.getRoster(sessionId);
      if (data['success'] != true) {
        _showSnack(data['message'] ?? 'Export failed', Colors.red.shade700); return;
      }

      final sessionTitle = data['sessionTitle'] ?? 'Attendance';
      final sessionDate  = data['sessionDate']  ?? '';
      final roster       = List<Map<String, dynamic>>.from(data['roster'] ?? []);

      final excel = ex.Excel.createExcel();
      final sheet = excel['Attendance'];
      excel.delete('Sheet1');

      final titleCell = sheet.cell(ex.CellIndex.indexByString('A1'));
      titleCell.value = ex.TextCellValue('Session: $sessionTitle');
      titleCell.cellStyle = ex.CellStyle(
        bold: true, fontSize: 14,
        fontColorHex: ex.ExcelColor.fromHexString('#FFFFFF'),
        backgroundColorHex: ex.ExcelColor.fromHexString('#1565C0'),
      );
      sheet.merge(ex.CellIndex.indexByString('A1'), ex.CellIndex.indexByString('I1'));

      final dateCell = sheet.cell(ex.CellIndex.indexByString('A2'));
      dateCell.value = ex.TextCellValue('Date: $sessionDate');
      dateCell.cellStyle = ex.CellStyle(
        italic: true, backgroundColorHex: ex.ExcelColor.fromHexString('#E3F2FD'),
      );
      sheet.merge(ex.CellIndex.indexByString('A2'), ex.CellIndex.indexByString('I2'));

      final headers = [
        'Enrollment No.', 'Student Name', 'Status', 'Device ID',
        'Session ID', 'Distance (m)', 'Accuracy (m)', 'Marked At', 'Present %',
      ];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 2));
        cell.value = ex.TextCellValue(headers[i]);
        cell.cellStyle = ex.CellStyle(
          bold: true,
          fontColorHex:       ex.ExcelColor.fromHexString('#FFFFFF'),
          backgroundColorHex: ex.ExcelColor.fromHexString('#0D47A1'),
          horizontalAlign:    ex.HorizontalAlign.Center,
        );
      }

      for (int r = 0; r < roster.length; r++) {
        final row       = roster[r];
        final isPresent = row['status'] == 'Present';
        final bgColor   = isPresent
            ? ex.ExcelColor.fromHexString('#E8F5E9')
            : ex.ExcelColor.fromHexString('#FFEBEE');
        final rowData = [
          row['enrollment'] ?? '', row['name']      ?? '', row['status']    ?? '',
          row['deviceId']   ?? '-', row['sessionId'] ?? '-', row['distanceM'] ?? '-',
          row['accuracyM']  ?? '-', row['markedAt']  ?? '-', row['presentPct'] ?? '-',
        ];
        for (int c = 0; c < rowData.length; c++) {
          final cell = sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 3));
          cell.value = ex.TextCellValue(rowData[c].toString());
          cell.cellStyle = ex.CellStyle(
            backgroundColorHex: bgColor,
            fontColorHex: isPresent
                ? ex.ExcelColor.fromHexString('#1B5E20')
                : ex.ExcelColor.fromHexString('#B71C1C'),
          );
        }
      }

      sheet.setColumnWidth(0, 18); sheet.setColumnWidth(1, 22); sheet.setColumnWidth(2, 12);
      sheet.setColumnWidth(3, 36); sheet.setColumnWidth(4, 36); sheet.setColumnWidth(5, 14);
      sheet.setColumnWidth(6, 14); sheet.setColumnWidth(7, 22); sheet.setColumnWidth(8, 12);

      final summaryRow   = roster.length + 4;
      final presentCount = roster.where((r) => r['status'] == 'Present').length;
      final absentCount  = roster.length - presentCount;

      final summaryCell = sheet.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow));
      summaryCell.value = ex.TextCellValue('Total: ${roster.length}   Present: $presentCount   Absent: $absentCount');
      summaryCell.cellStyle = ex.CellStyle(
        bold: true,
        backgroundColorHex: ex.ExcelColor.fromHexString('#1565C0'),
        fontColorHex:       ex.ExcelColor.fromHexString('#FFFFFF'),
      );
      sheet.merge(
        ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: summaryRow),
        ex.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: summaryRow),
      );

      final bytes     = excel.encode();
      if (bytes == null) throw Exception('Excel encode failed');

      final dir       = await getTemporaryDirectory();
      final safeTitle = sessionTitle.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      final file      = File('${dir.path}/Attendance_${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'Attendance - $sessionTitle',
        text:    'Attendance sheet for $sessionTitle\nPresent: $presentCount / ${roster.length}',
      );
    } catch (e) {
      _showSnack('Export failed: $e', Colors.red.shade700);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 4),
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleCtl.dispose();
    _bgCtl.dispose(); _pulseCtl.dispose(); _qrRevealCtl.dispose();
    _qrRefreshTimer?.cancel(); _qrCountdownTimer?.cancel(); _markedCountTimer?.cancel();
    super.dispose();
  }

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
          _topBar(),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(children: [
              _classDropdownCard(),        const SizedBox(height: 12),
              _titleCard(),                const SizedBox(height: 16),
              _qrCard(),                   const SizedBox(height: 20),
              _actionButtons(),
              if (_sessions.isNotEmpty) ...[const SizedBox(height: 24), _sessionHistory()],
            ]),
          )),
        ])),
      ]),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 16, 4),
    child: Row(children: [
      IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
      ),
      const SizedBox(width: 2),
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 229, 255, 0.12), borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(0, 229, 255, 0.3)),
        ),
        child: const Icon(Icons.qr_code_2_rounded, color: _accent, size: 20),
      ),
      const SizedBox(width: 12),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Attendance QR', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        Text('Class-wise attendance', style: TextStyle(fontSize: 12, color: Colors.white38)),
      ]),
      const Spacer(),
      if (_sessionActive)
        AnimatedBuilder(
          animation: _pulseCtl,
          builder: (_, __) => GestureDetector(
            onTap: _refreshMarkedCount,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color.fromRGBO(76, 175, 80, (0.12 + _pulseCtl.value * 0.05).clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color.fromRGBO(76, 175, 80, (0.4 + _pulseCtl.value * 0.2).clamp(0.0, 1.0))),
              ),
              child: Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color.fromRGBO(105, 240, 174, 0.7), blurRadius: 6)],
                  ),
                ),
                const SizedBox(width: 6),
                Text('$_markedCount Present',
                    style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
          ),
        ),
    ]),
  );

  Widget _classDropdownCard() => _GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Select Class',
          style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 10),
      if (_loadingClasses)
        const Center(child: SizedBox(width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _accent)))
      else if (_myClasses.isEmpty)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 152, 0, 0.08), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromRGBO(255, 152, 0, 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
            const SizedBox(width: 10),
            const Expanded(child: Text(
              'No classes assigned. Contact admin.',
              style: TextStyle(color: Colors.orange, fontSize: 13),
            )),
            GestureDetector(onTap: _loadMyClasses,
                child: const Icon(Icons.refresh, color: Colors.orange, size: 18)),
          ]),
        )
      else
        Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedClass != null
                  ? const Color.fromRGBO(0, 229, 255, 0.4)
                  : const Color.fromRGBO(255, 255, 255, 0.08),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              value: _selectedClass,
              isExpanded: true,
              dropdownColor: const Color(0xFF0F1A2E),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              borderRadius: BorderRadius.circular(12),
              hint: const Text('Choose class...',
                  style: TextStyle(color: Color.fromRGBO(255,255,255,0.25), fontSize: 14)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
              items: _myClasses.map((cls) => DropdownMenuItem<Map<String, dynamic>>(
                value: cls,
                child: Row(children: [
                  Text(cls['icon'] ?? '📚', style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(cls['name'] ?? '',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('${cls['subject'] ?? ''}  •  ${cls['student_count'] ?? 0} students',
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ])),
                ]),
              )).toList(),
              onChanged: _sessionActive ? null : (val) => setState(() => _selectedClass = val),
              selectedItemBuilder: (_) => _myClasses.map((cls) => Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${cls['icon'] ?? '📚'} ${cls['name']}  •  ${cls['student_count'] ?? 0} students',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              )).toList(),
            ),
          ),
        ),
    ]),
  );

  Widget _titleCard() => _GlassCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Session Title',
          style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      TextField(
        controller: _titleCtl, enabled: !_sessionActive,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'e.g. Math Lecture - Period 3',
          hintStyle: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.25), fontSize: 14),
          filled: true, fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color.fromRGBO(255,255,255,0.08))),
          enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color.fromRGBO(255,255,255,0.08))),
          focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color.fromRGBO(255,255,255,0.04))),
          prefixIcon: Icon(Icons.edit_rounded,
              color: _sessionActive ? const Color.fromRGBO(255,255,255,0.12) : const Color.fromRGBO(0,229,255,0.6), size: 18),
        ),
      ),
    ]),
  );

  Widget _qrCard() => _GlassCard(
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.qr_code_rounded, color: Colors.white38, size: 16),
        const SizedBox(width: 6),
        const Text('QR Code', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
        if (_selectedClass != null && !_sessionActive) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0,229,255,0.1), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color.fromRGBO(0,229,255,0.3)),
            ),
            child: Text(_selectedClass!['name'] ?? '',
                style: const TextStyle(color: _accent, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ]),
      const SizedBox(height: 16),
      AnimatedBuilder(
        animation: _qrRevealCtl,
        builder: (_, __) => Opacity(
          opacity: _sessionActive ? _qrFade.value : (1 - _qrFade.value).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _sessionActive ? _qrScale.value : 1.0,
            child: Container(
              width: double.infinity, height: 240,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: _sessionActive
                    ? [BoxShadow(color: const Color.fromRGBO(0,229,255,0.25), blurRadius: 30, spreadRadius: 2)]
                    : [],
              ),
              child: _sessionActive && _currentQrData != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: QrImageView(data: _currentQrData!, version: QrVersions.auto,
                    backgroundColor: Colors.white, padding: const EdgeInsets.all(10), size: double.infinity),
              )
                  : Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  _selectedClass == null
                      ? 'Select a class first'
                      : 'Start session to generate QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ])),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      AnimatedBuilder(
        animation: _pulseCtl,
        builder: (_, __) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _sessionActive ? const Color(0xFF0A2010) : const Color(0xFF0A0E18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _sessionActive
                  ? Color.fromRGBO(76, 175, 80, (0.3 + _pulseCtl.value * 0.2).clamp(0.0, 1.0))
                  : const Color.fromRGBO(255,255,255,0.07),
            ),
          ),
          child: _sessionActive
              ? Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(
                color: Colors.greenAccent, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color.fromRGBO(105,240,174,0.6), blurRadius: 8)],
              )),
              const SizedBox(width: 8),
              Text('${_selectedClass?['name'] ?? 'Active'} Session',
                  style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            Text(_sessionId ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
              _BadgeChip(icon: Icons.timer_rounded, label: 'QR in ${_qrSecondsLeft}s',
                  color: _qrSecondsLeft <= 5 ? Colors.orange : _accent),
              _BadgeChip(icon: Icons.people_rounded, label: '$_markedCount / ${_selectedClass?['student_count'] ?? '?'} marked', color: Colors.greenAccent),
              const _BadgeChip(icon: Icons.location_on_rounded, label: '100m'),
            ]),
          ])
              : const Center(child: Text('Not started', style: TextStyle(color: Colors.white38, fontSize: 13))),
        ),
      ),
    ]),
  );

  Widget _actionButtons() => Column(children: [
    _ActionButton(
      onTap: (!_sessionActive && !_isStarting && _selectedClass != null) ? _startSession : null,
      color:       _sessionActive ? const Color(0xFF1B3A1F) : (_selectedClass != null ? const Color(0xFF1DB954) : const Color(0xFF152A1A)),
      borderColor: _sessionActive ? const Color.fromRGBO(76,175,80,0.2) : (_selectedClass != null ? Colors.green : Colors.green.withValues(alpha: 0.2)),
      icon:  _isStarting ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
      label: _isStarting ? 'Starting...' : 'Start Session',
      textColor: (_sessionActive || _selectedClass == null) ? Colors.white30 : Colors.white,
    ),
    const SizedBox(height: 12),
    _ActionButton(
      onTap: (_sessionActive && !_isClosing) ? () => _showCloseConfirmDialog() : null,
      color:       _sessionActive ? const Color(0xFFC62828) : const Color(0xFF3A1A1A),
      borderColor: _sessionActive ? const Color.fromRGBO(244,67,54,0.4) : const Color.fromRGBO(244,67,54,0.1),
      icon:  _isClosing ? Icons.hourglass_top_rounded : Icons.stop_rounded,
      label: _isClosing ? 'Closing...' : 'Close Session',
      textColor: _sessionActive ? Colors.white : Colors.white24,
    ),
    const SizedBox(height: 12),
    _ActionButton(
      onTap: (_sessionId != null && !_isExporting) ? () => _exportExcel(_sessionId!) : null,
      color:       _sessionId != null ? const Color(0xFF1B5E20) : const Color(0xFF0A1628),
      borderColor: _sessionId != null ? const Color(0xFF4CAF50) : Colors.white10,
      icon:  _isExporting ? Icons.hourglass_top_rounded : Icons.table_chart_rounded,
      label: _isExporting ? 'Generating...' : 'Export & Share Excel',
      textColor: _sessionId != null ? Colors.white : Colors.white24,
    ),
  ]);

  Widget _sessionHistory() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      const Text("Today's Sessions", style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700)),
      const Spacer(),
      GestureDetector(onTap: _loadSessions, child: const Icon(Icons.refresh_rounded, color: Colors.white38, size: 18)),
    ]),
    const SizedBox(height: 12),
    ..._sessions.map((s) {
      final isActive  = s['status'] == 'ACTIVE';
      final color     = isActive ? Colors.greenAccent : Colors.white38;
      final sessionId = s['id']?.toString() ?? '';
      return Container(
        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(10,22,40,0.8), borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? const Color.fromRGBO(76,175,80,0.3) : const Color.fromRGBO(255,255,255,0.06),
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: Color.fromRGBO(isActive?105:255, isActive?240:255, isActive?174:255, 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(isActive ? Icons.radio_button_checked : Icons.check_circle_outline, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s['title'] ?? 'Session',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            Text('${s['class_name'] ?? ''}  •  ${s['markedCount'] ?? 0} marked',
                style: const TextStyle(color: Color.fromRGBO(255,255,255,0.35), fontSize: 11)),
          ])),
          GestureDetector(
            onTap: _isExporting ? null : () => _exportExcel(sessionId),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(76,175,80,0.12), borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color.fromRGBO(76,175,80,0.3)),
              ),
              child: _isExporting
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.greenAccent))
                  : const Icon(Icons.ios_share_rounded, color: Colors.greenAccent, size: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Color.fromRGBO(isActive?105:255, isActive?240:255, isActive?174:255, 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color.fromRGBO(isActive?105:255, isActive?240:255, isActive?174:255, 0.3)),
            ),
            child: Text(isActive ? 'ACTIVE' : 'CLOSED',
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
          ),
        ]),
      );
    }),
  ]);
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color.fromRGBO(10,22,40,0.85), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color.fromRGBO(255,255,255,0.07)),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0,4))],
    ),
    child: child,
  );
}

class _ActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color color, borderColor, textColor;
  final IconData icon;
  final String label;
  const _ActionButton({required this.onTap, required this.color, required this.borderColor,
    required this.icon, required this.label, required this.textColor});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200), width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: onTap != null
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0,4))]
            : [],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: textColor, size: 22),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;
  const _BadgeChip({required this.icon, required this.label, this.color = Colors.white54});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _BgPainter extends CustomPainter {
  final double progress;
  _BgPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final e = Curves.easeInOut.transform(progress);
    void orb(Offset c, double r, Color col, double op) => canvas.drawCircle(c, r, Paint()
      ..shader = RadialGradient(colors: [
        col.withValues(alpha: op), col.withValues(alpha: op*0.3), col.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(center: c, radius: r)));
    orb(Offset(size.width*0.85, size.height*0.08 - e*10), size.width*0.6, const Color(0xFF003A45), 0.45);
    orb(Offset(-size.width*0.1 + e*8, size.height*0.5),   size.width*0.5, const Color(0xFF002030), 0.40);
    final p = Paint()..color = Colors.white.withValues(alpha: 0.015)..strokeWidth = 0.7..style = PaintingStyle.stroke;
    for (int i = 0; i < 20; i++) {
      final y    = (size.height/19)*i;
      final path = Path();
      for (int s = 0; s <= 100; s++) {
        final x  = (size.width/100)*s;
        final yy = y + 14.0*sin((x/size.width)*pi*2.2 + i*0.3 + e*0.4) + 6.0*sin((x/size.width)*pi*4.4 + i*0.15);
        s==0 ? path.moveTo(x, yy) : path.lineTo(x, yy);
      }
      canvas.drawPath(path, p);
    }
  }
  @override
  bool shouldRepaint(covariant _BgPainter old) => old.progress != progress;
}