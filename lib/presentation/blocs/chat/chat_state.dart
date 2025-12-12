import 'package:equatable/equatable.dart';
import '../../../domain/entities/chat_room.dart';
import '../../../domain/entities/message.dart';

enum ChatBlocStatus { initial, loading, loaded, sending, error }

class ChatState extends Equatable {
  final ChatBlocStatus status;
  final List<ChatRoom> rooms;
  final List<Message> messages;
  final String? selectedRoomId;
  final String? errorMessage;

  const ChatState({
    this.status = ChatBlocStatus.initial,
    this.rooms = const [],
    this.messages = const [],
    this.selectedRoomId,
    this.errorMessage,
  });

  ChatRoom? get selectedRoom => 
    selectedRoomId != null 
      ? rooms.firstWhere((r) => r.id == selectedRoomId, orElse: () => rooms.first) 
      : null;

  ChatState copyWith({
    ChatBlocStatus? status,
    List<ChatRoom>? rooms,
    List<Message>? messages,
    String? selectedRoomId,
    String? errorMessage,
    bool clearSelectedRoom = false,
  }) {
    return ChatState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      messages: messages ?? this.messages,
      selectedRoomId: clearSelectedRoom ? null : (selectedRoomId ?? this.selectedRoomId),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rooms, messages, selectedRoomId, errorMessage];
}
