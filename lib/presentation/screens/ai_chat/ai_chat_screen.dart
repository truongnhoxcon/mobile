/// AI Chat Screen
/// 
/// ChatBot interface for interacting with Groq AI.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/theme/app_colors.dart';
import '../../../config/dependencies/injection_container.dart' as di;
import '../../../domain/entities/ai_chat_message.dart';
import '../../../domain/entities/ai_action.dart';
import '../../blocs/ai_chat/ai_chat_bloc.dart';
import '../../blocs/ai_chat/ai_chat_event.dart';
import '../../blocs/ai_chat/ai_chat_state.dart';
import '../../blocs/auth/auth_bloc.dart';

class AIChatScreen extends StatelessWidget {
  const AIChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get current user from AuthBloc
    final authState = context.read<AuthBloc>().state;
    final currentUser = authState.user;

    return BlocProvider(
      create: (_) {
        final bloc = di.sl<AIChatBloc>();
        // Set user context if available
        if (currentUser != null) {
          bloc.add(AIChatSetUserContext(currentUser));
        }
        bloc.add(const AIChatLoadHistory());
        return bloc;
      },
      child: const _AIChatContent(),
    );
  }
}

class _AIChatContent extends StatefulWidget {
  const _AIChatContent();

  @override
  State<_AIChatContent> createState() => _AIChatContentState();
}

