import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edulearn/screens/auth/api_service.dart';

enum ScanState { idle, scanning, verifying, success, failed }

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});
  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen>
    with TickerProviderStateMixin {

  late final AnimationController _bgCtl, _pulseCtl, _scanLineCtl,
      _cornerCtl, _resultCtl, _particleCtl;
  late final Animation<double> _cornerAnim, _resultScale, _resultFade, _successRing;

  MobileScannerController? _scannerController;

  ScanState _state            = ScanState.idle;
  String    _scannedSessionId = '';
  String    _scannedNonce     = '';
  String    _failReason       = '';
  int       _distanceM        = 0;
  String    _deviceId         = '';
  String    _studentName      = '';

  double _currentZoom = 1.0;
  double _baseZoom    = 1.0;
  static const double _minZoom = 1.0;
  static const double _maxZoom = 4.0;

  static const _accent  = Color(0xFF00E5FF);
  static const _bg      = Color(0xFF030810);
  static const _success = Color(0xFF00E676);
  static const _fail    = Color(0xFFFF1744);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadPrefs();
  }

  void _initAnimations() {
    _bgCtl       = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _pulseCtl    = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
    _scanLineCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _cornerCtl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _cornerAnim  = CurvedAnimation(parent: _cornerCtl, curve: Curves.easeOutBack);
    _resultCtl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _resultScale = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _resultCtl, curve: Curves.elasticOut));
    _resultFade  = CurvedAnimation(parent: _resultCtl, curve: Curves.easeIn);
    _particleCtl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _successRing = CurvedAnimation(parent: _particleCtl, curve: Curves.easeOut);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final storedDeviceId = prefs.getString('deviceId');
    final newDeviceId    = storedDeviceId ?? _generateDeviceId();
    if (storedDeviceId == null) await prefs.setString('deviceId', newDeviceId);
    setState(() {
      _studentName = prefs.getString('name') ?? 'Student';
      _deviceId    = newDeviceId;
    });
  }

  String _generateDeviceId() =>
      List.generate(16, (_) => Random().nextInt(16).toRadixString(16)).join();

  void _startScan() {
    HapticFeedback.mediumImpact();
    setState(() {
      _state       = ScanState.scanning;
      _failReason  = '';
      _currentZoom = 1.0;
      _baseZoom    = 1.0;
    });
    _cornerCtl.forward(from: 0);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing:         CameraFacing.back,
      torchEnabled:   false,
    );
  }

  void _onQrDetected(String rawValue) async {
    if (_state != ScanState.scanning) return;
    HapticFeedback.lightImpact();

    final parts = rawValue.split('|');
    if (parts.length < 4 || parts[0] != 'EDULEARN') {
      _onFail('Invalid QR code — not an EduLearn attendance QR.');
      return;
    }

    final sessionId = parts[1];
    final nonce     = parts[2];

    setState(() {
      _state            = ScanState.verifying;
      _scannedSessionId = sessionId;
      _scannedNonce     = nonce;
    });

    await _scannerController?.stop();
    await _verifyAttendance(sessionId, nonce);
  }

  Future<void> _verifyAttendance(String sessionId, String nonce) async {
    Position? pos;
    try {
      pos = await _getLocation();
    } catch (e) {
      _onFail('GPS Error: $e');
      return;
    }

    try {
      final data = await AttendanceApi.markAttendance(
        sessionId: sessionId,
        nonce:     nonce,
        lat:       pos.latitude,
        lng:       pos.longitude,
        accuracyM: pos.accuracy.round(),
        deviceId:  _deviceId,
      );

      if (data['success'] == true) {
        setState(() => _distanceM = data['distanceM'] ?? 0);
        _onSuccess();
      } else {
        _onFail(data['message'] ?? 'Verification failed');
      }
    } catch (e) {
      _onFail('Network error. Check connection and try again.');
    }
  }

  Future<Position> _getLocation() async {
    if (!await Geolocator.isLocationServiceEnabled())
      throw Exception('Location services are OFF. Please enable GPS.');

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied)        throw Exception('Location permission denied.');
    if (perm == LocationPermission.deniedForever) throw Exception('Location permanently denied. Enable in settings.');

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit:       const Duration(seconds: 12),
      );
    } catch (_) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit:       const Duration(seconds: 8),
      );
    }
  }

  void _onSuccess() {
    HapticFeedback.heavyImpact();
    setState(() => _state = ScanState.success);
    _resultCtl.forward(from: 0);
    _particleCtl.forward(from: 0);
  }

  void _onFail(String reason) {
    HapticFeedback.vibrate();
    setState(() { _state = ScanState.failed; _failReason = reason; });
    _resultCtl.forward(from: 0);
  }

  void _reset() {
    _scannerController?.dispose();
    _scannerController = null;
    setState(() {
      _state            = ScanState.idle;
      _scannedSessionId = '';
      _scannedNonce     = '';
      _failReason       = '';
      _distanceM        = 0;
      _currentZoom      = 1.0;
      _baseZoom         = 1.0;
    });
    _resultCtl.reverse();
    _cornerCtl.reverse();
    _particleCtl.reset();
  }

  @override
  void dispose() {
    _bgCtl.dispose(); _pulseCtl.dispose(); _scanLineCtl.dispose();
    _cornerCtl.dispose(); _resultCtl.dispose(); _particleCtl.dispose();
    _scannerController?.dispose();
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
            painter: _StudentBgPainter(progress: _bgCtl.value),
          ),
        ),
        SafeArea(child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: _state == ScanState.success || _state == ScanState.failed
                ? _buildResultView()
                : _buildScanView(),
          ),
        ])),
      ]),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(4, 12, 16, 4),
    child: Row(children: [
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
      ),
      const SizedBox(width: 2),
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 229, 255, 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(0, 229, 255, 0.3)),
        ),
        child: const Icon(Icons.fact_check_outlined, color: _accent, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mark Attendance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        Text('Hi, $_studentName',
            style: const TextStyle(fontSize: 12, color: Colors.white38)),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: _showHistorySheet,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
          ),
          child: const Row(children: [
            Icon(Icons.history, color: Color.fromRGBO(255, 255, 255, 0.5), size: 14),
            SizedBox(width: 5),
            Text('History', style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    ]),
  );

  Widget _buildScanView() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
    child: Column(children: [
      _buildTodayCard(),
      const SizedBox(height: 24),
      Expanded(child: _buildScannerFrame()),
      const SizedBox(height: 12),
      if (_state == ScanState.scanning) _buildZoomIndicator(),
      const SizedBox(height: 12),
      _buildStatusText(),
      const SizedBox(height: 20),
      _buildScanButton(),
    ]),
  );

  Widget _buildZoomIndicator() => Row(children: [
    const Icon(Icons.zoom_out, color: Colors.white30, size: 16),
    const SizedBox(width: 8),
    Expanded(
      child: SliderTheme(
        data: SliderThemeData(
          thumbColor: _accent, activeTrackColor: _accent,
          inactiveTrackColor: Colors.white12, trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        ),
        child: Slider(
          value: _currentZoom.clamp(_minZoom, _maxZoom),
          min: _minZoom, max: _maxZoom,
          onChanged: (v) {
            setState(() => _currentZoom = v);
            _scannerController?.setZoomScale(
              ((v - _minZoom) / (_maxZoom - _minZoom)).clamp(0.0, 1.0),
            );
          },
        ),
      ),
    ),
    const SizedBox(width: 8),
    const Icon(Icons.zoom_in, color: Colors.white30, size: 16),
    const SizedBox(width: 8),
    Text('${_currentZoom.toStringAsFixed(1)}x',
        style: const TextStyle(color: Colors.white38, fontSize: 12)),
  ]);

  Widget _buildTodayCard() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: const Color.fromRGBO(10, 22, 40, 0.85),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.07)),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 229, 255, 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.calendar_today_outlined, color: _accent, size: 18),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Today's Attendance",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        Text(_formattedDate(),
            style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.35), fontSize: 12)),
      ]),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 229, 255, 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color.fromRGBO(0, 229, 255, 0.2)),
        ),
        child: Text(
          _state == ScanState.idle ? 'Scan QR' : _state.name.toUpperCase(),
          style: TextStyle(
            color: _state == ScanState.verifying ? Colors.amber : _accent,
            fontSize: 10, fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ]),
  );

  Widget _buildScannerFrame() => AnimatedBuilder(
    animation: Listenable.merge([_pulseCtl, _scanLineCtl, _cornerAnim]),
    builder: (context, _) {
      final isScanning  = _state == ScanState.scanning;
      final isVerifying = _state == ScanState.verifying;
      return Stack(alignment: Alignment.center, children: [
        if (isScanning)
          Container(
            width:  280 + _pulseCtl.value * 12,
            height: 280 + _pulseCtl.value * 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Color.fromRGBO(0, 229, 255, 0.08 + _pulseCtl.value * 0.08),
              ),
            ),
          ),
        GestureDetector(
          onScaleStart:  (_)       => _baseZoom = _currentZoom,
          onScaleUpdate: (details) {
            if (!isScanning) return;
            final nz = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
            setState(() => _currentZoom = nz);
            _scannerController?.setZoomScale(
              ((nz - _minZoom) / (_maxZoom - _minZoom)).clamp(0.0, 1.0),
            );
          },
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              color: isScanning
                  ? const Color.fromRGBO(0, 0, 0, 0.4)
                  : const Color.fromRGBO(10, 22, 40, 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isScanning
                    ? Color.fromRGBO(0, 229, 255, (0.5 + _pulseCtl.value * 0.3).clamp(0.0, 1.0))
                    : const Color.fromRGBO(255, 255, 255, 0.08),
                width: isScanning ? 1.5 : 1,
              ),
              boxShadow: isScanning
                  ? [BoxShadow(
                  color: Color.fromRGBO(0, 229, 255, 0.15 + _pulseCtl.value * 0.1),
                  blurRadius: 30, spreadRadius: 2)]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Stack(children: [
                if (isScanning && _scannerController != null)
                  MobileScanner(
                    controller: _scannerController!,
                    onDetect: (capture) {
                      final barcode = capture.barcodes.firstOrNull;
                      if (barcode?.rawValue != null) _onQrDetected(barcode!.rawValue!);
                    },
                  ),
                if (!isScanning && !isVerifying)
                  const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.qr_code_scanner, size: 70,
                          color: Color.fromRGBO(255, 255, 255, 0.08)),
                      SizedBox(height: 12),
                      Text("Tap 'Scan QR Code' to begin",
                          style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.15), fontSize: 12)),
                    ]),
                  ),
                if (isScanning)
                  Positioned(
                    top: 260 * _scanLineCtl.value - 2, left: 0, right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          Colors.transparent,
                          Color.fromRGBO(0, 229, 255, 0.8),
                          _accent,
                          Color.fromRGBO(0, 229, 255, 0.8),
                          Colors.transparent,
                        ]),
                        boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 229, 255, 0.6), blurRadius: 8, spreadRadius: 2)],
                      ),
                    ),
                  ),
                if (isVerifying)
                  Container(
                    color: const Color.fromRGBO(0, 0, 0, 0.7),
                    child: const Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(
                          width: 50, height: 50,
                          child: CircularProgressIndicator(
                            color: _accent, strokeWidth: 2.5,
                            backgroundColor: Color.fromRGBO(0, 229, 255, 0.1),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text('Verifying...', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('Checking GPS & session...', style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.35), fontSize: 11)),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        if (isScanning || isVerifying) ...[
          _corner(top: true,  left: true),
          _corner(top: true,  left: false),
          _corner(top: false, left: true),
          _corner(top: false, left: false),
        ],
      ]);
    },
  );

  Widget _corner({required bool top, required bool left}) => Positioned(
    top:    top  ? (132 - 130 * _cornerAnim.value) : null,
    bottom: top  ? null : (132 - 130 * _cornerAnim.value),
    left:   left ? (108 - 130 * _cornerAnim.value) : null,
    right:  left ? null : (108 - 130 * _cornerAnim.value),
    child: CustomPaint(
      size: const Size(28, 28),
      painter: _CornerPainter(
        topLeft:     top && left,
        topRight:    top && !left,
        bottomLeft:  !top && left,
        bottomRight: !top && !left,
        color:   _accent,
        opacity: _cornerAnim.value,
      ),
    ),
  );

  Widget _buildStatusText() {
    String text; Color color; IconData icon;
    switch (_state) {
      case ScanState.idle:
        text = "Point camera at teacher's QR code"; color = Colors.white38; icon = Icons.info_outline;
      case ScanState.scanning:
        text = 'Camera active — hold QR steady • Pinch to zoom'; color = _accent; icon = Icons.qr_code_scanner;
      case ScanState.verifying:
        text = 'QR detected! Verifying GPS location...'; color = Colors.amber; icon = Icons.location_searching;
      default:
        text = ''; color = Colors.transparent; icon = Icons.circle;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Row(key: ValueKey(_state), mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Flexible(child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildScanButton() {
    final isActive = _state == ScanState.scanning || _state == ScanState.verifying;
    return AnimatedBuilder(
      animation: _pulseCtl,
      builder: (_, __) => GestureDetector(
        onTap: isActive ? null : _startScan,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: isActive ? null : const LinearGradient(colors: [_accent, Color(0xFF0072FF)]),
            color: isActive ? const Color(0xFF0A1628) : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive
                  ? Color.fromRGBO(0, 229, 255, (0.2 + _pulseCtl.value * 0.15).clamp(0.0, 1.0))
                  : Colors.transparent,
            ),
            boxShadow: isActive ? [] : [
              BoxShadow(color: const Color.fromRGBO(0, 229, 255, 0.3), blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              isActive ? Icons.hourglass_top_rounded : Icons.qr_code_scanner,
              color: isActive ? const Color.fromRGBO(0, 229, 255, 0.5) : Colors.black,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              isActive ? 'Scanning...' : 'Scan QR Code',
              style: TextStyle(
                color: isActive ? const Color.fromRGBO(0, 229, 255, 0.5) : Colors.black,
                fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.3,
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final isSuccess = _state == ScanState.success;
    return AnimatedBuilder(
      animation: Listenable.merge([_resultScale, _resultFade, _successRing]),
      builder: (context, _) => Opacity(
        opacity: _resultFade.value,
        child: Transform.scale(
          scale: _resultScale.value,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(children: [
              const Spacer(),
              Stack(alignment: Alignment.center, children: [
                if (isSuccess)
                  ...List.generate(3, (i) {
                    final delay    = i * 0.25;
                    final progress = (_successRing.value - delay).clamp(0.0, 1.0);
                    return Container(
                      width:  120 + progress * (80 + i * 30),
                      height: 120 + progress * (80 + i * 30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color.fromRGBO(0, 230, 118, (1 - progress) * 0.3),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(isSuccess ? 0 : 255, isSuccess ? 230 : 23, isSuccess ? 118 : 68, 0.12),
                    border: Border.all(color: isSuccess ? _success : _fail, width: 2),
                    boxShadow: [BoxShadow(
                      color: Color.fromRGBO(isSuccess ? 0 : 255, isSuccess ? 230 : 23, isSuccess ? 118 : 68, 0.3),
                      blurRadius: 40, spreadRadius: 5,
                    )],
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_rounded : Icons.close_rounded,
                    color: isSuccess ? _success : _fail, size: 56,
                  ),
                ),
              ]),
              const SizedBox(height: 36),
              Text(
                isSuccess ? 'Attendance Marked!' : 'Verification Failed',
                style: TextStyle(
                  color: isSuccess ? _success : _fail,
                  fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSuccess
                    ? 'Your attendance has been successfully\nrecorded for this session'
                    : _failReason.isEmpty ? 'Could not verify attendance.\nPlease try again.' : _failReason,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.45), fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 32),
              if (isSuccess) _buildSuccessDetails() else _buildFailDetails(),
              const Spacer(),
              if (isSuccess)
                _buildResultButton(
                  label: 'Done', icon: Icons.home_outlined,
                  gradient: [_success, const Color(0xFF00A651)],
                  onTap: () => Navigator.pop(context),
                )
              else ...[
                _buildResultButton(
                  label: 'Try Again', icon: Icons.refresh_rounded,
                  gradient: [_accent, const Color(0xFF0072FF)],
                  onTap: _reset,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('Go Back',
                      style: TextStyle(color: Color.fromRGBO(255, 255, 255, 0.35),
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessDetails() => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color.fromRGBO(0, 230, 118, 0.07),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color.fromRGBO(0, 230, 118, 0.2)),
    ),
    child: Column(children: [
      _detailRow(Icons.verified_rounded,     'Status',    'Present ✓'),
      const SizedBox(height: 12),
      _detailRow(Icons.access_time,          'Marked At', _formattedTime()),
      const SizedBox(height: 12),
      _detailRow(Icons.location_on_outlined, 'Distance',
          _distanceM > 0 ? '${_distanceM}m from class ✓' : 'Within range ✓'),
      const SizedBox(height: 12),
      _detailRow(Icons.badge_outlined, 'Session ID',
          _scannedSessionId.length > 8 ? '${_scannedSessionId.substring(0, 8)}...' : _scannedSessionId),
    ]),
  );

  Widget _buildFailDetails() => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color.fromRGBO(255, 23, 68, 0.07),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color.fromRGBO(255, 23, 68, 0.2)),
    ),
    child: Column(children: [
      if (_failReason.isNotEmpty) ...[
        Container(
          width: double.infinity, padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 23, 68, 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(_failReason,
              style: const TextStyle(color: Color(0xFFFF6B8A), fontSize: 12, height: 1.5)),
        ),
        const SizedBox(height: 14),
      ],
      Row(children: const [
        Icon(Icons.warning_amber_rounded, color: _fail, size: 18),
        SizedBox(width: 10),
        Text('Common causes:', style: TextStyle(color: _fail, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
      const SizedBox(height: 12),
      ...[
        'QR code has expired — rescan fresh QR',
        'Outside the allowed radius (100m)',
        'Session was closed by teacher',
        'GPS accuracy too low — go outdoors',
        'Already marked for this session',
      ].map((r) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          Container(width: 5, height: 5,
              decoration: const BoxDecoration(color: Color.fromRGBO(255, 255, 255, 0.25), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(r,
              style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.45), fontSize: 12, height: 1.4))),
        ]),
      )),
    ]),
  );

  Widget _detailRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, color: const Color.fromRGBO(255, 255, 255, 0.35), size: 16),
    const SizedBox(width: 10),
    Text(label, style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.35), fontSize: 12, fontWeight: FontWeight.w500)),
    const Spacer(),
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
  ]);

  Widget _buildResultButton({
    required String label, required IconData icon,
    required List<Color> gradient, required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: gradient.first.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.black, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
      ]),
    ),
  );

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const AttendanceHistorySheet(),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _formattedTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class AttendanceHistorySheet extends StatefulWidget {
  const AttendanceHistorySheet({super.key});
  @override
  State<AttendanceHistorySheet> createState() => _AttendanceHistorySheetState();
}

class _AttendanceHistorySheetState extends State<AttendanceHistorySheet> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await AttendanceApi.getStudentHistory();
      if (data['success'] == true && mounted) {
        setState(() => _history = List<Map<String, dynamic>>.from(data['records'] ?? []));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1623),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, 0.2), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [
          const Text('Attendance History',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 229, 255, 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color.fromRGBO(0, 229, 255, 0.3)),
            ),
            child: const Text('Live Data',
                style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 2),
          )
        else if (_history.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Icon(Icons.event_busy, color: Colors.white.withValues(alpha: 0.2), size: 48),
              const SizedBox(height: 12),
              Text('No attendance records yet',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 14)),
            ]),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _history.length,
              itemBuilder: (_, i) {
                final h        = _history[i];
                final title    = h['title']     ?? 'Session';
                final markedAt = h['marked_at'] ?? '';
                final distM    = h['distance_m'] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 230, 118, 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color.fromRGBO(0, 230, 118, 0.15)),
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 230, 118, 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_outline, color: Color(0xFF00E676), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('${distM}m away  •  $markedAt',
                          style: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.35), fontSize: 11)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 230, 118, 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color.fromRGBO(0, 230, 118, 0.3)),
                      ),
                      child: const Text('PRESENT',
                          style: TextStyle(color: Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ]),
                );
              },
            ),
          ),
      ]),
    );
  }
}

