import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const String kBaseUrl = 'https://plastics-venice-potter-abu.trycloudflare.com';
const Duration kTimeout = Duration(seconds: 20);

class SessionStore {
  static const _token    = 'token';
  static const _role     = 'user_role';
  static const _name     = 'name';
  static const _userId   = 'user_id';
  static const _deviceId = 'deviceId';
  static const _fcmToken = 'fcm_token';

  static Future<void> save({
    required String token,
    required String role,
    required String name,
    required int userId,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_token,  token);
    await p.setString(_role,   role);
    await p.setString(_name,   name);
    await p.setInt(_userId,    userId);

    // FCM token save karo aur backend ko bhejo
    await _saveFcmToken(userId, token);
  }

  // FCM token save + backend sync
  static Future<void> _saveFcmToken(int userId, String authToken) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final p = await SharedPreferences.getInstance();
      final oldToken = p.getString(_fcmToken);

      // Sirf tab update karo jab token change ho
      if (oldToken != fcmToken) {
        await p.setString(_fcmToken, fcmToken);
        // Backend ko FCM token bhejo
        await http.post(
          Uri.parse('$kBaseUrl/api/fcm/token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'userId': userId,
            'fcmToken': fcmToken,
            'platform': Platform.isAndroid ? 'android' : 'ios',
          }),
        ).timeout(kTimeout);
      }
    } catch (_) {
      // FCM token save fail ho toh app crash na kare
    }
  }

  // FCM token refresh listener — app mein call karo
  static void listenFcmTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final p = await SharedPreferences.getInstance();
      final authToken = p.getString(_token);
      final userId = p.getInt(_userId);
      if (authToken == null || userId == null) return;

      await p.setString(_fcmToken, newToken);
      try {
        await http.post(
          Uri.parse('$kBaseUrl/api/fcm/token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'userId': userId,
            'fcmToken': newToken,
            'platform': Platform.isAndroid ? 'android' : 'ios',
          }),
        ).timeout(kTimeout);
      } catch (_) {}
    });
  }

  static Future<String?> get token     async => (await SharedPreferences.getInstance()).getString(_token);
  static Future<String?> get role      async => (await SharedPreferences.getInstance()).getString(_role);
  static Future<String?> get name      async => (await SharedPreferences.getInstance()).getString(_name);
  static Future<int?>    get userId    async => (await SharedPreferences.getInstance()).getInt(_userId);
  static Future<String?> get deviceId  async => (await SharedPreferences.getInstance()).getString(_deviceId);
  static Future<String?> get fcmToken  async => (await SharedPreferences.getInstance()).getString(_fcmToken);
  static Future<bool>    get isLoggedIn async => (await token) != null;
  static Future<void>    clear() async => (await SharedPreferences.getInstance()).clear();
}

class _Http {
  static Future<Map<String, String>> get _headers async {
    final t = await SessionStore.token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  static Map<String, dynamic> _parse(http.Response res) {
    try {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response (${res.statusCode})'};
    }
  }

  static Map<String, dynamic> _error(Object e) {
    if (e is SocketException) return {'success': false, 'message': 'Connection error. Check internet.'};
    return {'success': false, 'message': 'Request failed: $e'};
  }

  static Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) async {
    try {
      final uri = Uri.parse('$kBaseUrl$path').replace(queryParameters: query);
      final res = await http.get(uri, headers: await _headers).timeout(kTimeout);
      return _parse(res);
    } catch (e) { return _error(e); }
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(Uri.parse('$kBaseUrl$path'), headers: await _headers, body: jsonEncode(body))
          .timeout(kTimeout);
      return _parse(res);
    } catch (e) { return _error(e); }
  }

  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .put(Uri.parse('$kBaseUrl$path'), headers: await _headers, body: jsonEncode(body))
          .timeout(kTimeout);
      return _parse(res);
    } catch (e) { return _error(e); }
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .patch(Uri.parse('$kBaseUrl$path'), headers: await _headers, body: jsonEncode(body))
          .timeout(kTimeout);
      return _parse(res);
    } catch (e) { return _error(e); }
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http
          .delete(Uri.parse('$kBaseUrl$path'), headers: await _headers)
          .timeout(kTimeout);
      return _parse(res);
    } catch (e) { return _error(e); }
  }
}

Dio _dio() => Dio(BaseOptions(
  baseUrl:        kBaseUrl,
  connectTimeout: kTimeout,
  receiveTimeout: const Duration(seconds: 120),
));

Future<Options> _dioOpts() async {
  final t = await SessionStore.token;
  return Options(headers: {if (t != null) 'Authorization': 'Bearer $t'});
}

class AuthApi {
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String role,
  }) async {
    final res = await _Http.post('/auth/login', {
      'username': username.trim(),
      'password': password,
      'role':     role.toUpperCase(),
    });
    if (res['success'] == true) {
      await SessionStore.save(
        token:  res['token'],
        role:   res['role'],
        name:   res['name'],
        userId: res['userId'],
      );
    }
    return res;
  }
  static Future<void> logout() => SessionStore.clear();
}

