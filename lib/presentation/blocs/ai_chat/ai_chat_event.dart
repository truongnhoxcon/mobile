/// AI Chat BLoC Events

import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/entities/ai_action.dart';

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

/// Execute an approved action
class AIChatExecuteAction extends AIChatEvent {
  final AIAction action;

  const AIChatExecuteAction(this.action);

  @override
  List<Object?> get props => [action];
}

/// Reject a pending action
class AIChatRejectAction extends AIChatEvent {
  final AIAction action;

  const AIChatRejectAction(this.action);

  @override
  List<Object?> get props => [action];
}

/// Clear pending actions
class AIChatClearActions extends AIChatEvent {
  const AIChatClearActions();
}

// ========== Session Events ==========

/// Load all sessions
class AIChatLoadSessions extends AIChatEvent {
  const AIChatLoadSessions();
}

/// Create a new session
class AIChatCreateSession extends AIChatEvent {
  const AIChatCreateSession();
}

/// Switch to a different session
class AIChatSwitchSession extends AIChatEvent {
  final String sessionId;

  const AIChatSwitchSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}

/// Delete a session
class AIChatDeleteSession extends AIChatEvent {
  final String sessionId;

  const AIChatDeleteSession(this.sessionId);

  @override
  List<Object?> get props => [sessionId];
}
