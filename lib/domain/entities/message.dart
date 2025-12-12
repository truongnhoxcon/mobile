import 'package:equatable/equatable.dart';

enum MessageType { text, image, file }

extension MessageTypeExtension on MessageType {
  String get value {
    switch (this) {
      case MessageType.text: return 'TEXT';
      case MessageType.image: return 'IMAGE';
      case MessageType.file: return 'FILE';
    }
  }

  static MessageType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'TEXT': return MessageType.text;
      case 'IMAGE': return MessageType.image;
      case 'FILE': return MessageType.file;
      default: return MessageType.text;
    }
  }
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
    );
  }

  bool get isImage => type == MessageType.image;
  bool get isFile => type == MessageType.file;

  @override
  List<Object?> get props => [id, roomId, senderId, senderName, senderPhotoUrl, content, type, fileUrl, fileName, createdAt, readBy];
}
