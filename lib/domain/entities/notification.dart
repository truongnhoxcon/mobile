import 'package:equatable/equatable.dart';

/// Notification Type - Based on DACN ThongBao.LoaiThongBao
enum NotificationType {
  contractExpiring,   // HOP_DONG_HET_HAN
  leaveRequestPending, // NGHI_PHEP_CHO_DUYET
  leaveRequestApproved, // NGHI_PHEP_DA_DUYET
  leaveRequestRejected, // NGHI_PHEP_TU_CHOI
  salaryApproved,     // LUONG_DA_DUYET
  salaryPaid,         // LUONG_DA_THANH_TOAN
  attendanceWarning,  // CHAM_CONG_CANH_BAO
  evaluation,         // DANH_GIA_NHAN_VIEN
  projectAssigned,    // PROJECT_ASSIGNED
  projectDeadline,    // PROJECT_DEADLINE
  chatMessage,        // CHAT_MESSAGE
  system,             // SYSTEM_MAINTENANCE
  general,            // GENERAL
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.contractExpiring:
        return 'HOP_DONG_HET_HAN';
      case NotificationType.leaveRequestPending:
        return 'NGHI_PHEP_CHO_DUYET';
      case NotificationType.leaveRequestApproved:
        return 'NGHI_PHEP_DA_DUYET';
      case NotificationType.leaveRequestRejected:
        return 'NGHI_PHEP_TU_CHOI';
      case NotificationType.salaryApproved:
        return 'LUONG_DA_DUYET';
      case NotificationType.salaryPaid:
        return 'LUONG_DA_THANH_TOAN';
      case NotificationType.attendanceWarning:
        return 'CHAM_CONG_CANH_BAO';
      case NotificationType.evaluation:
        return 'DANH_GIA_NHAN_VIEN';
      case NotificationType.projectAssigned:
        return 'PROJECT_ASSIGNED';
      case NotificationType.projectDeadline:
        return 'PROJECT_DEADLINE';
      case NotificationType.chatMessage:
        return 'CHAT_MESSAGE';
      case NotificationType.system:
        return 'SYSTEM_MAINTENANCE';
      case NotificationType.general:
        return 'GENERAL';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.contractExpiring:
        return 'Hợp đồng';
      case NotificationType.leaveRequestPending:
        return 'Đơn nghỉ phép';
      case NotificationType.leaveRequestApproved:
        return 'Nghỉ phép duyệt';
      case NotificationType.leaveRequestRejected:
        return 'Nghỉ phép từ chối';
      case NotificationType.salaryApproved:
        return 'Lương';
      case NotificationType.salaryPaid:
        return 'Thanh toán lương';
      case NotificationType.attendanceWarning:
        return 'Chấm công';
      case NotificationType.evaluation:
        return 'Đánh giá';
      case NotificationType.projectAssigned:
        return 'Dự án';
      case NotificationType.projectDeadline:
        return 'Deadline';
      case NotificationType.chatMessage:
        return 'Tin nhắn';
      case NotificationType.system:
        return 'Hệ thống';
      case NotificationType.general:
        return 'Thông báo';
    }
  }

  static NotificationType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'HOP_DONG_HET_HAN':
        return NotificationType.contractExpiring;
      case 'NGHI_PHEP_CHO_DUYET':
        return NotificationType.leaveRequestPending;
      case 'NGHI_PHEP_DA_DUYET':
        return NotificationType.leaveRequestApproved;
      case 'NGHI_PHEP_TU_CHOI':
        return NotificationType.leaveRequestRejected;
      case 'LUONG_DA_DUYET':
        return NotificationType.salaryApproved;
      case 'LUONG_DA_THANH_TOAN':
        return NotificationType.salaryPaid;
      case 'CHAM_CONG_CANH_BAO':
        return NotificationType.attendanceWarning;
      case 'DANH_GIA_NHAN_VIEN':
        return NotificationType.evaluation;
      case 'PROJECT_ASSIGNED':
        return NotificationType.projectAssigned;
      case 'PROJECT_DEADLINE':
        return NotificationType.projectDeadline;
      case 'CHAT_MESSAGE':
        return NotificationType.chatMessage;
      case 'SYSTEM_MAINTENANCE':
        return NotificationType.system;
      default:
        return NotificationType.general;
    }
  }
}

/// Notification Status
enum NotificationStatus {
  unread,   // CHUA_DOC
  read,     // DA_DOC
  deleted,  // DA_XOA
}

extension NotificationStatusExtension on NotificationStatus {
  String get value {
    switch (this) {
      case NotificationStatus.unread:
        return 'CHUA_DOC';
      case NotificationStatus.read:
        return 'DA_DOC';
      case NotificationStatus.deleted:
        return 'DA_XOA';
    }
  }

  static NotificationStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'DA_DOC':
        return NotificationStatus.read;
      case 'DA_XOA':
        return NotificationStatus.deleted;
      default:
        return NotificationStatus.unread;
    }
  }
}

/// Notification Priority
enum NotificationPriority {
  low,      // THAP
  normal,   // BINH_THUONG
  high,     // CAO
  urgent,   // KHAN_CAP
}

extension NotificationPriorityExtension on NotificationPriority {
  String get value {
    switch (this) {
      case NotificationPriority.low:
        return 'THAP';
      case NotificationPriority.normal:
        return 'BINH_THUONG';
      case NotificationPriority.high:
        return 'CAO';
      case NotificationPriority.urgent:
        return 'KHAN_CAP';
    }
  }

  static NotificationPriority fromString(String value) {
    switch (value.toUpperCase()) {
      case 'THAP':
        return NotificationPriority.low;
      case 'CAO':
        return NotificationPriority.high;
      case 'KHAN_CAP':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }
}

/// Notification Entity - Based on DACN ThongBao
class AppNotification extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String content;
  final String recipientId;
  final String? senderId;
  final String? senderName;
  final NotificationStatus status;
  final NotificationPriority priority;
  final String? deepLink;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.recipientId,
    this.senderId,
    this.senderName,
    this.status = NotificationStatus.unread,
    this.priority = NotificationPriority.normal,
    this.deepLink,
    required this.createdAt,
    this.readAt,
  });

  bool get isUnread => status == NotificationStatus.unread;
  bool get isUrgent => priority == NotificationPriority.urgent || priority == NotificationPriority.high;

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? content,
    String? recipientId,
    String? senderId,
    String? senderName,
    NotificationStatus? status,
    NotificationPriority? priority,
    String? deepLink,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      deepLink: deepLink ?? this.deepLink,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
    id, type, title, content, recipientId, senderId, 
    senderName, status, priority, deepLink, createdAt, readAt
  ];
}
