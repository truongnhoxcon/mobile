import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/chat_room.dart';
import '../../blocs/blocs.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<ChatBloc>(),
      child: const _ChatListContent(),
    );
  }
}

class _ChatListContent extends StatefulWidget {
  const _ChatListContent();

  @override
  State<_ChatListContent> createState() => _ChatListContentState();
}

class _ChatListContentState extends State<_ChatListContent> {
  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id;
    if (userId != null) {
      context.read<ChatBloc>().add(ChatSubscribeRooms(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tin nhắn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp)),
        actions: [
          IconButton(
            icon: Icon(Icons.group_add, size: 26.w),
            onPressed: () => _showCreateGroupDialog(context),
            tooltip: 'Tạo nhóm',
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.status == ChatBlocStatus.loading && state.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.rooms.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async => _loadRooms(),
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: state.rooms.length,
              itemBuilder: (context, index) => _buildChatItem(context, state.rooms[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewChatDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80.w, color: AppColors.textSecondary),
          SizedBox(height: 16.h),
          Text('Chưa có cuộc trò chuyện', style: TextStyle(fontSize: 18.sp, color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          Text('Nhấn + để bắt đầu chat', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, ChatRoom room) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id ?? '';
    final isUnread = room.lastMessageSenderId != null && room.lastMessageSenderId != currentUserId;

    return InkWell(
      onTap: () => context.push('/chat/${room.id}', extra: room),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: room.isGroup 
                    ? AppColors.info.withValues(alpha: 0.1) 
                    : AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: room.imageUrl != null ? NetworkImage(room.imageUrl!) : null,
                  child: room.imageUrl == null
                    ? Icon(
                        room.isGroup ? Icons.group : Icons.person,
                        color: room.isGroup ? AppColors.info : AppColors.primary,
                        size: 28.w,
                      )
                    : null,
                ),
                if (room.isGroup)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.group, size: 10.w, color: Colors.white),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (room.lastMessageTime != null)
                        Text(
                          _formatTime(room.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isUnread ? AppColors.primary : AppColors.textHint,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    room.lastMessage ?? 'Chưa có tin nhắn',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE', 'vi').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  void _showNewChatDialog(BuildContext context) {
    // TODO: Show user list to start new chat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng chọn người dùng đang phát triển')),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final authState = context.read<AuthBloc>().state;
    final userId = authState.user?.id ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, MediaQuery.of(ctx).viewInsets.bottom + 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tạo nhóm chat', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên nhóm *',
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  context.read<ChatBloc>().add(ChatCreateGroupRoom(
                    nameController.text.trim(),
                    [userId],
                    userId,
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('Tạo nhóm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
