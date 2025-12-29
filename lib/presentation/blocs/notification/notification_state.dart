import 'package:equatable/equatable.dart';
import '../../../domain/entities/notification.dart';

/// Notification Bloc Status
enum NotificationBlocStatus {
  initial,
  loading,
  loaded,
  error,
}

/// Notification State
class NotificationState extends Equatable {
  final NotificationBlocStatus status;
  final List<AppNotification> notifications;
  final int unreadCount;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationBlocStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.errorMessage,
  });

  NotificationState copyWith({
    NotificationBlocStatus? status,
    List<AppNotification>? notifications,
    int? unreadCount,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, notifications, unreadCount, errorMessage];
}
