/// AI Chat BLoC
/// 
/// Manages AI chatbot state and interactions with Gemini API.

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/datasources/ai_chat_datasource.dart';
import '../../../domain/entities/ai_chat_message.dart';
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
    ));

    try {
      // Get AI response
      final response = await _dataSource.sendMessage(
        event.message.trim(),
        state.messages,
      );

      // Add AI response to list
      final aiMessage = AIChatMessage(
        id: _uuid.v4(),
        content: response,
        role: AIChatRole.assistant,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedMessages, aiMessage];
      
      // Save history after each message
      await _dataSource.saveHistory(finalMessages);

      emit(state.copyWith(
        status: AIChatStatus.loaded,
        messages: finalMessages,
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

  Future<void> _onClearHistory(
    AIChatClearHistory event,
    Emitter<AIChatState> emit,
  ) async {
    _dataSource.startNewConversation();
    await _dataSource.clearHistory();
    emit(const AIChatState(status: AIChatStatus.initial));
  }
}
