/// AI Chat Data Source
/// 
/// Google Gemini API integration for AI ChatBot with history persistence.

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ai_chat_message.dart';

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
}

class AIChatDataSourceImpl implements AIChatDataSource {
  final String _apiKey;
  final SharedPreferences _prefs;
  late final GenerativeModel _model;
  ChatSession? _chatSession;
  
  static const String _historyKey = 'ai_chat_history';

  // System prompt to set the AI's persona
  static const String _systemPrompt = '''
Bạn là trợ lý AI thông minh cho ứng dụng quản lý doanh nghiệp. 
Bạn có thể giúp đỡ về:
- Quản lý nhân sự: chấm công, nghỉ phép, thông tin nhân viên
- Quản lý dự án: tạo dự án, theo dõi tiến độ, quản lý task
- Các câu hỏi chung về công việc

Hãy trả lời ngắn gọn, thân thiện và hữu ích. Sử dụng tiếng Việt.
Nếu được hỏi về tính năng chưa có trong app, hãy giải thích rằng tính năng đó chưa được hỗ trợ.
''';

  AIChatDataSourceImpl({
    required String apiKey,
    required SharedPreferences prefs,
  }) : _apiKey = apiKey,
       _prefs = prefs {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.text(_systemPrompt),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    _initChatSession();
  }

  void _initChatSession() {
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
    _initChatSession();
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
