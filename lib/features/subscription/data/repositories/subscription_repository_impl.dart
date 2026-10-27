import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_datasource.dart';
import '../models/subscription_models.dart';

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource remoteDataSource;
  static const String _entitlementCacheKey = 'cached_entitlement_data';

  SubscriptionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<PlanModel>> getPlans() async {
    return await remoteDataSource.getPlans();
  }

  @override
  Future<Map<String, dynamic>> getOfficesGrouped() async {
    return await remoteDataSource.getOfficesGrouped();
  }

  @override
  Future<EntitlementEntity> getMyAccess() async {
    try {
      final model = await remoteDataSource.getMyAccess();
      final entity = model.toEntity();
      await cacheEntitlement(entity);
      return entity;
    } catch (e) {
      // Fallback to cached entitlement if offline
      final cached = await getCachedEntitlement();
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<EntitlementEntity> syncRevenueCat() async {
    final model = await remoteDataSource.syncRevenueCat();
    final entity = model.toEntity();
    await cacheEntitlement(entity);
    return entity;
  }

  @override
  Future<bool> chooseOffices({
    required String subscriptionId,
    String? single,
    String? national,
    String? regional,
  }) async {
    return await remoteDataSource.chooseOffices(
      subscriptionId: subscriptionId,
      single: single,
      national: national,
      regional: regional,
    );
  }

  @override
  Future<EntitlementEntity?> getCachedEntitlement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_entitlementCacheKey);
      if (str == null || str.isEmpty) return null;
      final map = jsonDecode(str) as Map<String, dynamic>;
      final model = UserAccessModel.fromJson(map);
      return model.toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cacheEntitlement(EntitlementEntity entitlement) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'tier': entitlement.planId.name,
        'status': entitlement.status.name,
        'billingPeriod': entitlement.billingPeriod,
        'subscriptionId': entitlement.subscriptionId,
        'periodStart': entitlement.periodStart?.toIso8601String(),
        'periodEnd': entitlement.periodEnd?.toIso8601String(),
        'officeCodes': entitlement.includedOffices,
        'selectedOffices': entitlement.selectedOffices,
        'canChangeOffices': entitlement.officeChangeAllowed,
        'nextChangeDate': entitlement.nextOfficeChangeDate?.toIso8601String(),
        'needsOfficeSelection': entitlement.needsOfficeSelection,
        'activeTiers': entitlement.activePlans
            .map((tier) => tier.name)
            .toList(),
      };
      await prefs.setString(_entitlementCacheKey, jsonEncode(map));
    } catch (_) {}
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final remote = ref.watch(subscriptionRemoteDataSourceProvider);
  return SubscriptionRepositoryImpl(remoteDataSource: remote);
});
