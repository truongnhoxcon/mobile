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
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;
  const ChatCreatePrivateRoom(this.currentUserId, this.currentUserName, this.otherUserId, this.otherUserName);
  @override
  List<Object?> get props => [currentUserId, currentUserName, otherUserId, otherUserName];
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
  // Reply support
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderName;
  // Mention support
  final List<String> mentions;
  
  const ChatSendMessage({
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = MessageType.text,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    this.mentions = const [],
  });
  @override
  List<Object?> get props => [roomId, senderId, senderName, content, type, replyToId, mentions];
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

// ============================================================================
// NEW EVENTS for Advanced Features
// ============================================================================

/// Toggle emoji reaction on a message
class ChatToggleReaction extends ChatEvent {
  final String messageId;
  final String roomId;
  final String emoji;
  final String userId;
  
  const ChatToggleReaction({
    required this.messageId,
    required this.roomId,
    required this.emoji,
    required this.userId,
  });
  
  @override
  List<Object?> get props => [messageId, roomId, emoji, userId];
}

/// Delete or recall a message
class ChatDeleteMessage extends ChatEvent {
  final String messageId;
  final String roomId;
  final bool forEveryone; // true = recall (show "thu hồi"), false = delete for self only
  
  const ChatDeleteMessage({
    required this.messageId,
    required this.roomId,
    this.forEveryone = false,
  });
  
  @override
  List<Object?> get props => [messageId, roomId, forEveryone];
}

/// Set typing status for current user
class ChatSetTyping extends ChatEvent {
  final String roomId;
  final String oderId;
  final String userName;
  final bool isTyping;
  
  const ChatSetTyping({
    required this.roomId,
    required this.oderId,
    required this.userName,
    required this.isTyping,
  });
  
  @override
  List<Object?> get props => [roomId, oderId, userName, isTyping];
}

/// Edit an existing message
class ChatEditMessage extends ChatEvent {
  final String messageId;
  final String roomId;
  final String newContent;
  
  const ChatEditMessage({
    required this.messageId,
    required this.roomId,
    required this.newContent,
  });
  
  @override
  List<Object?> get props => [messageId, roomId, newContent];
}
