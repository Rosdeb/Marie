import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/referral_models.dart';

abstract class ReferralRemoteDataSource {
  Future<SharePreviewModel> getSharePreview();
  Future<LinkedInStatusModel> getLinkedInStatus();
  Future<String?> getLinkedInAuthorizationUrl();
  Future<LinkedInShareResult> shareOnLinkedIn({String? message});
  Future<Map<String, dynamic>> claimDiscount();
  Future<Map<String, dynamic>> validatePromoCode(String code);
}

class ReferralRemoteDataSourceImpl implements ReferralRemoteDataSource {
  final ApiClient apiClient;

  ReferralRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<SharePreviewModel> getSharePreview() async {
    final response = await apiClient.get(
      ApiConstants.sharePreview,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return SharePreviewModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    return const SharePreviewModel();
  }

  @override
  Future<LinkedInStatusModel> getLinkedInStatus() async {
    final response = await apiClient.get(
      ApiConstants.linkedinStatus,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return LinkedInStatusModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
    return const LinkedInStatusModel();
  }

  @override
  Future<String?> getLinkedInAuthorizationUrl() async {
    final response = await apiClient.post(
      ApiConstants.linkedinConnect,
      body: {},
      requiresAuth: true,
    );

    if (response is Map<String, dynamic> &&
        response['data'] is Map<String, dynamic>) {
      return response['data']['authorizationUrl'] as String?;
    }
    return null;
  }

  @override
  Future<LinkedInShareResult> shareOnLinkedIn({String? message}) async {
    final body = <String, dynamic>{
      if (message != null && message.isNotEmpty) 'comment': message,
    };

    final response = await apiClient.post(
      ApiConstants.linkedinShare,
      body: body,
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return LinkedInShareResult.fromJson(response);
    }
    return const LinkedInShareResult(
      success: false,
      message: 'Failed to share to LinkedIn',
    );
  }

  @override
  Future<Map<String, dynamic>> claimDiscount() async {
    final response = await apiClient.post(
      ApiConstants.claimDiscount,
      body: {},
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> validatePromoCode(String code) async {
    final response = await apiClient.post(
      ApiConstants.validatePromoCode,
      body: {'code': code},
      requiresAuth: true,
    );

    if (response is Map<String, dynamic>) {
      return response;
    }
    return {};
  }
}

final referralRemoteDataSourceProvider =
    Provider<ReferralRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReferralRemoteDataSourceImpl(apiClient: apiClient);
});
