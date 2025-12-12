import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.senderName,
    super.senderPhotoUrl,
    required super.content,
    super.type,
    super.fileUrl,
    super.fileName,
    required super.createdAt,
    super.readBy,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderPhotoUrl: data['senderPhotoUrl'],
      content: data['content'] ?? '',
      type: MessageTypeExtension.fromString(data['type'] ?? 'TEXT'),
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      roomId: message.roomId,
      senderId: message.senderId,
      senderName: message.senderName,
      senderPhotoUrl: message.senderPhotoUrl,
      content: message.content,
      type: message.type,
      fileUrl: message.fileUrl,
      fileName: message.fileName,
      createdAt: message.createdAt,
      readBy: message.readBy,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'content': content,
      'type': type.value,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }

  Message toEntity() => Message(
    id: id, roomId: roomId, senderId: senderId, senderName: senderName,
    senderPhotoUrl: senderPhotoUrl, content: content, type: type,
    fileUrl: fileUrl, fileName: fileName, createdAt: createdAt, readBy: readBy,
  );
}
