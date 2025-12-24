/// AI Chat Data Source
/// 
/// Google Gemini API integration for AI ChatBot with system data access.

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/issue.dart';
import 'user_datasource.dart';
import 'project_datasource.dart';
import 'issue_datasource.dart';
import 'attendance_datasource.dart';

abstract class AIChatDataSource {
  /// Send a message to the AI and get a response
  Future<String> sendMessage(String message, List<AIChatMessage> history);
  
  /// Start a new conversation (clear context)
  void startNewConversation();
  
  /// Save chat history to local storage
  Future<void> saveHistory(List<AIChatMessage> messages);
  
  /// Load chat history from local storage
  Future<List<AIChatMessage>> loadHistory();
  
  /// Clear saved history
  Future<void> clearHistory();
  
  /// Set current user context
  void setUserContext(User user);
  
  /// Refresh system data context
  Future<void> refreshSystemContext();
}

class AIChatDataSourceImpl implements AIChatDataSource {
  final String _apiKey;
  final SharedPreferences _prefs;
  late GenerativeModel _model;
  ChatSession? _chatSession;
  User? _currentUser;
  String _systemDataContext = '';
  
  static const String _historyKey = 'ai_chat_history';

  // Base system prompt
  static const String _baseSystemPrompt = '''
Bạn là trợ lý AI thông minh cho ứng dụng quản lý doanh nghiệp. 
Bạn có quyền truy cập vào dữ liệu thực của hệ thống và có thể trả lời các câu hỏi dựa trên dữ liệu này.

Bạn có thể giúp đỡ về:
- Quản lý nhân sự: chấm công, nghỉ phép, thông tin nhân viên
- Quản lý dự án: tạo dự án, theo dõi tiến độ, quản lý task, giao việc
- Thống kê và báo cáo: tổng quan dự án, tiến độ công việc
- Các câu hỏi chung về công việc và hệ thống

Hãy trả lời ngắn gọn, chính xác và hữu ích. Luôn sử dụng tiếng Việt.
Khi trả lời về dữ liệu, hãy dựa vào thông tin context được cung cấp.
Nếu không có dữ liệu liên quan, hãy nói rõ rằng bạn không có thông tin về vấn đề đó.
''';

  AIChatDataSourceImpl({
    required String apiKey,
    required SharedPreferences prefs,
  }) : _apiKey = apiKey,
       _prefs = prefs {
    _initModel();
  }

  void _initModel() {
    final fullPrompt = _buildFullSystemPrompt();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(fullPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
    _chatSession = _model.startChat();
  }

  String _buildFullSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln(_baseSystemPrompt);
    
    if (_currentUser != null) {
      buffer.writeln('\n--- THÔNG TIN NGƯỜI DÙNG HIỆN TẠI ---');
      buffer.writeln('Tên: ${_currentUser!.displayName ?? "Chưa cập nhật"}');
      buffer.writeln('Email: ${_currentUser!.email}');
      buffer.writeln('Vai trò: ${_currentUser!.role.displayName}');
      if (_currentUser!.departmentId != null) {
        buffer.writeln('Phòng ban ID: ${_currentUser!.departmentId}');
      }
      if (_currentUser!.position != null) {
        buffer.writeln('Chức vụ: ${_currentUser!.position}');
      }
    }
    
    if (_systemDataContext.isNotEmpty) {
      buffer.writeln('\n--- DỮ LIỆU HỆ THỐNG ---');
      buffer.writeln(_systemDataContext);
    }
    
    return buffer.toString();
  }

  @override
  void setUserContext(User user) {
    _currentUser = user;
    _reinitializeModel();
  }

