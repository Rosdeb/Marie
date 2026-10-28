import '../../data/models/referral_models.dart';

abstract class ReferralRepository {
  Future<SharePreviewModel> getSharePreview();
  Future<LinkedInStatusModel> getLinkedInStatus();
  Future<String?> getLinkedInAuthorizationUrl();
  Future<LinkedInShareResult> shareOnLinkedIn({String? postMessage});
  Future<Map<String, dynamic>> validatePromoCode(String code);
  Future<Map<String, dynamic>> redeemPromoCode(RedeemRequestModel request);
  Future<dynamic> getContentVideos();
  Future<dynamic> getReferralCopy();
  Future<dynamic> getDiscountOffer();
}
