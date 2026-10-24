import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';

class NotificationNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    return const [
      NotificationItem(
        id: '1',
        title: 'Daily Practice Reminder',
        message: 'Your daily quiz in Human Anatomy is waiting. Keep up your study streak!',
        timeAgo: '15m ago',
        type: NotificationType.quizReminder,
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'Referral Bonus Earned',
        message: 'Your colleague joined using your code. \$5 study credits added to your wallet.',
        timeAgo: '2h ago',
        type: NotificationType.referralBonus,
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: '3-Day Study Streak!',
        message: 'You have completed quizzes 3 days in a row. Great momentum!',
        timeAgo: '1d ago',
        type: NotificationType.streakAlert,
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: 'New Questions Added',
        message: '50 new Patent & Trademark questions have been added to the library.',
        timeAgo: '2d ago',
        type: NotificationType.systemUpdate,
        isRead: true,
      ),
    ];
  }

  void markAsRead(String id) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((item) => item.copyWith(isRead: true)).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, List<NotificationItem>>(
        NotificationNotifier.new);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationProvider);
  return list.where((item) => !item.isRead).length;
});
