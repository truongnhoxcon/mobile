import 'package:equatable/equatable.dart';

enum ChatRoomType { private, group, project }

extension ChatRoomTypeExtension on ChatRoomType {
  String get value {
    switch (this) {
      case ChatRoomType.private: return 'PRIVATE';
      case ChatRoomType.group: return 'GROUP';
      case ChatRoomType.project: return 'PROJECT';
    }
  }

  static ChatRoomType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PRIVATE': return ChatRoomType.private;
      case 'GROUP': return ChatRoomType.group;
      case 'PROJECT': return ChatRoomType.project;
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
  final Map<String, String> memberNames; // userId -> displayName
  final String? lastMessage;
  final String? lastMessageSenderId;
  final DateTime? lastMessageTime;
  final String createdBy;
  final DateTime createdAt;
  final String? projectId;

  const ChatRoom({
    required this.id,
    required this.name,
    this.imageUrl,
    this.type = ChatRoomType.private,
    required this.memberIds,
    this.memberNames = const {},
    this.lastMessage,
    this.lastMessageSenderId,
    this.lastMessageTime,
    required this.createdBy,
    required this.createdAt,
    this.projectId,
  });

  ChatRoom copyWith({
    String? id,
    String? name,
    String? imageUrl,
    ChatRoomType? type,
    List<String>? memberIds,
    Map<String, String>? memberNames,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    String? createdBy,
    DateTime? createdAt,
    String? projectId,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      memberIds: memberIds ?? this.memberIds,
      memberNames: memberNames ?? this.memberNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      projectId: projectId ?? this.projectId,
    );
  }

  bool get isGroup => type == ChatRoomType.group;
  bool get isProject => type == ChatRoomType.project;
  bool get isPrivate => type == ChatRoomType.private;

  /// Get display name for private chat (name of the other person)
  String getDisplayName(String currentUserId) {
    if (!isPrivate) return name;
    // For private chat, return the other person's name
    for (final entry in memberNames.entries) {
      if (entry.key != currentUserId) {
        return entry.value;
      }
    }
    return name; // Fallback to room name
  }

  @override
  List<Object?> get props => [id, name, imageUrl, type, memberIds, memberNames, lastMessage, lastMessageSenderId, lastMessageTime, createdBy, createdAt, projectId];
}