  @override
  Future<void> refreshSystemContext() async {
    if (_currentUser == null) return;
    
    final buffer = StringBuffer();
    
    try {
      // Load user's projects
      final projectDatasource = ProjectDataSourceImpl();
      final projects = await projectDatasource.getProjectsByUser(_currentUser!.id);
      
      if (projects.isNotEmpty) {
        buffer.writeln('\n[DỰ ÁN CỦA BẠN]');
        for (final project in projects) {
          final p = project.toEntity();
          buffer.writeln('- "${p.name}" (${p.status.displayName}, tiến độ: ${p.progress}%)');
        }
        
        // Load issues for each project
        final issueDatasource = IssueDataSourceImpl();
        int totalTodo = 0;
        int totalInProgress = 0;
        int totalDone = 0;
        final List<Issue> allIssues = [];
        
        for (final project in projects.take(5)) { // Limit to 5 projects
          final issues = await issueDatasource.getIssuesByProject(project.id);
          for (final issue in issues) {
            final i = issue.toEntity();
            allIssues.add(i);
            switch (i.status) {
              case IssueStatus.todo:
                totalTodo++;
                break;
              case IssueStatus.inProgress:
                totalInProgress++;
                break;
              case IssueStatus.done:
                totalDone++;
                break;
              default:
                break;
            }
          }
        }
        
        buffer.writeln('\n[THỐNG KÊ CÔNG VIỆC]');
        buffer.writeln('- Chờ xử lý: $totalTodo');
        buffer.writeln('- Đang làm: $totalInProgress');
        buffer.writeln('- Hoàn thành: $totalDone');
        
        // Issues assigned to user
        final myIssues = allIssues.where((i) => i.assigneeId == _currentUser!.id).toList();
        if (myIssues.isNotEmpty) {
          buffer.writeln('\n[CÔNG VIỆC ĐƯỢC GIAO CHO BẠN]');
          for (final issue in myIssues.take(10)) {
            buffer.writeln('- "${issue.title}" (${issue.status.displayName}, ưu tiên: ${issue.priority.displayName})');
          }
        }
      }
      
      // Load attendance (this month)
      try {
        final attendanceDatasource = AttendanceDataSourceImpl();
        final today = DateTime.now();
        final attendances = await attendanceDatasource.getMonthlyAttendance(
          _currentUser!.id, 
          today.year,
          today.month,
        );
        
        if (attendances.isNotEmpty) {
          int presentDays = attendances.where((a) => a.checkInTime != null).length;
          buffer.writeln('\n[CHẤM CÔNG THÁNG NÀY]');
          buffer.writeln('- Số ngày đã chấm công: $presentDays');
        }
      } catch (_) {}
      
    } catch (e) {
      buffer.writeln('\nLỗi khi tải dữ liệu: ${e.toString()}');
    }
    
    _systemDataContext = buffer.toString();
    _reinitializeModel();
  }

  void _reinitializeModel() {
    final fullPrompt = _buildFullSystemPrompt();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(fullPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
      ),
    );
    _chatSession = _model.startChat();
  }

  @override
  Future<String> sendMessage(String message, List<AIChatMessage> history) async {
    try {
      // Ensure chat session exists
      _chatSession ??= _model.startChat();

      // Send message and get response
      final response = await _chatSession!.sendMessage(Content.text(message));
      
      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        return 'Xin lỗi, tôi không thể xử lý yêu cầu này. Vui lòng thử lại.';
      }

      return responseText;
    } catch (e) {
      // Return actual error for debugging
      return 'Lỗi: ${e.toString()}';
    }
  }

  @override
  void startNewConversation() {
    _chatSession = _model.startChat();
  }
  
  @override
  Future<void> saveHistory(List<AIChatMessage> messages) async {
    final jsonList = messages.map((m) => {
      'id': m.id,
      'content': m.content,
      'role': m.role == AIChatRole.user ? 'user' : 'assistant',
      'timestamp': m.timestamp.toIso8601String(),
    }).toList();
    
    await _prefs.setString(_historyKey, jsonEncode(jsonList));
  }
  
  @override
  Future<List<AIChatMessage>> loadHistory() async {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => AIChatMessage(
        id: json['id'] as String,
        content: json['content'] as String,
        role: json['role'] == 'user' ? AIChatRole.user : AIChatRole.assistant,
        timestamp: DateTime.parse(json['timestamp'] as String),
      )).toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }
}
