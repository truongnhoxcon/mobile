/// AI Chat BLoC Events

import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

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

/// Set current user context for AI
class AIChatSetUserContext extends AIChatEvent {
  final User user;

  const AIChatSetUserContext(this.user);

  @override
  List<Object?> get props => [user];
}

/// Refresh system data context
class AIChatRefreshContext extends AIChatEvent {
  const AIChatRefreshContext();
}
