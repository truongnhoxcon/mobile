/// AI Chat BLoC State

import 'package:equatable/equatable.dart';
import '../../../domain/entities/ai_chat_message.dart';

enum AIChatStatus { initial, loading, loaded, sending, error }

class AIChatState extends Equatable {
  final AIChatStatus status;
  final List<AIChatMessage> messages;
  final String? errorMessage;

  const AIChatState({
    this.status = AIChatStatus.initial,
    this.messages = const [],
    this.errorMessage,
  });

  bool get isLoading => status == AIChatStatus.loading;
  bool get isSending => status == AIChatStatus.sending;
  bool get hasError => status == AIChatStatus.error;

  AIChatState copyWith({
    AIChatStatus? status,
    List<AIChatMessage>? messages,
    String? errorMessage,
  }) {
    return AIChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, messages, errorMessage];
}
