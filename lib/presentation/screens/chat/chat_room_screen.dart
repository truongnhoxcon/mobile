import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

import '../../widgets/common/pastel_background.dart';

class ChatRoomScreen extends StatelessWidget {
  final String roomId;
  final ChatRoom? room;
  final String? projectOwnerId; // PM của project (nếu là project chat)

  const ChatRoomScreen({
    super.key, 
    required this.roomId, 
    this.room,
    this.projectOwnerId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ChatBloc>()..add(ChatSubscribeMessages(roomId)),
      child: _ChatRoomContent(
        roomId: roomId, 
        room: room,
        projectOwnerId: projectOwnerId,
      ),
    );
  }
}

class _ChatRoomContent extends StatefulWidget {
  final String roomId;
  final ChatRoom? room;
  final String? projectOwnerId;

  const _ChatRoomContent({
    required this.roomId, 
    this.room,
    this.projectOwnerId,
  });

  @override
  State<_ChatRoomContent> createState() => _ChatRoomContentState();
}

class _ChatRoomContentState extends State<_ChatRoomContent> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Reply state
  Message? _replyingTo;
  
  // Mention state
  bool _showMentionPicker = false;
  List<String> _mentionedUserIds = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _setReplyTo(Message message) {
    setState(() => _replyingTo = message);
  }
  
  void _cancelReply() {
    setState(() => _replyingTo = null);
  }

  // ============================================================================
  // Room Management Methods (PM only)
  // ============================================================================

  /// Check if current user can manage the room (is project owner/PM)
  bool _canManageRoom(String? currentUserId) {
    if (currentUserId == null) return false;
    
    // For project chat rooms
    if (widget.room?.isProject == true) {
      // If projectOwnerId is provided, use it
      if (widget.projectOwnerId != null) {
        return currentUserId == widget.projectOwnerId;
      }
      // Otherwise, check if user is the room creator (who is the PM)
      return widget.room?.createdBy == currentUserId;
    }
    
    // For group rooms, check if user created it
    if (widget.room?.isGroup == true) {
      return widget.room?.createdBy == currentUserId;
    }
    
    return false;
  }

  void _handleRoomAction(String action, BuildContext context) {
    switch (action) {
      case 'members':
        _showMembersDialog(context);
        break;
      case 'add_member':
        _showAddMemberDialog(context);
        break;
      case 'delete_room':
        _showDeleteRoomConfirmation(context);
        break;
    }
  }

  void _showMembersDialog(BuildContext context) {
    final room = widget.room;
    if (room == null) return;
    final currentUserId = context.read<AuthBloc>().state.user?.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Icon(Icons.people, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Text(
                    'Thành viên (${room.memberIds.length})',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: room.memberIds.length,
                itemBuilder: (context, index) {
                  final memberId = room.memberIds[index];
                  final memberName = room.memberNames[memberId] ?? 'Unknown';
                  final isOwner = memberId == widget.projectOwnerId;
                  final isCurrentUser = memberId == currentUserId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        memberName[0].toUpperCase(),
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                    title: Text(memberName),
                    subtitle: isOwner ? Text('Project Manager', style: TextStyle(color: AppColors.primary)) : null,
                    trailing: (!isOwner && !isCurrentUser && _canManageRoom(currentUserId))
                        ? IconButton(
                            icon: Icon(Icons.remove_circle, color: AppColors.error),
                            onPressed: () => _confirmRemoveMember(ctx, memberId, memberName),
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, String userId, String userName) {
    final chatBloc = this.context.read<ChatBloc>();
    final scaffoldMessenger = ScaffoldMessenger.of(this.context);
    final outerNavigator = Navigator.of(context); // For closing member sheet
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa $userName khỏi phòng chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              outerNavigator.pop(); // Close member sheet
              chatBloc.add(ChatRemoveMember(
                roomId: widget.roomId,
                userId: userId,
              ));
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('Đã xóa $userName khỏi phòng chat')),
              );
            },
            child: Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    // For now, show a simple dialog - in full implementation, 
    // this would load project members who are not yet in the chat
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_add, color: AppColors.primary),
            SizedBox(width: 8.w),
            const Text('Thêm thành viên'),
          ],
        ),
        content: Text(
          'Tính năng này sẽ cho phép thêm thành viên từ danh sách thành viên dự án.\n\n'
          'Hiện tại, thành viên sẽ tự động được thêm khi họ được thêm vào dự án.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRoomConfirmation(BuildContext context) {
    final chatBloc = context.read<ChatBloc>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8.w),
            const Text('Xóa phòng chat'),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn xóa phòng chat này?\n\n'
          'Tất cả tin nhắn sẽ bị xóa vĩnh viễn và không thể khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              chatBloc.add(ChatDeleteRoom(widget.roomId));
              navigator.pop(); // Go back to chat list
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Đã xóa phòng chat')),
              );
            },
            child: Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
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
              backgroundColor: Colors.white,
              backgroundImage: widget.room?.imageUrl != null ? NetworkImage(widget.room!.imageUrl!) : null,
              child: widget.room?.imageUrl == null
                  ? Text(
                      (widget.room?.getDisplayName(currentUser?.id ?? '') ?? 'C')[0].toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room?.getDisplayName(currentUser?.id ?? '') ?? 'Chat',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Typing indicator in app bar
                  if (widget.room != null && currentUser != null)
                    BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        final typingText = widget.room!.getTypingText(currentUser.id);
                        if (typingText.isEmpty) {
                           // Show "Online" or member count if not typing
                           if (widget.room!.isGroup || widget.room!.isProject) {
                             return Text(
                               '${widget.room!.memberIds.length} thành viên',
                               style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                             );
                           }
                           return const SizedBox.shrink();
                        }
                        return Text(
                          typingText,
                          style: TextStyle(fontSize: 11.sp, color: Colors.white70, fontStyle: FontStyle.italic),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        actions: [
          // Room management menu for PM only (project chat rooms)
          if (_canManageRoom(currentUser?.id))
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _handleRoomAction(value, context),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'members',
                  child: ListTile(
                    leading: Icon(Icons.people),
                    title: Text('Xem thành viên'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'add_member',
                  child: ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text('Thêm thành viên'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'delete_room',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: AppColors.error),
                    title: Text('Xóa phòng chat', style: TextStyle(color: AppColors.error)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: PastelBackground(
          child: Column(
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

                        return _buildMessageBubble(message, isMe, showAvatar, currentUser?.id ?? '');
                      },
                    );
                  },
                ),
              ),
              // Reply preview bar
              if (_replyingTo != null) _buildReplyPreview(),
              _buildInputBar(currentUser?.id ?? '', currentUser?.displayName ?? 'User', currentUser?.photoUrl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 3),
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, color: AppColors.primary, size: 20.w),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trả lời ${_replyingTo!.senderName}',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12.sp),
                ),
                Text(
                  _replyingTo!.content.length > 50 
                      ? '${_replyingTo!.content.substring(0, 50)}...' 
                      : _replyingTo!.content,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20.w),
            onPressed: _cancelReply,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool showAvatar, String currentUserId) {
    // Check if message is deleted
    if (message.isDeleted) {
      return _buildDeletedMessage(message, isMe, showAvatar);
    }
    
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message, isMe, currentUserId),
      child: Padding(
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
                  
                  // Reply preview if this message is a reply
                  if (message.isReply) _buildReplyReference(message, isMe),
                  
                  Container(
                    constraints: BoxConstraints(maxWidth: 280.w),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(message.isReply ? 4.r : 16.r),
                        topRight: Radius.circular(message.isReply ? 4.r : 16.r),
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
                  
                  // Reactions display
                  if (message.hasReactions) _buildReactionsDisplay(message, currentUserId),
                  
                  // Time and edited indicator
                  Padding(
                    padding: EdgeInsets.only(top: 4.h, left: 4.w, right: 4.w),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(fontSize: 10.sp, color: AppColors.textHint),
                        ),
                        if (message.isEdited) ...[
                          SizedBox(width: 4.w),
                          Text('(đã sửa)', style: TextStyle(fontSize: 10.sp, color: AppColors.textHint, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  



  
  Widget _buildDeletedMessage(Message message, bool isMe, bool showAvatar) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && showAvatar)
            CircleAvatar(radius: 16.r, backgroundColor: AppColors.textSecondary.withValues(alpha: 0.1))
          else if (!isMe)
            SizedBox(width: 32.w),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 16.w, color: AppColors.textHint),
                SizedBox(width: 6.w),
                Text(
                  message.isDeletedForEveryone ? 'Tin nhắn đã thu hồi' : 'Tin nhắn đã xóa',
                  style: TextStyle(color: AppColors.textHint, fontStyle: FontStyle.italic, fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReplyReference(Message message, bool isMe) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(8.w),
      constraints: BoxConstraints(maxWidth: 280.w),
      decoration: BoxDecoration(
        color: (isMe ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
        border: Border(
          left: BorderSide(color: isMe ? Colors.white70 : AppColors.primary, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyToSenderName ?? '',
            style: TextStyle(
              color: isMe ? Colors.white70 : AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
            ),
          ),
          Text(
            message.replyToContent ?? '',
            style: TextStyle(
              color: isMe ? Colors.white60 : AppColors.textSecondary,
              fontSize: 11.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Widget _buildReactionsDisplay(Message message, String currentUserId) {
    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: Wrap(
        spacing: 4.w,
        children: message.reactions.map((reaction) {
          final hasReacted = reaction.userIds.contains(currentUserId);
          return GestureDetector(
            onTap: () => _toggleReaction(message, reaction.emoji, currentUserId),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: hasReacted 
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: hasReacted ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(reaction.emoji, style: TextStyle(fontSize: 14.sp)),
                  if (reaction.count > 1) ...[
                    SizedBox(width: 2.w),
                    Text('${reaction.count}', style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  void _showMessageOptions(Message message, bool isMe, String currentUserId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reaction bar
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ReactionEmojis.defaults.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _toggleReaction(message, emoji, currentUserId);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: message.hasUserReacted(currentUserId, emoji)
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: TextStyle(fontSize: 24.sp)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            // Actions
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Trả lời'),
              onTap: () {
                Navigator.pop(context);
                _setReplyTo(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Sao chép'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã sao chép'), duration: Duration(seconds: 1)),
                );
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.error),
                title: Text('Xóa cho tôi', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message, false);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppColors.error),
                title: Text('Thu hồi (xóa cho mọi người)', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message, true);
                },
              ),
            ],
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
  
  void _toggleReaction(Message message, String emoji, String currentUserId) {
    context.read<ChatBloc>().add(ChatToggleReaction(
      messageId: message.id,
      roomId: widget.roomId,
      emoji: emoji,
      userId: currentUserId,
    ));
  }
  
  void _deleteMessage(Message message, bool forEveryone) {
    context.read<ChatBloc>().add(ChatDeleteMessage(
      messageId: message.id,
      roomId: widget.roomId,
      forEveryone: forEveryone,
    ));
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

    // Build text with highlighted mentions
    if (message.hasMentions) {
      return _buildMentionText(message, isMe);
    }

    return Text(
      message.content,
      style: TextStyle(
        color: isMe ? Colors.white : AppColors.textPrimary,
        fontSize: 15.sp,
      ),
    );
  }
  
  Widget _buildMentionText(Message message, bool isMe) {
    final spans = <TextSpan>[];
    int lastIndex = 0;
    
    for (final mention in message.mentions) {
      // Add text before mention
      if (mention.startIndex > lastIndex) {
        spans.add(TextSpan(
          text: message.content.substring(lastIndex, mention.startIndex),
          style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 15.sp),
        ));
      }
      // Add highlighted mention
      spans.add(TextSpan(
        text: '@${mention.displayName}',
        style: TextStyle(
          color: isMe ? Colors.yellowAccent : AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 15.sp,
        ),
      ));
      lastIndex = mention.endIndex;
    }
    // Add remaining text
    if (lastIndex < message.content.length) {
      spans.add(TextSpan(
        text: message.content.substring(lastIndex),
        style: TextStyle(color: isMe ? Colors.white : AppColors.textPrimary, fontSize: 15.sp),
      ));
    }
    
    return RichText(text: TextSpan(children: spans));
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
                onChanged: (text) {
                  // Detect @ for mentions
                  if (text.endsWith('@') && widget.room != null) {
                    setState(() => _showMentionPicker = true);
                  }
                },
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
      replyToId: _replyingTo?.id,
      replyToContent: _replyingTo?.content,
      replyToSenderName: _replyingTo?.senderName,
      mentions: _mentionedUserIds,
    ));

    _messageController.clear();
    _cancelReply();
    setState(() => _mentionedUserIds = []);
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
