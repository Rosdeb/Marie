import '../../data/models/subscription_models.dart';
import '../entities/entitlement_entity.dart';

abstract class SubscriptionRepository {
  Future<List<PlanModel>> getPlans();
  Future<Map<String, dynamic>> getOfficesGrouped();
  Future<EntitlementEntity> getMyAccess();
  Future<EntitlementEntity> syncRevenueCat();
  Future<bool> chooseOffices({
    required String subscriptionId,
    String? single,
    String? national,
    String? regional,
  });
  Future<EntitlementEntity?> getCachedEntitlement();
  Future<void> cacheEntitlement(EntitlementEntity entitlement);
}
