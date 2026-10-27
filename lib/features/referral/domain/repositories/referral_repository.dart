import '../../data/models/referral_models.dart';

abstract class ReferralRepository {
  Future<SharePreviewModel> getSharePreview();
  Future<LinkedInStatusModel> getLinkedInStatus();
  Future<String?> getLinkedInAuthorizationUrl();
  Future<LinkedInShareResult> shareOnLinkedIn({String? message});
  Future<Map<String, dynamic>> claimDiscount();
  Future<Map<String, dynamic>> validatePromoCode(String code);
}
