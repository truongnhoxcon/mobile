import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/notification.dart';
import '../../blocs/blocs.dart';

import '../../widgets/common/pastel_background.dart';

/// Notification Screen - View and manage notifications
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationBloc()..add(const NotificationLoadAll()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Thông báo',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state.unreadCount > 0) {
                  return TextButton(
                    onPressed: () => context.read<NotificationBloc>().add(const NotificationMarkAllRead()),
                    child: Text(
                      'Đọc tất cả',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: PastelBackground(
          child: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state.status == NotificationBlocStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 64.w, color: AppColors.textSecondary),
                    SizedBox(height: 16.h),
                    Text(
                      'Không có thông báo',
                      style: TextStyle(fontSize: 16.sp, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => context.read<NotificationBloc>().add(const NotificationLoadAll()),
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: state.notifications.length,
                separatorBuilder: (_, __) => SizedBox(height: 8.h),
                itemBuilder: (context, index) => _NotificationCard(
                  notification: state.notifications[index],
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => context.read<NotificationBloc>().add(NotificationDelete(notification.id)),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.delete, color: Colors.white, size: 24.w),
      ),
      child: InkWell(
        onTap: () {
          // Mark as read
          if (notification.isUnread) {
            context.read<NotificationBloc>().add(NotificationMarkRead(notification.id));
          }
          // Navigate if deep link exists
          if (notification.deepLink != null) {
            context.push(notification.deepLink!);
          }
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: notification.isUnread 
              ? AppColors.primary.withValues(alpha: 0.05) 
              : AppColors.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: notification.isUnread 
                ? AppColors.primary.withValues(alpha: 0.2) 
                : AppColors.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Icon
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: _getTypeColor(notification.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  _getTypeIcon(notification.type),
                  color: _getTypeColor(notification.type),
                  size: 24.w,
                ),
              ),
              SizedBox(width: 12.w),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: notification.isUnread ? FontWeight.bold : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (notification.isUrgent)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'Khẩn',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12.w, color: AppColors.textSecondary),
                        SizedBox(width: 4.w),
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                        ),
                        if (notification.senderName != null) ...[
                          SizedBox(width: 12.w),
                          Icon(Icons.person_outline, size: 12.w, color: AppColors.textSecondary),
                          SizedBox(width: 4.w),
                          Text(
                            notification.senderName!,
                            style: TextStyle(fontSize: 11.sp, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Unread indicator
              if (notification.isUnread)
                Container(
                  width: 8.w,
                  height: 8.w,
                  margin: EdgeInsets.only(left: 8.w),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.contractExpiring:
        return Icons.description;
      case NotificationType.leaveRequestPending:
      case NotificationType.leaveRequestApproved:
      case NotificationType.leaveRequestRejected:
        return Icons.event_available;
      case NotificationType.salaryApproved:
      case NotificationType.salaryPaid:
        return Icons.paid;
      case NotificationType.attendanceWarning:
        return Icons.access_time;
      case NotificationType.evaluation:
        return Icons.rate_review;
      case NotificationType.projectAssigned:
      case NotificationType.projectDeadline:
        return Icons.folder_special;
      case NotificationType.chatMessage:
        return Icons.chat_bubble;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.contractExpiring:
        return const Color(0xFFF59E0B); // Amber
      case NotificationType.leaveRequestPending:
        return const Color(0xFF6366F1); // Indigo
      case NotificationType.leaveRequestApproved:
        return AppColors.success;
      case NotificationType.leaveRequestRejected:
        return AppColors.error;
      case NotificationType.salaryApproved:
      case NotificationType.salaryPaid:
        return const Color(0xFF10B981); // Emerald
      case NotificationType.attendanceWarning:
        return AppColors.error;
      case NotificationType.evaluation:
        return const Color(0xFF8B5CF6); // Purple
      case NotificationType.projectAssigned:
      case NotificationType.projectDeadline:
        return const Color(0xFF3B82F6); // Blue
      case NotificationType.chatMessage:
        return const Color(0xFFFF6B00); // Orange
      case NotificationType.system:
        return AppColors.textSecondary;
      case NotificationType.general:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }
}
