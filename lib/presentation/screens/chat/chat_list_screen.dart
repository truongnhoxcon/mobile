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

import '../../widgets/common/pastel_background.dart';

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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        title: Text(
          'Tin nhắn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22.sp,
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
      body: PastelBackground(
        child: BlocBuilder<ChatBloc, ChatState>(
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
        padding: EdgeInsets.fromLTRB(0, 12.h, 0, 80.h),
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
        onTap: () {
          context.push('/chat/${room.id}', extra: room).then((_) {
            // Reload rooms when returning from chat room (in case of deletion)
            _loadRooms();
          });
        },
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
      builder: (ctx) => _UserSearchSheet(
        currentUserId: currentUserId,
        onUserSelected: (user) {
          final userName = user.displayName ?? user.email;
          chatBloc.add(ChatCreatePrivateRoom(currentUserId, authState.user?.displayName ?? '', user.id, userName));
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tạo chat với $userName'),
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }
}

class _UserSearchSheet extends StatefulWidget {
  final String currentUserId;
  final Function(User) onUserSelected;

  const _UserSearchSheet({
    required this.currentUserId,
    required this.onUserSelected,
  });

  @override
  State<_UserSearchSheet> createState() => _UserSearchSheetState();
}

class _UserSearchSheetState extends State<_UserSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final UserDataSourceImpl _userDataSource = UserDataSourceImpl();
  
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    try {
      final users = await _userDataSource.getAllUsers();
      if (mounted) {
        setState(() {
          // Optimization: Only take top 50 users initially to avoid lag
          _allUsers = users.where((u) => u.id != widget.currentUserId).toList();
          _filteredUsers = _allUsers.take(50).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _allUsers.take(50).toList());
      return;
    }
    
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user.displayName ?? '').toLowerCase();
        final email = user.email.toLowerCase();
        return name.contains(lowerQuery) || email.contains(lowerQuery);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        '${_allUsers.length} đồng nghiệp trong công ty',
                        style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
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
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
                onChanged: _filterUsers,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Divider(height: 1, color: AppColors.border),
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 64.w, color: Colors.grey.shade300),
                            SizedBox(height: 16.h),
                            Text(
                              'Không tìm thấy ai',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16.sp),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
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
                                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                          style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                              ),
                              title: Text(userName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp)),
                              subtitle: Text(user.email, style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp)),
                              trailing: ElevatedButton(
                                onPressed: () => widget.onUserSelected(user),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                  elevation: 0,
                                ),
                                child: const Text('Chat'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
