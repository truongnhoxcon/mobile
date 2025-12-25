/// AI Chat BLoC State

import 'package:equatable/equatable.dart';
import '../../../domain/entities/ai_chat_message.dart';
import '../../../domain/entities/ai_chat_session.dart';
import '../../../domain/entities/ai_action.dart';

enum AIChatStatus { initial, loading, loaded, sending, executingAction, error }

class AIChatState extends Equatable {
  final AIChatStatus status;
  final List<AIChatMessage> messages;
  final List<AIAction> pendingActions;
  final String? errorMessage;
  final List<AIChatSession> sessions;
  final String? currentSessionId;

  const AIChatState({
    this.status = AIChatStatus.initial,
    this.messages = const [],
    this.pendingActions = const [],
    this.errorMessage,
    this.sessions = const [],
    this.currentSessionId,
  });

  bool get isLoading => status == AIChatStatus.loading;
  bool get isSending => status == AIChatStatus.sending;
  bool get isExecutingAction => status == AIChatStatus.executingAction;
  bool get hasError => status == AIChatStatus.error;
  bool get hasPendingActions => pendingActions.isNotEmpty;

  AIChatState copyWith({
    AIChatStatus? status,
    List<AIChatMessage>? messages,
    List<AIAction>? pendingActions,
    String? errorMessage,
    List<AIChatSession>? sessions,
    String? currentSessionId,
    bool clearCurrentSessionId = false,
  }) {
    return AIChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      pendingActions: pendingActions ?? this.pendingActions,
      errorMessage: errorMessage ?? this.errorMessage,
      sessions: sessions ?? this.sessions,
      currentSessionId: clearCurrentSessionId ? null : (currentSessionId ?? this.currentSessionId),
    );
  }

  @override
  List<Object?> get props => [status, messages, pendingActions, errorMessage, sessions, currentSessionId];
}
