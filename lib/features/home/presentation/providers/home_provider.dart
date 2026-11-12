import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
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
  late final ApiClient _apiClient;

  @override
  HomeState build() {
    _apiClient = ref.watch(apiClientProvider);
    Future.microtask(load);
    return const HomeState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _apiClient.get(ApiConstants.home);
      final body = response is Map<String, dynamic> ? response['data'] : null;
      if (body is Map<String, dynamic>) {
        state = HomeState(isLoading: false, data: HomeData.fromJson(body));
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
        // Whatever was already loaded stays on screen; this only explains the
        // pull-to-refresh that did not work.
        errorMessage: 'Home could not be refreshed. Please try again.',
      );
    }
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
