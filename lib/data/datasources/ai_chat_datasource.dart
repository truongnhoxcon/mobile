/// AI Chat Data Source
/// 
/// Groq API integration for AI ChatBot with system data access and action execution.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ai_chat_message.dart';
import '../../domain/entities/ai_chat_session.dart';
import '../../domain/entities/ai_action.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/issue.dart';
import '../../domain/entities/project.dart';
import 'user_datasource.dart';
import 'project_datasource.dart';
import 'issue_datasource.dart';
import 'attendance_datasource.dart';

abstract class AIChatDataSource {
  /// Send a message to the AI and get a response with potential actions
  Future<AIResponseWithActions> sendMessageWithActions(String message, List<AIChatMessage> history);
  
  /// Execute an approved action
  Future<String> executeAction(AIAction action);
  
  /// Start a new conversation (clear context)
  void startNewConversation();
  
  /// Save chat history to local storage (deprecated - use session methods)
  Future<void> saveHistory(List<AIChatMessage> messages);
  
  /// Load chat history from local storage (deprecated - use session methods)
  Future<List<AIChatMessage>> loadHistory();
  
  /// Clear saved history
  Future<void> clearHistory();
  
  /// Set current user context
  void setUserContext(User user);
  
  /// Refresh system data context
  Future<void> refreshSystemContext();
  
  /// Get list of users for action execution
  Future<List<User>> getAvailableUsers();
  
  // ========== Session Management ==========
  
  /// Get all chat sessions for current user
  Future<List<AIChatSession>> getAllSessions();
  
  /// Save a chat session
  Future<void> saveSession(AIChatSession session);
  
  /// Load a specific session
  Future<AIChatSession?> loadSession(String sessionId);
  
  /// Delete a session
  Future<void> deleteSession(String sessionId);
  
  /// Get current session ID
  String? get currentSessionId;
  
  /// Set current session ID
  set currentSessionId(String? id);
}

class AIChatDataSourceImpl implements AIChatDataSource {
  final String _apiKey;
  final SharedPreferences _prefs;
  final Dio _dio;
  User? _currentUser;
  String _systemDataContext = '';
  List<Map<String, String>> _conversationHistory = [];
  List<User> _cachedUsers = [];
  
