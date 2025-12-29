import 'package:equatable/equatable.dart';

enum MessageType { text, image, file, system }

extension MessageTypeExtension on MessageType {
  String get value {
    switch (this) {
      case MessageType.text: return 'TEXT';
      case MessageType.image: return 'IMAGE';
      case MessageType.file: return 'FILE';
      case MessageType.system: return 'SYSTEM';
    }
  }

  static MessageType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'TEXT': return MessageType.text;
      case 'IMAGE': return MessageType.image;
      case 'FILE': return MessageType.file;
      case 'SYSTEM': return MessageType.system;
      default: return MessageType.text;
    }
  }
}

/// Message reaction (emoji reactions like 👍❤️😂)
class MessageReaction extends Equatable {
  final String emoji;
  final List<String> userIds;

  const MessageReaction({
    required this.emoji,
    this.userIds = const [],
  });

  int get count => userIds.length;

  MessageReaction addUser(String userId) {
    if (userIds.contains(userId)) return this;
    return MessageReaction(emoji: emoji, userIds: [...userIds, userId]);
  }

  MessageReaction removeUser(String userId) {
    return MessageReaction(
      emoji: emoji,
      userIds: userIds.where((id) => id != userId).toList(),
    );
  }

  @override
  List<Object?> get props => [emoji, userIds];
}

/// Mentioned user in message
class MentionedUser extends Equatable {
  final String userId;
  final String displayName;
  final int startIndex; // Position in text where mention starts
  final int endIndex;   // Position in text where mention ends

  const MentionedUser({
    required this.userId,
    required this.displayName,
    required this.startIndex,
    required this.endIndex,
  });

  @override
  List<Object?> get props => [userId, displayName, startIndex, endIndex];
}

class Message extends Equatable {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String content;
  final MessageType type;
  final String? fileUrl;
  final String? fileName;
  final DateTime createdAt;
  final List<String> readBy;
  
  // Reply feature
  final String? replyToId;          // ID of message being replied to
  final String? replyToContent;     // Preview of replied message content
  final String? replyToSenderName;  // Name of original sender
  
  // Reactions feature
  final List<MessageReaction> reactions;
  
  // Mentions feature
  final List<MentionedUser> mentions;
  
  // Delete/Recall feature
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isDeletedForEveryone; // true = recalled, false = deleted for sender only
  
  // Edit feature (bonus)
  final bool isEdited;
  final DateTime? editedAt;

  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.content,
    this.type = MessageType.text,
    this.fileUrl,
    this.fileName,
    required this.createdAt,
    this.readBy = const [],
    // Reply
    this.replyToId,
    this.replyToContent,
    this.replyToSenderName,
    // Reactions
    this.reactions = const [],
    // Mentions
    this.mentions = const [],
    // Delete
    this.isDeleted = false,
    this.deletedAt,
    this.isDeletedForEveryone = false,
    // Edit
    this.isEdited = false,
    this.editedAt,
  });

  Message copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? content,
    MessageType? type,
    String? fileUrl,
    String? fileName,
    DateTime? createdAt,
    List<String>? readBy,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderName,
    List<MessageReaction>? reactions,
    List<MentionedUser>? mentions,
    bool? isDeleted,
    DateTime? deletedAt,
    bool? isDeletedForEveryone,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return Message(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      reactions: reactions ?? this.reactions,
      mentions: mentions ?? this.mentions,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  // Helpers
  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;
  bool get isSystem => type == MessageType.system;
  bool get isReply => replyToId != null;
  bool get hasReactions => reactions.isNotEmpty;
  bool get hasMentions => mentions.isNotEmpty;
  
  /// Get total reaction count
  int get totalReactionCount => reactions.fold(0, (sum, r) => sum + r.count);
  
  /// Check if user has reacted with specific emoji
  bool hasUserReacted(String userId, String emoji) {
    final reaction = reactions.where((r) => r.emoji == emoji).firstOrNull;
    return reaction?.userIds.contains(userId) ?? false;
  }
  
  /// Add or toggle reaction for user
  Message toggleReaction(String userId, String emoji) {
    final existingIndex = reactions.indexWhere((r) => r.emoji == emoji);
    
    if (existingIndex == -1) {
      // Add new reaction
      return copyWith(reactions: [...reactions, MessageReaction(emoji: emoji, userIds: [userId])]);
    }
    
    final existing = reactions[existingIndex];
    if (existing.userIds.contains(userId)) {
      // Remove user from reaction
      final updated = existing.removeUser(userId);
      if (updated.count == 0) {
        // Remove reaction entirely
        return copyWith(reactions: reactions.where((r) => r.emoji != emoji).toList());
      }
      final newReactions = [...reactions];
      newReactions[existingIndex] = updated;
      return copyWith(reactions: newReactions);
    } else {
      // Add user to reaction
      final newReactions = [...reactions];
      newReactions[existingIndex] = existing.addUser(userId);
      return copyWith(reactions: newReactions);
    }
  }

  @override
  List<Object?> get props => [
    id, roomId, senderId, senderName, senderPhotoUrl, content, type, 
    fileUrl, fileName, createdAt, readBy,
    replyToId, replyToContent, replyToSenderName,
    reactions, mentions,
    isDeleted, deletedAt, isDeletedForEveryone,
    isEdited, editedAt,
  ];
}

/// Available reaction emojis
class ReactionEmojis {
  static const List<String> defaults = ['👍', '❤️', '😂', '😮', '😢', '🎉'];
}
