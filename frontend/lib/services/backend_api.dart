import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;

import '../models/analysis_models.dart';
import '../models/auth_response.dart';
import '../models/backend_models.dart';
import '../models/budget_models.dart';
import '../models/goal_chat_conversation.dart';
import '../models/goal_chat_history.dart';
import '../models/user_profile.dart';
import '../models/voice_session_models.dart';
import 'download_helper.dart' if (dart.library.html) 'download_helper_web.dart' as downloader;

class BackendApi {
  /// Local backend URL; adjust to `http://10.0.2.2:8081` when using Android emulators.
  ///
  /// We prefer the loopback IP to avoid the Windows/Chrome habit of resolving
  /// `localhost` to IPv6 (`::1`), which can lead to spurious
  /// `ERR_CONNECTION_REFUSED` errors when Tomcat only binds to IPv4.
  static const String _defaultBaseUrl = 'http://127.0.0.1:8081';

  final String baseUrl;
  final http.Client _client;

  BackendApi({
    this.baseUrl = _defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    final response = await _client.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'password': password}),
    );
    _verifySuccess(response);
    return AuthResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
    String? location,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final body = {
      'email': email,
      'password': password,
      if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
      if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      if (location != null && location.isNotEmpty) 'location': location,
    };
    final response = await _client.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode(body),
    );
    _verifySuccess(response);
    return AuthResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<PasswordResetRequestResult> requestPasswordResetCode({required String email}) async {
    final uri = Uri.parse('$baseUrl/auth/password-reset/request');
    final response = await _client.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode({'email': email}),
    );
    _verifySuccess(response);
    if (response.body.isEmpty) {
      return const PasswordResetRequestResult(emailSent: true);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return PasswordResetRequestResult.fromJson(data);
  }

  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/password-reset/confirm');
    final response = await _client.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email,
        'code': code,
        'newPassword': newPassword,
      }),
    );
    _verifySuccess(response);
  }

  Future<StartSessionResponse> startSession({
    required String email,
    required String displayName,
    required String goalTitle,
    required double targetAmount,
    required DateTime targetDate,
  }) async {
    final uri = Uri.parse('$baseUrl/voice/sessions/start');
    final body = jsonEncode({
      'email': email,
      'displayName': displayName,
      'goalTitle': goalTitle,
      'targetAmount': targetAmount.toStringAsFixed(2),
      'targetDate': _formatDate(targetDate),
    });

    final response = await _client.post(uri, headers: _jsonHeaders, body: body);
    _verifySuccess(response);
    return StartSessionResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<VoiceResponse> sendVoiceInput({
    required int sessionId,
    required String transcript,
    String language = 'fr',
  }) async {
    final uri = Uri.parse('$baseUrl/voice/voice-input');
    final body = jsonEncode({
      'sessionId': sessionId,
      'transcript': transcript,
      'language': language,
    });

    final response = await _client.post(uri, headers: _jsonHeaders, body: body);
    _verifySuccess(response);
    return VoiceResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<VoiceSessionStartResponse> startGoalChatSession({
    required int userId,
    required String goalId,
    required String goalLabel,
  }) async {
    final uri = Uri.parse('$baseUrl/api/voice/start');
    final response = await _client.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode({
        'userId': userId,
        'goalId': goalId,
        'goalLabel': goalLabel,
      }),
    );
    _verifySuccess(response);
    return VoiceSessionStartResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<VoiceMessageResponse> sendGoalChatMessage({
    required int userId,
    required String sessionId,
    required String message,
  }) async {
    final uri = Uri.parse('$baseUrl/api/voice/message');
    final response = await _client.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode({
        'userId': userId,
        'sessionId': sessionId,
        'message': message,
      }),
    );
    _verifySuccess(response);
    return VoiceMessageResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<GoalChatHistoryItem>> fetchGoalChatHistory({
    required int userId,
    int limit = 30,
  }) async {
    final uri = Uri.parse('$baseUrl/api/voice/history?userId=$userId&limit=$limit');
    final response = await _client.get(uri, headers: _jsonHeaders);
    _verifySuccess(response);
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((entry) => GoalChatHistoryItem.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  Future<GoalChatConversation> fetchGoalChatConversation({
    required int userId,
    required String sessionId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/voice/history/$sessionId?userId=$userId');
    final response = await _client.get(uri, headers: _jsonHeaders);
    _verifySuccess(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return GoalChatConversation.fromJson(data);
  }

  Future<void> saveGoalChatSession({
    required int userId,
    required String sessionId,
    bool starred = true,
  }) async {
    final uri = Uri.parse('$baseUrl/api/voice/history/save');
    final body = jsonEncode({
      'userId': userId,
      'sessionId': sessionId,
      'starred': starred,
    });
    final response = await _client.post(uri, headers: _jsonHeaders, body: body);
    _verifySuccess(response);
  }

  Future<void> renameGoalChatSession({
    required int userId,
    required String sessionId,
    required String newLabel,
  }) async {
    final uri = Uri.parse('$baseUrl/api/voice/history/rename');
    final body = jsonEncode({
      'userId': userId,
      'sessionId': sessionId,
      'newLabel': newLabel,
    });
    final response = await _client.post(uri, headers: _jsonHeaders, body: body);
    _verifySuccess(response);
  }

  Future<void> deleteGoalChatSession({
    required int userId,
    required String sessionId,
  }) async {
    final uri = Uri.parse('$baseUrl/api/voice/history/$sessionId?userId=$userId');
    final response = await _client.delete(uri, headers: _jsonHeaders);
    _verifySuccess(response);
  }

  Future<BudgetSnapshot> fetchBudgetSnapshot({int? year, int? month}) async {
    final params = <String>[
      if (year != null) 'year=$year',
      if (month != null) 'month=$month',
    ].join('&');
    final uri = Uri.parse(
      params.isEmpty ? '$baseUrl/api/budgets' : '$baseUrl/api/budgets?$params',
    );
    final response = await _client.get(uri, headers: _jsonHeaders);
    _verifySuccess(response);
    return BudgetSnapshot.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<FinancialAnalysis> fetchFinancialAnalysis() async {
    final uri = Uri.parse('$baseUrl/api/analysis');
    final response = await _client.get(uri, headers: _jsonHeaders);
    _verifySuccess(response);
    return FinancialAnalysis.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserProfile> fetchUserProfile(int userId) async {
    final uri = Uri.parse('$baseUrl/api/users/$userId');
    final response = await _client.get(uri, headers: _jsonHeaders);
    _verifySuccess(response);
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserProfile> updateUserProfile({
    required int userId,
    required String displayName,
    required String email,
    String? phoneNumber,
    String? location,
    String? bio,
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/$userId');
    final payload = <String, dynamic>{
      'displayName': displayName,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (location != null) 'location': location,
      if (bio != null) 'bio': bio,
    };
    final response = await _client.put(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );
    _verifySuccess(response);
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<BudgetCategory> createBudget({
    required String category,
    required double amount,
    BudgetPeriodType periodType = BudgetPeriodType.monthly,
    int? periodMonth,
    int? periodYear,
    DateTime? startDate,
    DateTime? endDate,
    int? alertThreshold,
    String? note,
  }) async {
    final now = DateTime.now();
    final payload = _buildBudgetPayload(
      category: category,
      amount: amount,
      periodType: periodType,
      periodMonth: periodMonth ?? now.month,
      periodYear: periodYear ?? now.year,
      startDate: startDate,
      endDate: endDate,
      alertThreshold: alertThreshold,
      note: note,
    );
    final uri = Uri.parse('$baseUrl/api/budgets');
    final response = await _client.post(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );
    _verifySuccess(response);
    return BudgetCategory.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<BudgetCategory> fetchBudget(int id) async {
    final uri = Uri.parse('$baseUrl/api/budgets/$id');
    final response = await _client.get(uri, headers: _jsonHeaders);
    _verifySuccess(response);
    return BudgetCategory.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<BudgetCategory> updateBudget({
    required int id,
    required String category,
    required double amount,
    required BudgetPeriodType periodType,
    required int periodMonth,
    required int periodYear,
    DateTime? startDate,
    DateTime? endDate,
    int? alertThreshold,
    String? note,
  }) async {
    final payload = _buildBudgetPayload(
      category: category,
      amount: amount,
      periodType: periodType,
      periodMonth: periodMonth,
      periodYear: periodYear,
      startDate: startDate,
      endDate: endDate,
      alertThreshold: alertThreshold,
      note: note,
    );
    final uri = Uri.parse('$baseUrl/api/budgets/$id');
    final response = await _client.put(
      uri,
      headers: _jsonHeaders,
      body: jsonEncode(payload),
    );
    _verifySuccess(response);
    return BudgetCategory.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteBudget(int id) async {
    final uri = Uri.parse('$baseUrl/api/budgets/$id');
    final response = await _client.delete(uri, headers: _jsonHeaders);
    _verifySuccess(response);
  }

  void _verifySuccess(http.Response response) {
    final status = response.statusCode;
    if (status >= 200 && status < 300) return;
    String? backendMessage;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        backendMessage = decoded['message'] as String;
      }
    } catch (_) {}
    if (backendMessage != null && backendMessage.isNotEmpty) {
      throw Exception(backendMessage);
    }
    if (status == 401) {
      throw Exception('E-mail ou mot de passe incorrect.');
    }
    if (status == 409) {
      throw Exception('Conflit detecte avec la requete.');
    }
    throw http.ClientException(
      'Backend error $status: ${response.body}',
      Uri.parse(baseUrl),
    );
  }

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  Future<void> downloadAnalysisPdf({int? year, int? month}) async {
    final buffer = StringBuffer('$baseUrl/api/analysis/report.pdf');
    if (year != null || month != null) {
      buffer.write('?');
      final params = <String>[];
      if (year != null) params.add('year=$year');
      if (month != null) params.add('month=$month');
      buffer.write(params.join('&'));
    }
    final uri = Uri.parse(buffer.toString());
    final response = await _client.get(uri);
    _verifySuccess(response);
    if (!kIsWeb) {
      // On mobile/desktop, just drop bytes on the floor; could be saved to storage if needed.
      return;
    }
    final bytes = response.bodyBytes;
    _triggerWebDownload(bytes, 'rapport_financier.pdf');
  }

  void _triggerWebDownload(Uint8List bytes, String filename) {
    downloader.triggerWebDownload(bytes, filename);
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

  Map<String, dynamic> _buildBudgetPayload({
    required String category,
    required double amount,
    required BudgetPeriodType periodType,
    required int periodMonth,
    required int periodYear,
    DateTime? startDate,
    DateTime? endDate,
    int? alertThreshold,
    String? note,
  }) {
    return <String, dynamic>{
      'category': category.trim(),
      'amount': amount,
      'periodType': periodType.apiValue,
      'periodMonth': periodMonth,
      'periodYear': periodYear,
      if (startDate != null) 'startDate': _formatDate(startDate),
      if (endDate != null) 'endDate': _formatDate(endDate),
      if (alertThreshold != null) 'alertThreshold': alertThreshold,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };
  }
}
