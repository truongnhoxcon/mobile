import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_room.dart';

class ChatRoomModel extends ChatRoom {
  const ChatRoomModel({
    required super.id,
    required super.name,
    super.imageUrl,
    super.type,
    required super.memberIds,
    super.memberNames,
    super.lastMessage,
    super.lastMessageSenderId,
    super.lastMessageTime,
    required super.createdBy,
    required super.createdAt,
    super.projectId,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'],
      type: ChatRoomTypeExtension.fromString(data['type'] ?? 'PRIVATE'),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberNames: Map<String, String>.from(data['memberNames'] ?? {}),
      lastMessage: data['lastMessage'],
      lastMessageSenderId: data['lastMessageSenderId'],
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      projectId: data['projectId'],
    );
  }

  factory ChatRoomModel.fromEntity(ChatRoom room) {
    return ChatRoomModel(
      id: room.id,
      name: room.name,
      imageUrl: room.imageUrl,
      type: room.type,
      memberIds: room.memberIds,
      memberNames: room.memberNames,
      lastMessage: room.lastMessage,
      lastMessageSenderId: room.lastMessageSenderId,
      lastMessageTime: room.lastMessageTime,
      createdBy: room.createdBy,
      createdAt: room.createdAt,
      projectId: room.projectId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'type': type.value,
      'memberIds': memberIds,
      'memberNames': memberNames,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : null,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'projectId': projectId,
    };
  }

  ChatRoom toEntity() => ChatRoom(
    id: id, name: name, imageUrl: imageUrl, type: type, memberIds: memberIds,
    memberNames: memberNames,
    lastMessage: lastMessage, lastMessageSenderId: lastMessageSenderId,
    lastMessageTime: lastMessageTime, createdBy: createdBy, createdAt: createdAt,
    projectId: projectId,
  );
}


