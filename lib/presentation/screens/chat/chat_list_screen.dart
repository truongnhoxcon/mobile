import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/chat_room.dart';
import '../../../domain/entities/user.dart';
import '../../../data/datasources/user_datasource.dart';
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

class _ChatListContentState extends State<_ChatListContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRooms();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        title: Text(
          'Tin nhắn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_alt_1, color: Colors.white, size: 24.w),
            onPressed: () => _showSearchUserDialog(context),
            tooltip: 'Tìm người dùng',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, size: 20.w),
                      SizedBox(width: 8.w),
                      const Text('Cá nhân'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_special, size: 20.w),
                      SizedBox(width: 8.w),
                      const Text('Dự án'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.status == ChatBlocStatus.loading && state.rooms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter rooms: private for Cá nhân, project for Dự án
          final privateRooms = state.rooms.where((r) => r.isPrivate).toList();
          final projectRooms = state.rooms.where((r) => r.isProject || r.isGroup).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRoomList(
                privateRooms,
                'Chưa có tin nhắn cá nhân',
                'Tìm đồng nghiệp để bắt đầu trò chuyện',
                Icons.chat_bubble_outline,
                true,
              ),
              _buildRoomList(
                projectRooms,
                'Chưa có chat dự án',
                'Chat nhóm được tạo tự động khi có dự án mới',
                Icons.folder_outlined,
                false,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSearchUserDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Chat mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildRoomList(List<ChatRoom> rooms, String emptyTitle, String emptySubtitle, IconData emptyIcon, bool showAddButton) {
    if (rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(emptyIcon, size: 64.w, color: AppColors.primary),
              ),
              SizedBox(height: 24.h),
              Text(
                emptyTitle,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              if (showAddButton) ...[
                SizedBox(height: 24.h),
                OutlinedButton.icon(
                  onPressed: () => _showSearchUserDialog(context),
                  icon: const Icon(Icons.person_search),
                  label: const Text('Tìm đồng nghiệp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadRooms(),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        itemCount: rooms.length,
        separatorBuilder: (_, __) => Divider(height: 1, indent: 80.w),
        itemBuilder: (context, index) => _buildChatItem(context, rooms[index]),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, ChatRoom room) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id ?? '';
    final isUnread = room.lastMessageSenderId != null && room.lastMessageSenderId != currentUserId;
    
    // Use getDisplayName for private chats to show the other person's name
    final displayName = room.getDisplayName(currentUserId);

    Color avatarColor;
    IconData avatarIcon;
    if (room.isProject || room.isGroup) {
      avatarColor = AppColors.warning;
      avatarIcon = Icons.folder_special;
    } else {
      avatarColor = AppColors.primary;
      avatarIcon = Icons.person;
    }

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => context.push('/chat/${room.id}', extra: room),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56.w,
                height: 56.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [avatarColor.withValues(alpha: 0.8), avatarColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: avatarColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: room.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.network(room.imageUrl!, fit: BoxFit.cover),
                    )
                  : Icon(avatarIcon, color: Colors.white, size: 28.w),
              ),
              SizedBox(width: 16.w),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
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
                              fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                              color: isUnread ? AppColors.primary : AppColors.textHint,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.lastMessage ?? 'Bắt đầu trò chuyện...',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 10.w,
                            height: 10.w,
                            margin: EdgeInsets.only(left: 8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes}p';
    if (diff.inDays == 0) return DateFormat('HH:mm').format(time);
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return DateFormat('EEEE', 'vi').format(time);
    return DateFormat('dd/MM').format(time);
  }

  void _showSearchUserDialog(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.user?.id ?? '';
    final chatBloc = context.read<ChatBloc>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.person_search, color: AppColors.primary, size: 24.w),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tìm đồng nghiệp',
                            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Bắt đầu cuộc trò chuyện mới',
                            style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // Search field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên hoặc email...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: _isSearching 
                        ? Padding(
                            padding: EdgeInsets.all(12.w),
                            child: SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    ),
                    onChanged: (value) async {
                      if (value.trim().length >= 2) {
                        setModalState(() => _isSearching = true);
                        try {
                          final datasource = UserDataSourceImpl();
                          final results = await datasource.searchUsers(value.trim());
                          setModalState(() {
                            _searchResults = results.where((u) => u.id != currentUserId).toList();
                            _isSearching = false;
                          });
                        } catch (e) {
                          setModalState(() => _isSearching = false);
                        }
                      } else {
                        setModalState(() => _searchResults = []);
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Divider(height: 1),
              // Search results
              Expanded(
                child: _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 80.w, color: Colors.grey.shade300),
                          SizedBox(height: 16.h),
                          Text(
                            'Tìm kiếm đồng nghiệp',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Nhập ít nhất 2 ký tự để tìm kiếm',
                            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final userName = user.displayName ?? user.email;
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            leading: Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: user.photoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: Image.network(user.photoUrl!, fit: BoxFit.cover),
                                  )
                                : Center(
                                    child: Text(
                                      userName[0].toUpperCase(),
                                      style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                            ),
                            title: Text(userName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp)),
                            subtitle: Text(user.email, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
                            trailing: ElevatedButton(
                              onPressed: () {
                                final currentUserName = authState.user?.displayName ?? authState.user?.email ?? '';
                                chatBloc.add(ChatCreatePrivateRoom(currentUserId, currentUserName, user.id, userName));
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text('Đã tạo chat với $userName'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat, size: 16.w),
                                  SizedBox(width: 4.w),
                                  const Text('Chat'),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
