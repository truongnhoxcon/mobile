/// AI Chat Message Entity
/// 
/// Domain entity representing AI chat messages.

import 'package:equatable/equatable.dart';

enum AIChatRole { user, assistant }

class AIChatMessage extends Equatable {
  final String id;
  final String content;
  final AIChatRole role;
  final DateTime timestamp;

  const AIChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  bool get isUser => role == AIChatRole.user;
  bool get isAssistant => role == AIChatRole.assistant;

  @override
  List<Object?> get props => [id, content, role, timestamp];
}
