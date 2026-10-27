import 'package:flutter_test/flutter_test.dart';
import 'package:marie_nirva/features/referral/data/models/referral_models.dart';

void main() {
  group('Referral & LinkedIn Models Tests', () {
    test('SharePreviewModel.fromJson parses complete API payload', () {
      final json = {
        "referralUrl": "https://ipro.legal/referral/join-now?ref=5A0C89",
        "shareText":
            "I've been using IPro to streamline my IP law practice — it's been a game changer!",
        "title": "Join IPro — Smart IP Law Practice",
        "description":
            "Streamline your intellectual property practice with draft automation.",
        "previewDomain": "ipro.legal/referral/join-now",
        "previewImageUrl":
            "https://iter-bene.s3.eu-north-1.amazonaws.com/test.png",
        "referralCode": "5A0C89",
        "linkedinConnected": false,
        "discountPercentage": 10,
        "validityDays": 30,
        "banner": {
          "tag": "LINKEDIN EXCLUSIVE",
          "discountTag": "10% OFF",
          "title": "Share IPro & Get 10% Off Your Plan",
          "description": "Invite your LinkedIn network.",
          "buttonText": "Share on LinkedIn"
        },
        "actions": {
          "connectEndpoint": "/api/v1/referral/linkedin/connect",
          "publishEndpoint": "/api/v1/referral/linkedin/share",
          "publishButtonText": "Continue to Share"
        }
      };

      final preview = SharePreviewModel.fromJson(json);

      expect(preview.referralCode, '5A0C89');
      expect(preview.referralUrl,
          'https://ipro.legal/referral/join-now?ref=5A0C89');
      expect(preview.title, 'Join IPro — Smart IP Law Practice');
      expect(preview.discountPercentage, 10);
      expect(preview.validityDays, 30);
      expect(preview.bannerTag, 'LINKEDIN EXCLUSIVE');
      expect(preview.buttonText, 'Share on LinkedIn');
      expect(preview.publishEndpoint, '/api/v1/referral/linkedin/share');
      expect(preview.linkedinConnected, isFalse);
    });

    test('LinkedInStatusModel.fromJson parses connected and promoCode', () {
      final json = {
        "connected": true,
        "memberUrn": "urn:li:person:12345",
        "shareRewardClaimed": true,
        "promoCode": "IPRO-LI-9X2A"
      };

      final status = LinkedInStatusModel.fromJson(json);

      expect(status.connected, isTrue);
      expect(status.memberUrn, 'urn:li:person:12345');
      expect(status.shareRewardClaimed, isTrue);
      expect(status.promoCode, 'IPRO-LI-9X2A');
    });

    test('LinkedInShareResult.fromJson parses auth required status', () {
      final json = {
        "success": false,
        "statusCode": 200,
        "message": "Please connect your LinkedIn account to publish.",
        "data": {
          "requiresAuth": true,
          "authorizationUrl":
              "https://www.linkedin.com/oauth/v2/authorization?client_id=123",
          "message": "Please connect your LinkedIn account to publish."
        }
      };

      final result = LinkedInShareResult.fromJson(json);

      expect(result.success, isFalse);
      expect(result.requiresAuth, isTrue);
      expect(result.authorizationUrl, contains('oauth/v2/authorization'));
    });
  });
}