class _StudentBgPainter extends CustomPainter {
  final double progress;
  _StudentBgPainter({required this.progress});

  void _orb(Canvas c, Offset center, double r, Color color, double opacity) {
    c.drawCircle(center, r, Paint()
      ..shader = RadialGradient(colors: [
        color.withValues(alpha: opacity),
        color.withValues(alpha: opacity * 0.3),
        color.withValues(alpha: 0),
      ]).createShader(Rect.fromCircle(center: center, radius: r)));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ease = Curves.easeInOut.transform(progress);
    _orb(canvas, Offset(size.width * 0.8,  size.height * 0.1  - ease * 12), size.width * 0.55, const Color(0xFF003A45), 0.5);
    _orb(canvas, Offset(-size.width * 0.1  + ease * 10, size.height * 0.55), size.width * 0.5,  const Color(0xFF001830), 0.45);
    _orb(canvas, Offset(size.width * 0.5,  size.height * 0.9),               size.width * 0.4,  const Color(0xFF002040), 0.3);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.018)
      ..strokeWidth = 0.6..style = PaintingStyle.stroke;

    for (int i = 0; i < 12; i++) {
      final x = (size.width / 11) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (int i = 0; i < 22; i++) {
      final y    = (size.height / 21) * i;
      final wave = 4.0 * sin(i * 0.5 + ease * 2);
      canvas.drawLine(Offset(0, y + wave), Offset(size.width, y + wave), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _StudentBgPainter old) => old.progress != progress;
}

class _CornerPainter extends CustomPainter {
  final bool topLeft, topRight, bottomLeft, bottomRight;
  final Color  color;
  final double opacity;

  const _CornerPainter({
    required this.topLeft,    required this.topRight,
    required this.bottomLeft, required this.bottomRight,
    required this.color,      required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color      = color.withValues(alpha: opacity.clamp(0.0, 1.0))
      ..strokeWidth = 3
      ..style      = PaintingStyle.stroke
      ..strokeCap  = StrokeCap.round;

    const len = 22.0, r = 6.0;

    if (topLeft) {
      canvas.drawLine(const Offset(r, 0), const Offset(len, 0), paint);
      canvas.drawLine(const Offset(0, r), const Offset(0, len), paint);
      canvas.drawArc(const Rect.fromLTWH(0, 0, r * 2, r * 2), pi, pi / 2, false, paint);
    }
    if (topRight) {
      canvas.drawLine(Offset(size.width - len, 0), Offset(size.width - r, 0), paint);
      canvas.drawLine(Offset(size.width, r),        Offset(size.width, len), paint);
      canvas.drawArc(Rect.fromLTWH(size.width - r * 2, 0, r * 2, r * 2), -pi / 2, pi / 2, false, paint);
    }
    if (bottomLeft) {
      canvas.drawLine(Offset(r, size.height),       Offset(len, size.height), paint);
      canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height - r), paint);
      canvas.drawArc(Rect.fromLTWH(0, size.height - r * 2, r * 2, r * 2), pi / 2, pi / 2, false, paint);
    }
    if (bottomRight) {
      canvas.drawLine(Offset(size.width - len, size.height), Offset(size.width - r, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height - len), Offset(size.width, size.height - r),  paint);
      canvas.drawArc(Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2), 0, pi / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter old) => old.opacity != opacity || old.color != color;
}