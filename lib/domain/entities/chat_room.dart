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

/// Typing user status
class TypingUser extends Equatable {
  final String oderId;
  final String userName;
  final DateTime startedAt;

  const TypingUser({
    required this.oderId,
    required this.userName,
    required this.startedAt,
  });
  
  /// Typing status expires after 5 seconds
  bool get isExpired => DateTime.now().difference(startedAt).inSeconds > 5;

  @override
  List<Object?> get props => [oderId, userName, startedAt];
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
  
  // Typing indicator - userId -> TypingUser
  final Map<String, TypingUser> typingUsers;
  
  // Unread count per user - userId -> count
  final Map<String, int> unreadCounts;
  
  // Pinned message  
  final String? pinnedMessageId;
  
  // Muted users - users who muted this room
  final List<String> mutedBy;

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
    this.typingUsers = const {},
    this.unreadCounts = const {},
    this.pinnedMessageId,
    this.mutedBy = const [],
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
    Map<String, TypingUser>? typingUsers,
    Map<String, int>? unreadCounts,
    String? pinnedMessageId,
    List<String>? mutedBy,
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
      typingUsers: typingUsers ?? this.typingUsers,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      pinnedMessageId: pinnedMessageId ?? this.pinnedMessageId,
      mutedBy: mutedBy ?? this.mutedBy,
    );
  }

  bool get isGroup => type == ChatRoomType.group;
  bool get isProject => type == ChatRoomType.project;
  bool get isPrivate => type == ChatRoomType.private;
  bool get hasPinnedMessage => pinnedMessageId != null;

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
  
  /// Get list of currently typing users (excluding current user)
  List<TypingUser> getTypingUsers(String currentUserId) {
    return typingUsers.entries
        .where((e) => e.key != currentUserId && !e.value.isExpired)
        .map((e) => e.value)
        .toList();
  }
  
  /// Get typing indicator text
  String getTypingText(String currentUserId) {
    final typing = getTypingUsers(currentUserId);
    if (typing.isEmpty) return '';
    if (typing.length == 1) {
      return '${typing.first.userName} đang gõ...';
    } else if (typing.length == 2) {
      return '${typing[0].userName} và ${typing[1].userName} đang gõ...';
    } else {
      return '${typing.length} người đang gõ...';
    }
  }
  
  /// Check if user muted this room
  bool isMutedBy(String userId) => mutedBy.contains(userId);
  
  /// Get unread count for user
  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  @override
  List<Object?> get props => [
    id, name, imageUrl, type, memberIds, memberNames, 
    lastMessage, lastMessageSenderId, lastMessageTime, 
    createdBy, createdAt, projectId,
    typingUsers, unreadCounts, pinnedMessageId, mutedBy,
  ];
}
