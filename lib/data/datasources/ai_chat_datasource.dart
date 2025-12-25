/// AI Chat Data Source
/// 
/// Groq API integration for AI ChatBot with system data access.

import 'dart:convert';
import 'package:dio/dio.dart';
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
  final Dio _dio;
  User? _currentUser;
  String _systemDataContext = '';
  List<Map<String, String>> _conversationHistory = [];
  
  static const String _historyKey = 'ai_chat_history';
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile'; // Groq's best free model

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
    Dio? dio,
  }) : _apiKey = apiKey,
       _prefs = prefs,
       _dio = dio ?? Dio();

  String _buildFullSystemPrompt() {
    final buffer = StringBuffer(_baseSystemPrompt);
    
    if (_currentUser != null) {
      buffer.writeln('\n--- THÔNG TIN NGƯỜI DÙNG HIỆN TẠI ---');
      buffer.writeln('Tên: ${_currentUser!.displayName}');
      buffer.writeln('Email: ${_currentUser!.email}');
      buffer.writeln('Vai trò: ${_currentUser!.isProjectManager ? "Project Manager" : _currentUser!.isHRManager ? "HR Manager" : "Nhân viên"}');
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
  }

  @override
  Future<void> refreshSystemContext() async {
    final buffer = StringBuffer();
    
    try {
      // Load projects
      if (_currentUser != null) {
        final projectDatasource = ProjectDataSourceImpl();
        final projects = await projectDatasource.getProjectsByUser(_currentUser!.id);
        
        if (projects.isNotEmpty) {
          buffer.writeln('\n=== DỰ ÁN ===');
          for (final p in projects.take(10)) {
            final project = p.toEntity();
            buffer.writeln('- ${project.name} (${project.status.displayName})');
            if (project.description != null && project.description!.isNotEmpty) {
              buffer.writeln('  Mô tả: ${project.description}');
            }
          }
        }
        
        // Load tasks for user
        final issueDatasource = IssueDataSourceImpl();
        final tasks = await issueDatasource.getIssuesByAssignee(_currentUser!.id);
        
        if (tasks.isNotEmpty) {
          buffer.writeln('\n=== CÔNG VIỆC ĐƯỢC GIAO ===');
          for (final t in tasks.take(15)) {
            final task = t.toEntity();
            buffer.writeln('- ${task.title} (${task.status.displayName}, ${task.priority.displayName})');
          }
        }
        
        // Load today's attendance
        final attendanceDatasource = AttendanceDataSourceImpl();
        final todayAttendance = await attendanceDatasource.getTodayAttendance(_currentUser!.id);
        
        if (todayAttendance != null) {
          buffer.writeln('\n=== CHẤM CÔNG HÔM NAY ===');
          buffer.writeln('Trạng thái: ${todayAttendance.status.name}');
          if (todayAttendance.checkInTime != null) {
            buffer.writeln('Check-in: ${todayAttendance.checkInTime}');
          }
          if (todayAttendance.checkOutTime != null) {
            buffer.writeln('Check-out: ${todayAttendance.checkOutTime}');
          }
        }
      }
    } catch (e) {
      buffer.writeln('\nLỗi khi tải dữ liệu: ${e.toString()}');
    }
    
    _systemDataContext = buffer.toString();
  }

  @override
  Future<String> sendMessage(String message, List<AIChatMessage> history) async {
    try {
      // Build messages for API
      final messages = <Map<String, String>>[];
      
      // Add system prompt
      messages.add({
        'role': 'system',
        'content': _buildFullSystemPrompt(),
      });
      
      // Add conversation history
      for (final msg in _conversationHistory) {
        messages.add(msg);
      }
      
      // Add current user message
      messages.add({
        'role': 'user',
        'content': message,
      });
      
      // Make API request
      final response = await _dio.post(
        _groqApiUrl,
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2048,
          'top_p': 0.95,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final responseText = data['choices']?[0]?['message']?['content'] as String?;
        
        if (responseText != null && responseText.isNotEmpty) {
          // Update conversation history
          _conversationHistory.add({'role': 'user', 'content': message});
          _conversationHistory.add({'role': 'assistant', 'content': responseText});
          
          // Limit history to last 20 messages to avoid token limits
          if (_conversationHistory.length > 20) {
            _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 20);
          }
          
          return responseText;
        }
      }
      
      return 'Xin lỗi, tôi không thể xử lý yêu cầu này. Vui lòng thử lại.';
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        return 'Hệ thống đang quá tải. Vui lòng đợi vài giây và thử lại.';
      } else if (e.response?.statusCode == 401) {
        return 'API key không hợp lệ. Vui lòng kiểm tra cấu hình.';
      }
      return 'Lỗi kết nối: ${e.message}';
    } catch (e) {
      return 'Lỗi: ${e.toString()}';
    }
  }

  @override
  void startNewConversation() {
    _conversationHistory.clear();
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
    _conversationHistory.clear();
  }
}