class AdminApi {
  static Future<Map<String, dynamic>> getUsers({String? role, String? search}) =>
      _Http.get('/admin/users', query: {
        if (role   != null) 'role':   role,
        if (search != null) 'search': search,
      });

  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String name,
    required String password,
    required String role,
    String batch    = '',
    int    semester = 0,
  }) =>
      _Http.post('/admin/users', {
        'username': username, 'name': name, 'password': password,
        'role': role, 'batch': batch, 'semester': semester,
      });

  static Future<Map<String, dynamic>> updateUser({
    required int    userId,
    required String name,
    required String role,
    required bool   isAllowed,
    String?  password,
    String   batch    = '',
    int      semester = 0,
  }) =>
      _Http.put('/admin/users/$userId', {
        'name': name, 'role': role, 'is_allowed': isAllowed,
        'batch': batch, 'semester': semester,
        if (password != null) 'password': password,
      });

  static Future<Map<String, dynamic>> deleteUser(int userId) =>
      _Http.delete('/admin/users/$userId');

  static Future<Map<String, dynamic>> toggleUser(int userId) =>
      _Http.patch('/admin/users/$userId/toggle', {});

  static Future<Map<String, dynamic>> getClasses() =>
      _Http.get('/admin/classes');

  static Future<Map<String, dynamic>> createClass({
    required String name,
    required int    teacherId,
    String subject  = '',
    String icon     = '📚',
    String color    = '#6C63FF',
    List<int> studentIds = const [],
  }) =>
      _Http.post('/admin/classes', {
        'name': name, 'subject': subject, 'icon': icon,
        'color': color, 'teacherId': teacherId, 'studentIds': studentIds,
      });

  static Future<Map<String, dynamic>> updateClass({
    required int    classId,
    required String name,
    required int    teacherId,
    String subject  = '',
    String icon     = '📚',
    String color    = '#6C63FF',
    List<int>? studentIds,
  }) =>
      _Http.put('/admin/classes/$classId', {
        'name': name, 'subject': subject, 'icon': icon,
        'color': color, 'teacherId': teacherId,
        if (studentIds != null) 'studentIds': studentIds,
      });

  static Future<Map<String, dynamic>> deleteClass(int classId) =>
      _Http.delete('/admin/classes/$classId');

  static Future<Map<String, dynamic>> addStudentToClass(int classId, int studentId) =>
      _Http.post('/admin/classes/$classId/students', {'studentId': studentId, 'action': 'add'});

  static Future<Map<String, dynamic>> removeStudentFromClass(int classId, int studentId) =>
      _Http.post('/admin/classes/$classId/students', {'studentId': studentId, 'action': 'remove'});
}

class TeacherApi {
  static Future<Map<String, dynamic>> getMyClasses() =>
      _Http.get('/teacher/classes');
}

class AttendanceApi {
  static Future<Map<String, dynamic>> startSession({
    required String title,
    required double lat,
    required double lng,
    required int    classId,
    int radiusM         = 100,
    int accuracyM       = 50,
    int durationMinutes = 60,
    int nonceTtlSeconds = 20,
  }) =>
      _Http.post('/attendance/start', {
        'title': title, 'lat': lat, 'lng': lng, 'classId': classId,
        'radiusM': radiusM, 'accuracyM': accuracyM,
        'durationMinutes': durationMinutes,
        'nonceTtlSeconds': nonceTtlSeconds,
      });

  static Future<Map<String, dynamic>> refreshNonce({
    required String sessionId,
    int ttlSeconds = 20,
  }) =>
      _Http.post('/attendance/nonce', {'sessionId': sessionId, 'ttlSeconds': ttlSeconds});

  static Future<Map<String, dynamic>> closeSession(String sessionId) =>
      _Http.post('/attendance/close', {'sessionId': sessionId});

  static Future<Map<String, dynamic>> getSessions({String? date, int? classId}) =>
      _Http.get('/attendance/sessions', query: {
        if (date    != null) 'date':    date,
        if (classId != null) 'classId': classId.toString(),
      });

  static Future<Map<String, dynamic>> markAttendance({
    required String sessionId,
    required String nonce,
    required double lat,
    required double lng,
    required int    accuracyM,
    required String deviceId,
  }) =>
      _Http.post('/attendance/mark', {
        'sessionId': sessionId, 'nonce': nonce,
        'lat': lat, 'lng': lng,
        'accuracyM': accuracyM, 'deviceId': deviceId,
      });

  static Future<Map<String, dynamic>> getStudentHistory() =>
      _Http.get('/attendance/student');

  static Future<Map<String, dynamic>> getRoster(String sessionId) =>
      _Http.get('/attendance/roster', query: {'sessionId': sessionId});
}

class LectureApi {
  static Future<Map<String, dynamic>> uploadLecture({
    required String videoFilePath,
    required String title,
    String subject  = '',
    String category = '',
    int?   classId,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'subject': subject,
        'category': category,
        if (classId != null) 'classId': classId.toString(),
        'video': await MultipartFile.fromFile(
          videoFilePath,
          filename: videoFilePath.split('/').last,
        ),
      });

