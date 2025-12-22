/// AI Chat BLoC Events

import 'package:equatable/equatable.dart';

abstract class AIChatEvent extends Equatable {
  const AIChatEvent();

  @override
  List<Object?> get props => [];
}

/// Load chat history from storage
class AIChatLoadHistory extends AIChatEvent {
  const AIChatLoadHistory();
}

/// Send a message to the AI
class AIChatSendMessage extends AIChatEvent {
  final String message;

  const AIChatSendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

/// Clear chat history and start new conversation
class AIChatClearHistory extends AIChatEvent {
  const AIChatClearHistory();
}
