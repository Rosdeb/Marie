enum NotificationType {
  quizReminder,
  referralBonus,
  streakAlert,
  systemUpdate,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final NotificationType type;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.type,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? '').toString().toLowerCase();
    NotificationType nType = NotificationType.systemUpdate;
    if (typeStr.contains('quiz') || typeStr.contains('practice')) {
      nType = NotificationType.quizReminder;
    } else if (typeStr.contains('referral') || typeStr.contains('bonus')) {
      nType = NotificationType.referralBonus;
    } else if (typeStr.contains('streak')) {
      nType = NotificationType.streakAlert;
    }

    String timeAgo = 'Just now';
    if (json['createdAt'] != null) {
      try {
        final date = DateTime.parse(json['createdAt'].toString());
        final diff = DateTime.now().difference(date);
        if (diff.inDays > 0) {
          timeAgo = '${diff.inDays}d ago';
        } else if (diff.inHours > 0) {
          timeAgo = '${diff.inHours}h ago';
        } else if (diff.inMinutes > 0) {
          timeAgo = '${diff.inMinutes}m ago';
        } else {
          timeAgo = 'Just now';
        }
      } catch (_) {}
    }

    return NotificationItem(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      message: (json['message'] ?? '').toString(),
      timeAgo: timeAgo,
      type: nType,
      isRead: json['isRead'] == true || json['read'] == true,
    );
  }

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? timeAgo,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timeAgo: timeAgo ?? this.timeAgo,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}
