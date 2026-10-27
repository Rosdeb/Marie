import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage.dart';
import '../models/subscription_models.dart';

abstract class SubscriptionRemoteDataSource {
  Future<List<PlanModel>> getPlans();
  Future<Map<String, dynamic>> getOfficesGrouped();
  Future<UserAccessModel> getMyAccess();
  Future<UserAccessModel> syncRevenueCat();
  Future<bool> chooseOffices({
    required String subscriptionId,
    String? single,
    String? national,
    String? regional,
  });
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  final ApiClient apiClient;

  SubscriptionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PlanModel>> getPlans() async {
    final response = await apiClient.get(
      ApiConstants.subscriptionPlans,
      requiresAuth: false,
    );
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((item) => PlanModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getOfficesGrouped() async {
    final response = await apiClient.get(
      ApiConstants.subscriptionOffices,
      requiresAuth: false,
    );
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  @override
  Future<UserAccessModel> getMyAccess() async {
    final response = await apiClient.get(
      ApiConstants.subscriptionMyAccess,
      requiresAuth: true,
    );
    final data = response['data'];
    return UserAccessModel.fromJson(data);
  }

  @override
  Future<UserAccessModel> syncRevenueCat() async {
    // The sync endpoint only acknowledges the operation (`data` is null). The
    // authoritative access state lives at /subscription/my-access, so always
    // read it after the sync completes instead of replacing local state with
    // an empty entitlement.
    await apiClient.post(
      ApiConstants.subscriptionSync,
      body: {},
      requiresAuth: true,
    );
    return getMyAccess();
  }

  @override
  Future<bool> chooseOffices({
    required String subscriptionId,
    String? single,
    String? national,
    String? regional,
  }) async {
    final body = <String, dynamic>{};
    if (single != null) body['single'] = single;
    if (national != null) body['national'] = national;
    if (regional != null) body['regional'] = regional;

    await apiClient.patch(
      ApiConstants.subscriptionChooseOffices(subscriptionId),
      body: body,
      requiresAuth: true,
    );
    return true;
  }
}

final subscriptionRemoteDataSourceProvider =
    Provider<SubscriptionRemoteDataSource>((ref) {
      final localStorage = ref.watch(localStorageProvider);
      final apiClient = ApiClient(localStorage: localStorage);
      return SubscriptionRemoteDataSourceImpl(apiClient: apiClient);
    });
