import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../data/models/notification_model.dart';

class NotificationState {
  final List<NotificationItem> items;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  const NotificationState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  NotificationState copyWith({
    List<NotificationItem>? items,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  late final ApiClient _apiClient;

  @override
  NotificationState build() {
    _apiClient = ref.watch(apiClientProvider);
    Future.microtask(() => fetchNotifications());
    return const NotificationState(isLoading: true);
  }

  Future<void> fetchNotifications() async {
    final token = await ref.read(localStorageProvider).getAccessToken();
    if (token == null || token.isEmpty) {
      state = const NotificationState(isLoading: false, items: [], unreadCount: 0);
      return;
    }

    if (!state.isLoading) {
      state = state.copyWith(isLoading: true);
    }
    try {
      final response = await _apiClient.get(
        ApiConstants.notifications,
        queryParams: {'page': '1', 'limit': '20'},
        requiresAuth: true,
      );

      final List<NotificationItem> loadedItems = [];
      if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        if (data['results'] is List) {
          for (final item in (data['results'] as List)) {
            if (item is Map<String, dynamic>) {
              loadedItems.add(NotificationItem.fromJson(item));
            }
          }
        }
      }

      int unread = loadedItems.where((i) => !i.isRead).length;
      try {
        final unreadResp = await _apiClient.get(
          ApiConstants.notificationUnreadCount,
          requiresAuth: true,
        );
        if (unreadResp is Map<String, dynamic> && unreadResp['data'] is Map<String, dynamic>) {
          unread = (unreadResp['data']['count'] as num?)?.toInt() ?? unread;
        }
      } catch (_) {}

      state = state.copyWith(
        items: loadedItems,
        unreadCount: unread,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.patch(
        ApiConstants.notificationMarkAsRead,
        body: {},
        requiresAuth: true,
      );
    } catch (_) {}

    state = state.copyWith(
      items: state.items.map((item) => item.copyWith(isRead: true)).toList(),
      unreadCount: 0,
    );
  }

  void markAsRead(String id) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true);
        }
        return item;
      }).toList(),
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );
  }

  void clearAll() {
    state = state.copyWith(items: const [], unreadCount: 0);
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
        NotificationNotifier.new);

final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifState = ref.watch(notificationProvider);
  return notifState.unreadCount;
});
