import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/chat_room.dart';
import '../../domain/entities/message.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

abstract class ChatDataSource {
  Future<List<ChatRoomModel>> getChatRooms(String userId);
  Future<ChatRoomModel> createChatRoom(ChatRoom room);
  Future<ChatRoomModel?> getPrivateRoom(String userId1, String userId2);
  Future<void> deleteChatRoom(String roomId);
  Stream<List<ChatRoomModel>> chatRoomsStream(String userId);
  
  Future<List<MessageModel>> getMessages(String roomId, {int limit = 50});
  Future<MessageModel> sendMessage(Message message);
  Future<String> uploadFile(String roomId, File file, String fileName);
  Future<void> markAsRead(String roomId, String userId);
  Stream<List<MessageModel>> messagesStream(String roomId);
}

class ChatDataSourceImpl implements ChatDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ChatDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('chatRooms');

  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _firestore.collection('messages');

  @override
  Future<List<ChatRoomModel>> getChatRooms(String userId) async {
    // Query by memberIds only, then sort in memory to avoid composite index
    final snapshot = await _roomsRef
        .where('memberIds', arrayContains: userId)
        .get();
    
    final rooms = snapshot.docs.map((doc) => ChatRoomModel.fromFirestore(doc)).toList();
    // Sort by lastMessageTime in memory
    rooms.sort((a, b) {
      final aTime = a.lastMessageTime ?? DateTime(2000);
      final bTime = b.lastMessageTime ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return rooms;
  }

  @override
  Future<ChatRoomModel> createChatRoom(ChatRoom room) async {
    final model = ChatRoomModel.fromEntity(room);
    final docRef = await _roomsRef.add(model.toFirestore());
    final newDoc = await docRef.get();
    return ChatRoomModel.fromFirestore(newDoc);
  }

  @override
  Future<ChatRoomModel?> getPrivateRoom(String userId1, String userId2) async {
    // Find existing private room between two users
    final snapshot = await _roomsRef
        .where('type', isEqualTo: 'PRIVATE')
        .where('memberIds', arrayContains: userId1)
        .get();

    for (final doc in snapshot.docs) {
      final room = ChatRoomModel.fromFirestore(doc);
      if (room.memberIds.contains(userId2) && room.memberIds.length == 2) {
        return room;
      }
    }
    return null;
  }

  @override
  Future<void> deleteChatRoom(String roomId) async {
    // Delete all messages in room
    final messages = await _messagesRef.where('roomId', isEqualTo: roomId).get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }
    await _roomsRef.doc(roomId).delete();
  }

  @override
  Stream<List<ChatRoomModel>> chatRoomsStream(String userId) {
    // Query by memberIds only, sort in memory to avoid composite index
    return _roomsRef
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final rooms = snapshot.docs.map((doc) => ChatRoomModel.fromFirestore(doc)).toList();
          rooms.sort((a, b) {
            final aTime = a.lastMessageTime ?? DateTime(2000);
            final bTime = b.lastMessageTime ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return rooms;
        });
  }

  @override
  Future<List<MessageModel>> getMessages(String roomId, {int limit = 50}) async {
    // Query by roomId only, sort in memory to avoid composite index
    final snapshot = await _messagesRef
        .where('roomId', isEqualTo: roomId)
        .get();
    
    final messages = snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
    // Sort by createdAt descending in memory
    messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // Return only the last 'limit' messages
    return messages.take(limit).toList();
  }

  @override
  Future<MessageModel> sendMessage(Message message) async {
    final model = MessageModel.fromEntity(message);
    final docRef = await _messagesRef.add(model.toFirestore());
    
    // Update last message in room
    await _roomsRef.doc(message.roomId).update({
      'lastMessage': message.content,
      'lastMessageSenderId': message.senderId,
      'lastMessageTime': Timestamp.fromDate(message.createdAt),
    });

    final newDoc = await docRef.get();
    return MessageModel.fromFirestore(newDoc);
  }

  @override
  Future<String> uploadFile(String roomId, File file, String fileName) async {
    final ref = _storage.ref().child('chat/$roomId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  @override
  Future<void> markAsRead(String roomId, String userId) async {
    final unread = await _messagesRef
        .where('roomId', isEqualTo: roomId)
        .get();

    for (final doc in unread.docs) {
      final data = doc.data();
      if (data['senderId'] != userId) {
        final readBy = List<String>.from(data['readBy'] ?? []);
        if (!readBy.contains(userId)) {
          await doc.reference.update({
            'readBy': FieldValue.arrayUnion([userId]),
          });
        }
      }
    }
  }

  @override
  Stream<List<MessageModel>> messagesStream(String roomId) {
    // Query by roomId only, sort in memory to avoid composite index
    return _messagesRef
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs.map((doc) => MessageModel.fromFirestore(doc)).toList();
          messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return messages.take(100).toList();
        });
  }
}
