import 'package:equatable/equatable.dart';

enum ChatRoomType { private, group }

extension ChatRoomTypeExtension on ChatRoomType {
  String get value {
    switch (this) {
      case ChatRoomType.private: return 'PRIVATE';
      case ChatRoomType.group: return 'GROUP';
    }
  }

  static ChatRoomType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PRIVATE': return ChatRoomType.private;
      case 'GROUP': return ChatRoomType.group;
      default: return ChatRoomType.private;
    }
  }
}

class ChatRoom extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final ChatRoomType type;
  final List<String> memberIds;
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final String createdBy;
  final DateTime createdAt;

  const ChatRoom({
    required this.id,
    required this.name,
    this.imageUrl,
    this.type = ChatRoomType.private,
    required this.memberIds,
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    required this.createdBy,
    required this.createdAt,
  });

  ChatRoom copyWith({
    String? id,
    String? name,
    String? imageUrl,
    ChatRoomType? type,
    List<String>? memberIds,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      memberIds: memberIds ?? this.memberIds,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isGroup => type == ChatRoomType.group;

  @override
  List<Object?> get props => [id, name, imageUrl, type, memberIds, lastMessage, lastMessageSenderId, lastMessageTime, createdBy, createdAt];
}
