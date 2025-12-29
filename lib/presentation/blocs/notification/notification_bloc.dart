import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/notification.dart';
import 'notification_event.dart';
import 'notification_state.dart';

/// Notification BLoC
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(const NotificationState()) {
    on<NotificationLoadAll>(_onLoadAll);
    on<NotificationMarkRead>(_onMarkRead);
    on<NotificationMarkAllRead>(_onMarkAllRead);
    on<NotificationDelete>(_onDelete);
  }

  Future<void> _onLoadAll(
    NotificationLoadAll event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationBlocStatus.loading));

    // TODO: Replace with actual API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data
    final mockNotifications = [
      AppNotification(
        id: '1',
        type: NotificationType.leaveRequestApproved,
        title: 'Đơn nghỉ phép được duyệt',
        content: 'Đơn xin nghỉ phép từ 26/12 đến 27/12 đã được duyệt.',
        recipientId: 'user1',
        senderName: 'HR Manager',
        priority: NotificationPriority.normal,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        deepLink: '/hr/leave',
      ),
      AppNotification(
        id: '2',
        type: NotificationType.projectAssigned,
        title: 'Bạn được giao dự án mới',
        content: 'Bạn đã được thêm vào dự án "Mobile App Development".',
        recipientId: 'user1',
        senderName: 'PM',
        priority: NotificationPriority.high,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        deepLink: '/projects',
      ),
      AppNotification(
        id: '3',
        type: NotificationType.attendanceWarning,
        title: 'Cảnh báo chấm công',
        content: 'Bạn chưa chấm công hôm nay (25/12).',
        recipientId: 'user1',
        priority: NotificationPriority.urgent,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        deepLink: '/hr',
      ),
      AppNotification(
        id: '4',
        type: NotificationType.salaryPaid,
        title: 'Lương tháng 12 đã thanh toán',
        content: 'Lương tháng 12/2024 đã được chuyển vào tài khoản.',
        recipientId: 'user1',
        status: NotificationStatus.read,
        priority: NotificationPriority.normal,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        readAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      AppNotification(
        id: '5',
        type: NotificationType.contractExpiring,
        title: 'Hợp đồng sắp hết hạn',
        content: 'Hợp đồng lao động của bạn sẽ hết hạn trong 30 ngày.',
        recipientId: 'user1',
        priority: NotificationPriority.high,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        deepLink: '/my-info',
      ),
    ];

    final unreadCount = mockNotifications.where((n) => n.isUnread).length;

    emit(state.copyWith(
      status: NotificationBlocStatus.loaded,
      notifications: mockNotifications,
      unreadCount: unreadCount,
    ));
  }

  Future<void> _onMarkRead(
    NotificationMarkRead event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedNotifications = state.notifications.map((n) {
      if (n.id == event.notificationId) {
        return n.copyWith(
          status: NotificationStatus.read,
          readAt: DateTime.now(),
        );
      }
      return n;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => n.isUnread).length;

    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    ));
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedNotifications = state.notifications.map((n) {
      if (n.isUnread) {
        return n.copyWith(
          status: NotificationStatus.read,
          readAt: DateTime.now(),
        );
      }
      return n;
    }).toList();

    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    ));
  }

  Future<void> _onDelete(
    NotificationDelete event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedNotifications = state.notifications
        .where((n) => n.id != event.notificationId)
        .toList();

    final unreadCount = updatedNotifications.where((n) => n.isUnread).length;

    emit(state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    ));
  }
}
