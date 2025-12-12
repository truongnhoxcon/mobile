import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/chat_room.dart';
import '../../../domain/entities/message.dart';
import '../../blocs/blocs.dart';

class ChatRoomScreen extends StatelessWidget {
  final String roomId;
  final ChatRoom? room;

  const ChatRoomScreen({super.key, required this.roomId, this.room});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ChatBloc>()..add(ChatSubscribeMessages(roomId)),
      child: _ChatRoomContent(roomId: roomId, room: room),
    );
  }
}

class _ChatRoomContent extends StatefulWidget {
  final String roomId;
  final ChatRoom? room;

  const _ChatRoomContent({required this.roomId, this.room});

  @override
  State<_ChatRoomContent> createState() => _ChatRoomContentState();
}

class _ChatRoomContentState extends State<_ChatRoomContent> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: widget.room?.isGroup == true 
                ? AppColors.info.withValues(alpha: 0.1) 
                : AppColors.primary.withValues(alpha: 0.1),
              child: Icon(
                widget.room?.isGroup == true ? Icons.group : Icons.person,
                size: 20.w,
                color: widget.room?.isGroup == true ? AppColors.info : AppColors.primary,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                widget.room?.name ?? 'Chat',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.info_outline), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 60.w, color: AppColors.textSecondary),
                        SizedBox(height: 12.h),
                        Text('Bắt đầu cuộc trò chuyện!', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(12.w),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMe = message.senderId == currentUser?.id;
                    final showAvatar = !isMe && (index == state.messages.length - 1 ||
                        state.messages[index + 1].senderId != message.senderId);

                    return _buildMessageBubble(message, isMe, showAvatar);
                  },
                );
              },
            ),
          ),
          _buildInputBar(currentUser?.id ?? '', currentUser?.displayName ?? 'User', currentUser?.photoUrl),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showAvatar) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(
              radius: 16.r,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: message.senderPhotoUrl != null ? NetworkImage(message.senderPhotoUrl!) : null,
              child: message.senderPhotoUrl == null
                  ? Text(message.senderName[0].toUpperCase(), style: TextStyle(fontSize: 12.sp, color: AppColors.primary))
                  : null,
            )
          else if (!isMe)
            SizedBox(width: 32.w),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && showAvatar)
                  Padding(
                    padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                    child: Text(message.senderName, style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary)),
                  ),
                Container(
                  constraints: BoxConstraints(maxWidth: 280.w),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.r),
                      topRight: Radius.circular(16.r),
                      bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                      bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildMessageContent(message, isMe),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 4.h, left: 4.w, right: 4.w),
                  child: Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(fontSize: 10.sp, color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Message message, bool isMe) {
    if (message.isImage && message.fileUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.network(
          message.fileUrl!,
          width: 200.w,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 200.w,
              height: 150.h,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      );
    }

    if (message.isFile && message.fileUrl != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.attach_file, size: 20.w, color: isMe ? Colors.white70 : AppColors.primary),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              message.fileName ?? 'File',
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.textPrimary,
        fontSize: 15.sp,
      ),
    );
  }

  Widget _buildInputBar(String userId, String userName, String? userPhotoUrl) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: AppColors.textSecondary),
              onPressed: () => _pickFile(userId, userName, userPhotoUrl),
            ),
            IconButton(
              icon: Icon(Icons.image, color: AppColors.primary),
              onPressed: () => _pickImage(userId, userName, userPhotoUrl),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(userId, userName, userPhotoUrl),
              ),
            ),
            SizedBox(width: 8.w),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                final isSending = state.status == ChatBlocStatus.sending;
                return CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: isSending
                      ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : IconButton(
                          icon: Icon(Icons.send, color: Colors.white, size: 20.w),
                          onPressed: () => _sendMessage(userId, userName, userPhotoUrl),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(String userId, String userName, String? userPhotoUrl) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(ChatSendMessage(
      roomId: widget.roomId,
      senderId: userId,
      senderName: userName,
      senderPhotoUrl: userPhotoUrl,
      content: text,
    ));

    _messageController.clear();
  }

  Future<void> _pickImage(String userId, String userName, String? userPhotoUrl) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      context.read<ChatBloc>().add(ChatSendFile(
        roomId: widget.roomId,
        senderId: userId,
        senderName: userName,
        senderPhotoUrl: userPhotoUrl,
        file: File(image.path),
        fileName: image.name,
        type: MessageType.image,
      ));
    }
  }

  Future<void> _pickFile(String userId, String userName, String? userPhotoUrl) async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      context.read<ChatBloc>().add(ChatSendFile(
        roomId: widget.roomId,
        senderId: userId,
        senderName: userName,
        senderPhotoUrl: userPhotoUrl,
        file: File(result.files.single.path!),
        fileName: result.files.single.name,
        type: MessageType.file,
      ));
    }
  }
}
