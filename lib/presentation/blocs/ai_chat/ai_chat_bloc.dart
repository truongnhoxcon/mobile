/// AI Chat BLoC
/// 
/// Manages AI chatbot state and interactions with Groq API.
/// Supports action execution for task creation, assignment, etc.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/datasources/ai_chat_datasource.dart';
import '../../../domain/entities/ai_chat_message.dart';
import '../../../domain/entities/ai_chat_session.dart';
import '../../../domain/entities/ai_action.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  final AIChatDataSource _dataSource;
  final _uuid = const Uuid();

  AIChatBloc({required AIChatDataSource dataSource})
      : _dataSource = dataSource,
        super(const AIChatState()) {
    on<AIChatLoadHistory>(_onLoadHistory);
    on<AIChatSendMessage>(_onSendMessage);
    on<AIChatClearHistory>(_onClearHistory);
    on<AIChatSetUserContext>(_onSetUserContext);
    on<AIChatRefreshContext>(_onRefreshContext);
    on<AIChatExecuteAction>(_onExecuteAction);
    on<AIChatRejectAction>(_onRejectAction);
    on<AIChatClearActions>(_onClearActions);
    on<AIChatLoadSessions>(_onLoadSessions);
    on<AIChatCreateSession>(_onCreateSession);
    on<AIChatSwitchSession>(_onSwitchSession);
    on<AIChatDeleteSession>(_onDeleteSession);
  }

  Future<void> _onLoadHistory(
    AIChatLoadHistory event,
    Emitter<AIChatState> emit,
  ) async {
    emit(state.copyWith(status: AIChatStatus.loading));
    try {
      final messages = await _dataSource.loadHistory();
      emit(state.copyWith(
        status: AIChatStatus.loaded,
        messages: messages,
      ));
    } catch (e) {
      emit(state.copyWith(status: AIChatStatus.loaded, messages: []));
    }
  }

  Future<void> _onSendMessage(
    AIChatSendMessage event,
    Emitter<AIChatState> emit,
  ) async {
    if (event.message.trim().isEmpty) return;

    // Add user message to list
    final userMessage = AIChatMessage(
      id: _uuid.v4(),
      content: event.message.trim(),
      role: AIChatRole.user,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, userMessage];
    emit(state.copyWith(
      status: AIChatStatus.sending,
      messages: updatedMessages,
      pendingActions: [], // Clear previous pending actions
    ));

    try {
      // Get AI response with potential actions
      final response = await _dataSource.sendMessageWithActions(
        event.message.trim(),
        state.messages,
      );

      // Add AI response to list
      final aiMessage = AIChatMessage(
        id: _uuid.v4(),
        content: response.message,
        role: AIChatRole.assistant,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedMessages, aiMessage];
      
      // Save history after each message (legacy)
      await _dataSource.saveHistory(finalMessages);
      
      // Auto-save to session
      final sessionId = state.currentSessionId ?? _uuid.v4();
      final session = AIChatSession(
        id: sessionId,
        title: finalMessages.first.content.length > 30 
          ? '${finalMessages.first.content.substring(0, 30)}...'
          : finalMessages.first.content,
        userId: _currentUserId ?? '',
        messages: finalMessages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dataSource.saveSession(session);
      _dataSource.currentSessionId = sessionId;
      
      // Reload sessions list
      final sessions = await _dataSource.getAllSessions();

      emit(state.copyWith(
        status: AIChatStatus.loaded,
        messages: finalMessages,
        pendingActions: response.actions,
        currentSessionId: sessionId,
        sessions: sessions,
      ));
    } catch (e) {
      // Add error message as AI response
      final errorMessage = AIChatMessage(
        id: _uuid.v4(),
        content: 'Xin lỗi, đã xảy ra lỗi. Vui lòng thử lại.',
        role: AIChatRole.assistant,
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        status: AIChatStatus.error,
        messages: [...updatedMessages, errorMessage],
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onExecuteAction(
    AIChatExecuteAction event,
    Emitter<AIChatState> emit,
  ) async {
    emit(state.copyWith(status: AIChatStatus.executingAction));

    try {
      // Execute the action
      final result = await _dataSource.executeAction(event.action);

      // Update action status
      final updatedActions = state.pendingActions.map((a) {
        if (a.id == event.action.id) {
          return a.copyWith(
            status: AIActionStatus.completed,
            resultMessage: result,
          );
        }
        return a;
      }).toList();

      // Add result message to chat
      final resultMessage = AIChatMessage(
        id: _uuid.v4(),
        content: result,
        role: AIChatRole.assistant,
        timestamp: DateTime.now(),
      );

      final updatedMessages = [...state.messages, resultMessage];
      await _dataSource.saveHistory(updatedMessages);

      emit(state.copyWith(
        status: AIChatStatus.loaded,
        messages: updatedMessages,
        pendingActions: updatedActions.where((a) => a.status == AIActionStatus.pending).toList(),
      ));
    } catch (e) {
      // Update action as failed
      final updatedActions = state.pendingActions.map((a) {
        if (a.id == event.action.id) {
          return a.copyWith(
            status: AIActionStatus.failed,
            resultMessage: 'Lỗi: ${e.toString()}',
          );
        }
        return a;
      }).toList();

      emit(state.copyWith(
        status: AIChatStatus.error,
        pendingActions: updatedActions,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRejectAction(
    AIChatRejectAction event,
    Emitter<AIChatState> emit,
  ) async {
    // Remove rejected action from pending list
    final updatedActions = state.pendingActions
        .where((a) => a.id != event.action.id)
        .toList();

    // Add rejection message
    final rejectMessage = AIChatMessage(
      id: _uuid.v4(),
      content: '❌ Đã hủy: ${event.action.description}',
      role: AIChatRole.assistant,
      timestamp: DateTime.now(),
    );

    final updatedMessages = [...state.messages, rejectMessage];
    await _dataSource.saveHistory(updatedMessages);

    emit(state.copyWith(
      messages: updatedMessages,
      pendingActions: updatedActions,
    ));
  }

  Future<void> _onClearActions(
    AIChatClearActions event,
    Emitter<AIChatState> emit,
  ) async {
    emit(state.copyWith(pendingActions: []));
  }

  Future<void> _onClearHistory(
    AIChatClearHistory event,
    Emitter<AIChatState> emit,
  ) async {
    _dataSource.startNewConversation();
    await _dataSource.clearHistory();
    emit(const AIChatState(status: AIChatStatus.initial));
  }

  Future<void> _onRefreshContext(
    AIChatRefreshContext event,
    Emitter<AIChatState> emit,
  ) async {
    emit(state.copyWith(status: AIChatStatus.loading));
    try {
      await _dataSource.refreshSystemContext();
      emit(state.copyWith(status: AIChatStatus.loaded));
    } catch (e) {
      emit(state.copyWith(status: AIChatStatus.loaded));
    }
  }

  // ========== Session Handlers ==========

  String? _currentUserId;

  Future<void> _onLoadSessions(
    AIChatLoadSessions event,
    Emitter<AIChatState> emit,
  ) async {
    try {
      final sessions = await _dataSource.getAllSessions();
      emit(state.copyWith(sessions: sessions));
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _onCreateSession(
    AIChatCreateSession event,
    Emitter<AIChatState> emit,
  ) async {
    // Save current session if exists
    if (state.currentSessionId != null && state.messages.isNotEmpty) {
      final currentSession = AIChatSession(
        id: state.currentSessionId!,
        title: state.messages.first.content.length > 30 
          ? '${state.messages.first.content.substring(0, 30)}...'
          : state.messages.first.content,
        userId: _currentUserId ?? '',
        messages: state.messages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dataSource.saveSession(currentSession);
    }

    // Create new session
    final newSessionId = _uuid.v4();
    _dataSource.currentSessionId = newSessionId;
    _dataSource.startNewConversation();
    
    final sessions = await _dataSource.getAllSessions();
    emit(state.copyWith(
      messages: [],
      pendingActions: [],
      currentSessionId: newSessionId,
      sessions: sessions,
    ));
  }

  Future<void> _onSwitchSession(
    AIChatSwitchSession event,
    Emitter<AIChatState> emit,
  ) async {
    emit(state.copyWith(status: AIChatStatus.loading));
    
    try {
      // Save current session first
      if (state.currentSessionId != null && state.messages.isNotEmpty) {
        final currentSession = AIChatSession(
          id: state.currentSessionId!,
          title: state.messages.first.content.length > 30 
            ? '${state.messages.first.content.substring(0, 30)}...'
            : state.messages.first.content,
          userId: _currentUserId ?? '',
          messages: state.messages,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _dataSource.saveSession(currentSession);
      }

      // Load target session
      final session = await _dataSource.loadSession(event.sessionId);
      if (session != null) {
        _dataSource.currentSessionId = session.id;
        _dataSource.startNewConversation();
        
        emit(state.copyWith(
          status: AIChatStatus.loaded,
          messages: session.messages,
          currentSessionId: session.id,
          pendingActions: [],
        ));
      } else {
        emit(state.copyWith(status: AIChatStatus.loaded));
      }
    } catch (e) {
      emit(state.copyWith(status: AIChatStatus.loaded));
    }
  }

  Future<void> _onDeleteSession(
    AIChatDeleteSession event,
    Emitter<AIChatState> emit,
  ) async {
    await _dataSource.deleteSession(event.sessionId);
    final sessions = await _dataSource.getAllSessions();
    
    // If deleted current session, clear messages
    if (state.currentSessionId == event.sessionId) {
      emit(state.copyWith(
        messages: [],
        sessions: sessions,
        clearCurrentSessionId: true,
      ));
    } else {
      emit(state.copyWith(sessions: sessions));
    }
  }

  @override
  Future<void> _onSetUserContext(
    AIChatSetUserContext event,
    Emitter<AIChatState> emit,
  ) async {
    _currentUserId = event.user.id;
    _dataSource.setUserContext(event.user);
    await _dataSource.refreshSystemContext();
    add(const AIChatLoadSessions());
  }
}
