import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class ChatLoadRooms extends ChatEvent {
  final String userId;
  const ChatLoadRooms(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ChatSubscribeRooms extends ChatEvent {
  final String userId;
  const ChatSubscribeRooms(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ChatCreatePrivateRoom extends ChatEvent {
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;
  const ChatCreatePrivateRoom(this.currentUserId, this.otherUserId, this.otherUserName);
  @override
  List<Object?> get props => [currentUserId, otherUserId, otherUserName];
}

class ChatCreateGroupRoom extends ChatEvent {
  final String name;
  final List<String> memberIds;
  final String createdBy;
  const ChatCreateGroupRoom(this.name, this.memberIds, this.createdBy);
  @override
  List<Object?> get props => [name, memberIds, createdBy];
}

class ChatSelectRoom extends ChatEvent {
  final String roomId;
  const ChatSelectRoom(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class ChatSubscribeMessages extends ChatEvent {
  final String roomId;
  const ChatSubscribeMessages(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

class ChatSendMessage extends ChatEvent {
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  const ChatSendMessage({
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = MessageType.text,
  });
  @override
  List<Object?> get props => [roomId, senderId, senderName, content, type];
}

class ChatSendFile extends ChatEvent {
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final File file;
  final String fileName;
  final MessageType type;
  const ChatSendFile({
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.file,
    required this.fileName,
    this.type = MessageType.file,
  });
  @override
  List<Object?> get props => [roomId, senderId, file, fileName, type];
}

class ChatMarkAsRead extends ChatEvent {
  final String roomId;
  final String userId;
  const ChatMarkAsRead(this.roomId, this.userId);
  @override
  List<Object?> get props => [roomId, userId];
}

class ChatRoomsUpdated extends ChatEvent {
  final List<dynamic> rooms;
  const ChatRoomsUpdated(this.rooms);
  @override
  List<Object?> get props => [rooms];
}

class ChatMessagesUpdated extends ChatEvent {
  final List<dynamic> messages;
  const ChatMessagesUpdated(this.messages);
  @override
  List<Object?> get props => [messages];
}