      final res = await _dio().post(
        '/lectures/upload',
        data: formData,
        options: await _dioOpts(),
        onSendProgress: onProgress,
      );

      return res.data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteLecture(int id) =>
      _Http.delete('/lectures/$id');

  static Future<Map<String, dynamic>> getLectures() =>
      _Http.get('/lectures');

  static Future<Map<String, dynamic>> getBookmarks() =>
      _Http.get('/bookmarks');

  static Future<Map<String, dynamic>> toggleBookmark(int lectureId) =>
      _Http.post('/bookmarks/toggle', {'lectureId': lectureId});
}

class MarksApi {
  static Future<Map<String, dynamic>> getMyMarks() => _Http.get('/marks/student');
}

class QuizApi {
  static Future<Map<String, dynamic>> getTeacherQuizzes() =>
      _Http.get('/api/quiz/teacher');
  static Future<Map<String, dynamic>> notifyStudents(int quizId) =>
      _Http.post('/api/quiz/$quizId/notify', {});

  static Future<Map<String, dynamic>> createQuiz({
    required String title,
    required int totalMarks,
    required List<Map<String, dynamic>> questions,
  }) =>
      _Http.post('/api/quiz/create', {
        'title': title,
        'totalMarks': totalMarks,
        'questions': questions,
      });

  static Future<Map<String, dynamic>> updateQuiz({
    required int quizId,
    required String title,
    required int totalMarks,
    required List<Map<String, dynamic>> questions,
  }) =>
      _Http.put('/api/quiz/$quizId', {
        'title': title,
        'totalMarks': totalMarks,
        'questions': questions,
      });

  static Future<Map<String, dynamic>> getQuizFull(int quizId) =>
      _Http.get('/api/quiz/$quizId/full');

  static Future<Map<String, dynamic>> duplicateQuiz(int quizId) =>
      _Http.post('/api/quiz/$quizId/duplicate', {});

  static Future<Map<String, dynamic>> deleteQuiz(int quizId) =>
      _Http.delete('/api/quiz/$quizId');

  static Future<Map<String, dynamic>> getQuizResults(int quizId) =>
      _Http.get('/api/quiz/$quizId/results');

  static Future<Map<String, dynamic>> getStudentQuizzes() =>
      _Http.get('/api/quiz/student');

  static Future<Map<String, dynamic>> getQuizByLink(int quizId) =>
      _Http.get('/api/quiz/by-link/$quizId');

  static Future<Map<String, dynamic>> getQuizQuestions(int quizId) =>
      _Http.get('/api/quiz/$quizId/questions');

  static Future<Map<String, dynamic>> submitQuiz({
    required int quizId,
    required Map<String, String> answers,
    bool cheated = false,
  }) =>
      _Http.post('/api/quiz/$quizId/submit', {
        'answers': answers,
        'cheated': cheated,
      });
}
// ═══════════════════════════════════════════════════════════════════════════════
// HOMEWORK API
// ═══════════════════════════════════════════════════════════════════════════════

class HomeworkApi {
  // ── Teacher ───���──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getTeacherHomeworks() =>
      _Http.get('/homework/teacher');

  static Future<Map<String, dynamic>> createHomework({
    required int    classId,
    required String title,
    required String description,
    required String dueDate,
    List<String>    filePaths = const [],
  }) async {
    try {
      final token = await SessionStore.token; // ✅ .token getter
      final uri   = Uri.parse('$kBaseUrl/homework/create'); // ✅ kBaseUrl
      final req   = http.MultipartRequest('POST', uri);
      if (token != null) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      req.fields['classId']     = classId.toString();
      req.fields['title']       = title;
      req.fields['description'] = description;
      req.fields['dueDate']     = dueDate;
      for (final path in filePaths) {
        req.files.add(
          await http.MultipartFile.fromPath(
            'files', path,
            filename: path.split('/').last,
          ),
        );
      }
      final streamed = await req.send();
      final res      = await http.Response.fromStream(streamed);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSubmissions(
      int homeworkId) =>
      _Http.get('/homework/$homeworkId/submissions');

  static Future<Map<String, dynamic>> deleteHomework(
      int homeworkId) =>
      _Http.delete('/homework/$homeworkId');

  // ── Student ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStudentHomeworks() =>
      _Http.get('/homework/student');

  static Future<Map<String, dynamic>> submitHomework({
    required int    homeworkId,
    required String note,
    String?         filePath,
  }) async {
    try {
      final token = await SessionStore.token; // ✅ .token getter
      final uri   = Uri.parse(
          '$kBaseUrl/homework/$homeworkId/submit'); // ✅ kBaseUrl
      final req   = http.MultipartRequest('POST', uri);
      if (token != null) {
        req.headers['Authorization'] = 'Bearer $token';
      }
      req.fields['note'] = note;
      if (filePath != null &&
          filePath.isNotEmpty &&
          !filePath.startsWith('/mock')) {
        req.files.add(
          await http.MultipartFile.fromPath(
            'file', filePath,
            filename: filePath.split('/').last,
          ),
        );
      }
      final streamed = await req.send();
      final res      = await http.Response.fromStream(streamed);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}