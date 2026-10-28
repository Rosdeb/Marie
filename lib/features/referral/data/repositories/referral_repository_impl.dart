import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/referral_repository.dart';
import '../datasources/referral_remote_datasource.dart';
import '../models/referral_models.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralRemoteDataSource remoteDataSource;

  ReferralRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SharePreviewModel> getSharePreview() async {
    return await remoteDataSource.getSharePreview();
  }

  @override
  Future<LinkedInStatusModel> getLinkedInStatus() async {
    return await remoteDataSource.getLinkedInStatus();
  }

  @override
  Future<String?> getLinkedInAuthorizationUrl() async {
    return await remoteDataSource.getLinkedInAuthorizationUrl();
  }

  @override
  Future<LinkedInShareResult> shareOnLinkedIn({String? postMessage}) async {
    return await remoteDataSource.shareOnLinkedIn(postMessage: postMessage);
  }

  @override
  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    return await remoteDataSource.validatePromoCode(code);
  }

  @override
  Future<Map<String, dynamic>> redeemPromoCode(RedeemRequestModel request) async {
    return await remoteDataSource.redeemPromoCode(request);
  }

  @override
  Future<dynamic> getContentVideos() async {
    return await remoteDataSource.getContentVideos();
  }

  @override
  Future<dynamic> getReferralCopy() async {
    return await remoteDataSource.getReferralCopy();
  }

  @override
  Future<dynamic> getDiscountOffer() async {
    return await remoteDataSource.getDiscountOffer();
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final remote = ref.watch(referralRemoteDataSourceProvider);
  return ReferralRepositoryImpl(remoteDataSource: remote);
});