  static const String _historyKey = 'ai_chat_history';
  static const String _groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  // Enhanced system prompt with action capability
  static const String _baseSystemPrompt = '''
Bạn là trợ lý AI thông minh cho ứng dụng quản lý doanh nghiệp. 
Bạn có quyền truy cập vào dữ liệu thực của hệ thống và CÓ KHẢ NĂNG THỰC HIỆN HÀNH ĐỘNG.

## KHẢN NĂNG CỦA BẠN:
1. Trả lời câu hỏi về dữ liệu hệ thống
2. Tạo task/công việc mới
3. Giao việc cho nhân viên
4. Cập nhật trạng thái công việc
5. Tạo dự án mới

## CÁCH PHẢN HỒI:
- Với câu hỏi thông thường: Trả lời bằng text thuần
- Khi user YÊU CẦU THỰC HIỆN hành động (tạo, giao, cập nhật...): Trả lời theo format JSON sau:

```json
{
  "message": "Giải thích những gì bạn sẽ làm",
  "actions": [
    {
      "type": "create_task",
      "params": {
        "title": "Tên task",
        "description": "Mô tả",
        "projectId": "ID dự án nếu biết",
        "priority": "HIGH/MEDIUM/LOW",
        "assigneeId": "ID người được giao nếu có"
      }
    }
  ]
}
```

## CÁC LOẠI ACTION:
1. create_task: Tạo task mới
   - params: title, description, projectId, priority, assigneeId, dueDate
   
2. assign_task: Giao task cho user
   - params: taskId, assigneeId, assigneeName
   
3. update_task_status: Cập nhật trạng thái
   - params: taskId, status (TODO/IN_PROGRESS/IN_REVIEW/DONE)
   
4. create_project: Tạo dự án mới
   - params: name, description

## LƯU Ý QUAN TRỌNG:
- CHỈ trả về JSON khi user rõ ràng yêu cầu thực hiện hành động
- Với câu hỏi thông thường, KHÔNG trả về JSON
- Luôn sử dụng tiếng Việt
- Nếu thiếu thông tin cần thiết, hỏi lại user trước khi tạo action
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
      buffer.writeln('User ID: ${_currentUser!.id}');
      buffer.writeln('Tên: ${_currentUser!.displayName}');
      buffer.writeln('Email: ${_currentUser!.email}');
      buffer.writeln('Vai trò: ${_currentUser!.isProjectManager ? "Project Manager" : _currentUser!.isHRManager ? "HR Manager" : "Nhân viên"}');
    }
    
    if (_systemDataContext.isNotEmpty) {
      buffer.writeln('\n--- DỮ LIỆU HỆ THỐNG ---');
      buffer.writeln(_systemDataContext);
    }
    
    if (_cachedUsers.isNotEmpty) {
      buffer.writeln('\n--- DANH SÁCH NHÂN VIÊN ---');
      for (final user in _cachedUsers) {
        buffer.writeln('- ${user.displayName} (ID: ${user.id}, Email: ${user.email})');
      }
    }
    
    return buffer.toString();
  }

  @override
  void setUserContext(User user) {
    _currentUser = user;
  }

  @override
  Future<List<User>> getAvailableUsers() async {
    if (_cachedUsers.isEmpty) {
      try {
        final userDatasource = UserDataSourceImpl();
        final users = await userDatasource.getAllUsers();
        _cachedUsers = users.map((u) => u.toEntity()).toList();
      } catch (e) {
        // Ignore errors
      }
    }
    return _cachedUsers;
  }

  @override
  Future<void> refreshSystemContext() async {
    final buffer = StringBuffer();
    
    try {
      // Load users first
      await getAvailableUsers();
      
      // Load projects
      if (_currentUser != null) {
        final projectDatasource = ProjectDataSourceImpl();
        final projects = await projectDatasource.getProjectsByUser(_currentUser!.id);
        
        if (projects.isNotEmpty) {
          buffer.writeln('\n=== DỰ ÁN ===');
          for (final p in projects.take(10)) {
            final project = p.toEntity();
            buffer.writeln('- ${project.name} (ID: ${project.id}, Trạng thái: ${project.status.name})');
          }
        }
        
        // Load tasks for user
        final issueDatasource = IssueDataSourceImpl();
        final tasks = await issueDatasource.getIssuesByAssignee(_currentUser!.id);
        
        if (tasks.isNotEmpty) {
          buffer.writeln('\n=== CÔNG VIỆC ĐƯỢC GIAO ===');
          for (final t in tasks.take(15)) {
            final task = t.toEntity();
            buffer.writeln('- ${task.title} (ID: ${task.id}, Trạng thái: ${task.status.name}, Ưu tiên: ${task.priority.name})');
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

  /// Parse AI response to extract message and actions
  AIResponseWithActions _parseResponse(String rawResponse) {
    // Try to parse as JSON first
    try {
      // Check if response contains JSON
      final jsonMatch = RegExp(r'\{[\s\S]*"actions"[\s\S]*\}').firstMatch(rawResponse);
      
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        
        final message = json['message'] as String? ?? rawResponse;
        final actionsJson = json['actions'] as List<dynamic>? ?? [];
        
        final actions = <AIAction>[];
        for (int i = 0; i < actionsJson.length; i++) {
          try {
            final actionJson = actionsJson[i] as Map<String, dynamic>;
            final action = AIAction.fromJson(actionJson, 'action_${DateTime.now().millisecondsSinceEpoch}_$i');
            actions.add(action);
          } catch (e) {
            // Skip invalid actions
          }
        }
        
        return AIResponseWithActions(message: message, actions: actions);
      }
    } catch (e) {
      // Not JSON, return as regular message
    }
    
    return AIResponseWithActions(message: rawResponse);
  }

  @override
  Future<AIResponseWithActions> sendMessageWithActions(String message, List<AIChatMessage> history) async {
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
          
          // Limit history
          if (_conversationHistory.length > 20) {
            _conversationHistory = _conversationHistory.sublist(_conversationHistory.length - 20);
          }
          
          return _parseResponse(responseText);
        }
      }
      
      return const AIResponseWithActions(message: 'Xin lỗi, tôi không thể xử lý yêu cầu này.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        return const AIResponseWithActions(message: 'Hệ thống đang quá tải. Vui lòng đợi vài giây.');
      } else if (e.response?.statusCode == 401) {
        return const AIResponseWithActions(message: 'API key không hợp lệ.');
      }
      return AIResponseWithActions(message: 'Lỗi kết nối: ${e.message}');
    } catch (e) {
      return AIResponseWithActions(message: 'Lỗi: ${e.toString()}');
    }
  }

  @override
  Future<String> executeAction(AIAction action) async {
    try {
      switch (action.type) {
        case AIActionType.createTask:
          return await _executeCreateTask(action.params);
        case AIActionType.assignTask:
          return await _executeAssignTask(action.params);
        case AIActionType.updateTaskStatus:
          return await _executeUpdateTaskStatus(action.params);
        case AIActionType.createProject:
          return await _executeCreateProject(action.params);
      }
    } catch (e) {
      return 'Lỗi khi thực hiện: ${e.toString()}';
    }
  }

  Future<String> _executeCreateTask(Map<String, dynamic> params) async {
    final title = params['title'] as String? ?? 'Task mới';
    final description = params['description'] as String? ?? '';
    final projectId = params['projectId'] as String?;
    final priorityStr = params['priority'] as String? ?? 'MEDIUM';
    final assigneeId = params['assigneeId'] as String?;
    
    final priority = IssuePriorityExtension.fromString(priorityStr);
    
    final issueDatasource = IssueDataSourceImpl();
    
    final issue = Issue(
      id: '',
      title: title,
      description: description,
      projectId: projectId ?? '',
      type: IssueType.task,
      status: IssueStatus.todo,
      priority: priority,
      reporterId: _currentUser?.id ?? '',
      assigneeId: assigneeId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await issueDatasource.createIssue(issue);
    return '✅ Đã tạo task "$title" thành công!';
  }

  Future<String> _executeAssignTask(Map<String, dynamic> params) async {
    final taskId = params['taskId'] as String?;
    final assigneeId = params['assigneeId'] as String?;
    final assigneeName = params['assigneeName'] as String? ?? 'nhân viên';
    
    if (taskId == null || assigneeId == null) {
      return '❌ Thiếu thông tin taskId hoặc assigneeId';
    }
    
    final issueDatasource = IssueDataSourceImpl();
    // Fetch existing issue first
    final existingIssue = await issueDatasource.getIssue(taskId);
    if (existingIssue == null) {
      return '❌ Không tìm thấy task với ID: $taskId';
    }
    
    // Update with new assignee
    final updatedIssue = existingIssue.toEntity().copyWith(assigneeId: assigneeId);
    await issueDatasource.updateIssue(updatedIssue);
    
    return '✅ Đã giao task cho $assigneeName!';
  }

  Future<String> _executeUpdateTaskStatus(Map<String, dynamic> params) async {
    final taskId = params['taskId'] as String?;
    final statusStr = params['status'] as String?;
    
    if (taskId == null || statusStr == null) {
      return '❌ Thiếu thông tin taskId hoặc status';
    }
    
    final status = IssueStatusExtension.fromString(statusStr);
    
    final issueDatasource = IssueDataSourceImpl();
    // Fetch existing issue first
    final existingIssue = await issueDatasource.getIssue(taskId);
    if (existingIssue == null) {
      return '❌ Không tìm thấy task với ID: $taskId';
    }
    
    // Update with new status
    final updatedIssue = existingIssue.toEntity().copyWith(status: status);
    await issueDatasource.updateIssue(updatedIssue);
    
    return '✅ Đã cập nhật trạng thái task thành ${status.displayName}!';
  }

  Future<String> _executeCreateProject(Map<String, dynamic> params) async {
    final name = params['name'] as String? ?? 'Dự án mới';
    final description = params['description'] as String? ?? '';
    final userId = _currentUser?.id ?? '';
    
    final project = Project(
      id: '',
      name: name,
      description: description,
      ownerId: userId,
      status: ProjectStatus.planning,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      memberIds: userId.isNotEmpty ? [userId] : [], // Add creator as member
    );
    
    final projectDatasource = ProjectDataSourceImpl();
    await projectDatasource.createProject(project);
    
    return '✅ Đã tạo dự án "$name" thành công!';
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

  // ========== Session Management Implementation ==========
  
  static const String _sessionsKey = 'ai_chat_sessions';
  String? _currentSessionId;
  
  @override
  String? get currentSessionId => _currentSessionId;
  
  @override
  set currentSessionId(String? id) => _currentSessionId = id;
  
  @override
  Future<List<AIChatSession>> getAllSessions() async {
    final jsonString = _prefs.getString(_sessionsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final sessions = jsonList
          .map((json) => AIChatSession.fromJson(json as Map<String, dynamic>))
          .toList();
      // Sort by updatedAt descending
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<void> saveSession(AIChatSession session) async {
    final sessions = await getAllSessions();
    
    // Find and update or add new
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.insert(0, session);
    }
    
    // Keep only last 50 sessions
    final trimmed = sessions.take(50).toList();
    
    final jsonList = trimmed.map((s) => s.toJson()).toList();
    await _prefs.setString(_sessionsKey, jsonEncode(jsonList));
  }
  
  @override
  Future<AIChatSession?> loadSession(String sessionId) async {
    final sessions = await getAllSessions();
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> deleteSession(String sessionId) async {
    final sessions = await getAllSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await _prefs.setString(_sessionsKey, jsonEncode(jsonList));
  }
}
