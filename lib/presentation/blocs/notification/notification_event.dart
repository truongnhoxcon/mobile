import 'package:equatable/equatable.dart';
import '../../../domain/entities/notification.dart';

/// Notification Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Load notifications
class NotificationLoadAll extends NotificationEvent {
  const NotificationLoadAll();
}

/// Mark as read
class NotificationMarkRead extends NotificationEvent {
  final String notificationId;
  const NotificationMarkRead(this.notificationId);
  
  @override
  List<Object?> get props => [notificationId];
}

/// Mark all as read
class NotificationMarkAllRead extends NotificationEvent {
  const NotificationMarkAllRead();
}

/// Delete notification
class NotificationDelete extends NotificationEvent {
  final String notificationId;
  const NotificationDelete(this.notificationId);
  
  @override
  List<Object?> get props => [notificationId];
}