class _AIChatContentState extends State<_AIChatContent> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    context.read<AIChatBloc>().add(AIChatSendMessage(message));
    _messageController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 24.w),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp)),
                Text('Powered by Groq', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Lịch sử chat',
            onPressed: () => _showChatHistory(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xóa lịch sử',
            onPressed: () => _showClearConfirmation(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<AIChatBloc, AIChatState>(
              listener: (context, state) {
                if (state.messages.isNotEmpty) {
                  _scrollToBottom();
                }
              },
              builder: (context, state) {
                if (state.messages.isEmpty) {
                  return _buildWelcomeScreen();
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: state.messages.length + (state.isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.messages.length && state.isSending) {
                            return _buildTypingIndicator();
                          }
                          return _buildMessageBubble(state.messages[index]);
                        },
                      ),
                    ),
                    if (state.hasPendingActions)
                      _buildActionCards(state.pendingActions),
                  ],
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 60.w),
            ),
            SizedBox(height: 24.h),
            Text(
              'Xin chào! 👋',
              style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tôi là trợ lý AI, sẵn sàng giúp đỡ bạn!',
              style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            _buildSuggestionChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final suggestions = [
      'Tôi có bao nhiêu dự án?',
      'Công việc được giao cho tôi',
      'Thống kê công việc của tôi',
      'Tiến độ dự án hiện tại',
      'Hướng dẫn tạo task mới',
    ];

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.center,
      children: suggestions.map((text) {
        return ActionChip(
          label: Text(text, style: TextStyle(fontSize: 13.sp)),
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
          onPressed: () {
            _messageController.text = text;
            _sendMessage();
          },
        );
      }).toList(),
    );
  }

  Widget _buildMessageBubble(AIChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20.w),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: isUser ? Radius.circular(16.r) : Radius.circular(4.r),
                  bottomRight: isUser ? Radius.circular(4.r) : Radius.circular(16.r),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: TextStyle(color: Colors.white, fontSize: 15.sp),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(fontSize: 15.sp, color: AppColors.textPrimary),
                        code: TextStyle(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          fontSize: 13.sp,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8.w),
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Icon(Icons.person, color: AppColors.primary, size: 20.w),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 20.w),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                SizedBox(width: 4.w),
                _buildDot(1),
                SizedBox(width: 4.w),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3 + (0.5 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            BlocBuilder<AIChatBloc, AIChatState>(
              builder: (context, state) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: state.isSending ? null : _sendMessage,
                    icon: state.isSending
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          )
                        : Icon(Icons.send, color: Colors.white),
                    tooltip: 'Gửi',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa lịch sử'),
        content: const Text('Bạn có chắc muốn xóa toàn bộ lịch sử trò chuyện?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              context.read<AIChatBloc>().add(const AIChatClearHistory());
              Navigator.pop(ctx);
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showChatHistory(BuildContext context) {
    final bloc = context.read<AIChatBloc>();
    final state = bloc.state;
    final sessions = state.sessions;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
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
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Icon(Icons.history, color: AppColors.primary, size: 24.w),
                  SizedBox(width: 12.w),
                  Text(
                    'Lịch sử đoạn hội thoại',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // New conversation button
                  IconButton(
                    icon: Icon(Icons.add_circle, color: AppColors.primary, size: 28.w),
                    tooltip: 'Cuộc trò chuyện mới',
                    onPressed: () {
                      bloc.add(const AIChatCreateSession());
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
            Divider(height: 16.h),
            // Sessions list
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.forum_outlined, 
                            size: 64.w, 
                            color: Colors.grey.shade300),
                          SizedBox(height: 16.h),
                          Text(
                            'Chưa có cuộc trò chuyện nào',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          ElevatedButton.icon(
                            onPressed: () {
                              bloc.add(const AIChatCreateSession());
                              Navigator.pop(ctx);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Bắt đầu trò chuyện'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final isActive = session.id == state.currentSessionId;
                        return Container(
                          margin: EdgeInsets.only(bottom: 8.h),
                          decoration: BoxDecoration(
                            color: isActive 
                              ? AppColors.primary.withValues(alpha: 0.1) 
                              : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isActive ? AppColors.primary : AppColors.border,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            leading: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(Icons.chat, color: AppColors.primary, size: 20.w),
                            ),
                            title: Text(
                              session.preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14.sp,
                              ),
                            ),
                            subtitle: Text(
                              '${session.messages.length} tin nhắn • ${session.timeAgo}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20.w),
                              onSelected: (value) {
                                if (value == 'open') {
                                  bloc.add(AIChatSwitchSession(session.id));
                                  Navigator.pop(ctx);
                                } else if (value == 'delete') {
                                  bloc.add(AIChatDeleteSession(session.id));
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<String>(
                                  value: 'open',
                                  child: Row(
                                    children: [
                                      Icon(Icons.open_in_new, size: 18),
                                      SizedBox(width: 8),
                                      Text('Mở'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, size: 18, color: AppColors.error),
                                      const SizedBox(width: 8),
                                      Text('Xóa', style: TextStyle(color: AppColors.error)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              bloc.add(AIChatSwitchSession(session.id));
                              Navigator.pop(ctx);
                            },
                          ),
                        );
                      },
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
    
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${time.day}/${time.month}/${time.year}';
  }

  Widget _buildActionCards(List<AIAction> actions) {
    return Container(
      constraints: BoxConstraints(maxHeight: 280.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on, color: AppColors.warning, size: 20.w),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Hành động được đề xuất (${actions.length}):',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // Scrollable action list
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: actions.map((action) => _buildActionCard(action)).toList(),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // Bulk action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    for (final action in actions) {
                      context.read<AIChatBloc>().add(AIChatRejectAction(action));
                    }
                  },
                  icon: Icon(Icons.close, size: 18.w),
                  label: const Text('Từ chối tất cả'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    for (final action in actions) {
                      context.read<AIChatBloc>().add(AIChatExecuteAction(action));
                      // Small delay between executions
                      await Future.delayed(const Duration(milliseconds: 300));
                    }
                  },
                  icon: Icon(Icons.check_circle, size: 18.w),
                  label: const Text('Thực hiện tất cả'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(AIAction action) {
    final isExecuting = context.watch<AIChatBloc>().state.isExecutingAction;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  _getActionIcon(action.type),
                  color: AppColors.primary,
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.type.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      action.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: isExecuting ? null : () {
                  context.read<AIChatBloc>().add(AIChatRejectAction(action));
                },
                icon: Icon(Icons.close, size: 18.w),
                label: const Text('Hủy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton.icon(
                onPressed: isExecuting ? null : () {
                  context.read<AIChatBloc>().add(AIChatExecuteAction(action));
                },
                icon: isExecuting 
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.check, size: 18.w),
                label: Text(isExecuting ? 'Đang xử lý...' : 'Thực hiện'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(AIActionType type) {
    switch (type) {
      case AIActionType.createTask:
        return Icons.add_task;
      case AIActionType.assignTask:
        return Icons.person_add;
      case AIActionType.updateTaskStatus:
        return Icons.update;
      case AIActionType.createProject:
        return Icons.create_new_folder;
    }
  }
}
