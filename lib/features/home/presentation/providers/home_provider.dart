import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/home_models.dart';

/// The Home screen's own state.
///
/// One request for all eight sections, so the screen draws once. A failure
/// leaves whatever was loaded before on screen and reports itself, rather than
/// replacing a working Home with an error.
class HomeState {
  final bool isLoading;
  final String? errorMessage;
  final HomeData? data;

  const HomeState({this.isLoading = false, this.errorMessage, this.data});

  HomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    HomeData? data,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      data: data ?? this.data,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  late ApiClient _apiClient;
  late LocalStorage _storage;

  @override
  HomeState build() {
    _apiClient = ref.watch(apiClientProvider);
    _storage = ref.watch(localStorageProvider);
    final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));
    if (isAuth) {
      Future.microtask(_init);
      return const HomeState(isLoading: true);
    }
    return const HomeState(isLoading: false, data: null);
  }

  Future<void> _init() async {
    // 1. First hydrate from disk cache so the UI renders instantly without waiting
    try {
      final cachedJson = await _storage.getHomeData();
      if (cachedJson != null) {
        final cachedData = HomeData.fromJson(cachedJson);
        state = state.copyWith(data: cachedData);
      } else {
        final user = ref.read(authProvider).currentUser;
        final name = user?.firstName ??
            (user != null && user.name.isNotEmpty
                ? user.name.split(' ').first
                : '');
        state = state.copyWith(data: HomeData.fallback(firstName: name));
      }
    } catch (e) {
      debugPrint('[Home] Cache hydration failed: $e');
    }

    // 2. Fetch fresh data from network in background
    await load();
  }

  void clear() {
    _storage.clearHomeData();
    state = const HomeState(isLoading: false, data: null);
  }

  Future<void> load() async {
    final token = await _storage.getAccessToken();
    final isAuth = ref.read(authProvider).isAuthenticated ||
        (token != null && token.isNotEmpty);
    if (!isAuth) {
      state = const HomeState(isLoading: false, data: null);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.get(ApiConstants.home);
      Map<String, dynamic>? body;
      if (response is Map<String, dynamic>) {
        if (response['data'] is Map<String, dynamic>) {
          body = response['data'] as Map<String, dynamic>;
        } else if (response['data'] is Map) {
          body = Map<String, dynamic>.from(response['data'] as Map);
        } else {
          body = response;
        }
      } else if (response is Map) {
        body = Map<String, dynamic>.from(response);
      }

      if (body != null) {
        final homeData = HomeData.fromJson(body);
        state = HomeState(isLoading: false, data: homeData);
        await _storage.saveHomeData(body);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Home could not be loaded.',
      );
    } catch (e) {
      debugPrint('[Home] load failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Home could not be refreshed. Please try again.',
      );
    }
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
