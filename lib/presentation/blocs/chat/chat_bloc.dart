import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/chat_datasource.dart';
import '../../../domain/entities/chat_room.dart';
import '../../../domain/entities/message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatDataSource _dataSource;
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _messagesSubscription;

  ChatBloc({required ChatDataSource dataSource})
      : _dataSource = dataSource,
        super(const ChatState()) {
    on<ChatLoadRooms>(_onLoadRooms);
    on<ChatSubscribeRooms>(_onSubscribeRooms);
    on<ChatCreatePrivateRoom>(_onCreatePrivateRoom);
    on<ChatCreateGroupRoom>(_onCreateGroupRoom);
    on<ChatSelectRoom>(_onSelectRoom);
    on<ChatSubscribeMessages>(_onSubscribeMessages);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatSendFile>(_onSendFile);
    on<ChatMarkAsRead>(_onMarkAsRead);
    on<ChatRoomsUpdated>(_onRoomsUpdated);
    on<ChatMessagesUpdated>(_onMessagesUpdated);
  }

  @override
  Future<void> close() {
    _roomsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadRooms(ChatLoadRooms event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatBlocStatus.loading));
    try {
      final rooms = await _dataSource.getChatRooms(event.userId);
      emit(state.copyWith(
        status: ChatBlocStatus.loaded,
        rooms: rooms.map((m) => m.toEntity()).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(status: ChatBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSubscribeRooms(ChatSubscribeRooms event, Emitter<ChatState> emit) async {
    await _roomsSubscription?.cancel();
    _roomsSubscription = _dataSource.chatRoomsStream(event.userId).listen(
      (rooms) => add(ChatRoomsUpdated(rooms)),
    );
  }

  void _onRoomsUpdated(ChatRoomsUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      status: ChatBlocStatus.loaded,
      rooms: event.rooms.map((m) => (m as dynamic).toEntity() as ChatRoom).toList(),
    ));
  }

  Future<void> _onCreatePrivateRoom(ChatCreatePrivateRoom event, Emitter<ChatState> emit) async {
    try {
      // Check if room exists
      var room = await _dataSource.getPrivateRoom(event.currentUserId, event.otherUserId);
      
      if (room == null) {
        final newRoom = ChatRoom(
          id: '',
          name: '${event.currentUserName} & ${event.otherUserName}',
          type: ChatRoomType.private,
          memberIds: [event.currentUserId, event.otherUserId],
          memberNames: {
            event.currentUserId: event.currentUserName,
            event.otherUserId: event.otherUserName,
          },
          createdBy: event.currentUserId,
          createdAt: DateTime.now(),
        );
        room = await _dataSource.createChatRoom(newRoom);
      }
      
      emit(state.copyWith(selectedRoomId: room.id));
    } catch (e) {
      emit(state.copyWith(status: ChatBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCreateGroupRoom(ChatCreateGroupRoom event, Emitter<ChatState> emit) async {
    try {
      final newRoom = ChatRoom(
        id: '',
        name: event.name,
        type: ChatRoomType.group,
        memberIds: event.memberIds,
        createdBy: event.createdBy,
        createdAt: DateTime.now(),
      );
      final room = await _dataSource.createChatRoom(newRoom);
      emit(state.copyWith(selectedRoomId: room.id));
    } catch (e) {
      emit(state.copyWith(status: ChatBlocStatus.error, errorMessage: e.toString()));
    }
  }

  void _onSelectRoom(ChatSelectRoom event, Emitter<ChatState> emit) {
    emit(state.copyWith(selectedRoomId: event.roomId, messages: []));
  }

  Future<void> _onSubscribeMessages(ChatSubscribeMessages event, Emitter<ChatState> emit) async {
    await _messagesSubscription?.cancel();
    _messagesSubscription = _dataSource.messagesStream(event.roomId).listen(
      (messages) => add(ChatMessagesUpdated(messages)),
    );
  }

  void _onMessagesUpdated(ChatMessagesUpdated event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      messages: event.messages.map((m) => (m as dynamic).toEntity() as Message).toList(),
    ));
  }

  Future<void> _onSendMessage(ChatSendMessage event, Emitter<ChatState> emit) async {
    try {
      final message = Message(
        id: '',
        roomId: event.roomId,
        senderId: event.senderId,
        senderName: event.senderName,
        senderPhotoUrl: event.senderPhotoUrl,
        content: event.content,
        type: event.type,
        createdAt: DateTime.now(),
      );
      await _dataSource.sendMessage(message);
    } catch (e) {
      emit(state.copyWith(status: ChatBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onSendFile(ChatSendFile event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatBlocStatus.sending));
    try {
      final fileUrl = await _dataSource.uploadFile(event.roomId, event.file, event.fileName);
      
      final message = Message(
        id: '',
        roomId: event.roomId,
        senderId: event.senderId,
        senderName: event.senderName,
        senderPhotoUrl: event.senderPhotoUrl,
        content: event.fileName,
        type: event.type,
        fileUrl: fileUrl,
        fileName: event.fileName,
        createdAt: DateTime.now(),
      );
      await _dataSource.sendMessage(message);
      emit(state.copyWith(status: ChatBlocStatus.loaded));
    } catch (e) {
      emit(state.copyWith(status: ChatBlocStatus.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(ChatMarkAsRead event, Emitter<ChatState> emit) async {
    try {
      await _dataSource.markAsRead(event.roomId, event.userId);
    } catch (_) {}
  }
}
