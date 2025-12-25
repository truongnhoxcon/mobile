/// AI Chat Session Entity
/// 
/// Represents a conversation session with the AI chatbot.

import 'package:equatable/equatable.dart';
import 'ai_chat_message.dart';

/// A chat session containing multiple messages
class AIChatSession extends Equatable {
  final String id;
  final String title;
  final String userId;
  final List<AIChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AIChatSession({
    required this.id,
    required this.title,
    required this.userId,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a new session with auto-generated title from first message
  factory AIChatSession.create({
    required String id,
    required String userId,
    String? title,
  }) {
    final now = DateTime.now();
    return AIChatSession(
      id: id,
      title: title ?? 'Cuộc trò chuyện mới',
      userId: userId,
      messages: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get preview text (first user message or default)
  String get preview {
    final userMessages = messages.where((m) => m.role == AIChatRole.user);
    if (userMessages.isEmpty) return 'Cuộc trò chuyện mới';
    final first = userMessages.first.content;
    return first.length > 50 ? '${first.substring(0, 50)}...' : first;
  }

  /// Get relative time string
  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';
  }

  AIChatSession copyWith({
    String? id,
    String? title,
    String? userId,
    List<AIChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      userId: userId ?? this.userId,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'userId': userId,
      'messages': messages.map((m) => {
        'id': m.id,
        'content': m.content,
        'role': m.role == AIChatRole.user ? 'user' : 'assistant',
        'timestamp': m.timestamp.toIso8601String(),
      }).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory AIChatSession.fromJson(Map<String, dynamic> json) {
    final messagesList = (json['messages'] as List<dynamic>?)?.map((m) {
      final map = m as Map<String, dynamic>;
      return AIChatMessage(
        id: map['id'] as String,
        content: map['content'] as String,
        role: map['role'] == 'user' ? AIChatRole.user : AIChatRole.assistant,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
    }).toList() ?? [];

    return AIChatSession(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Cuộc trò chuyện',
      userId: json['userId'] as String? ?? '',
      messages: messagesList,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, title, userId, messages, createdAt, updatedAt];
}
