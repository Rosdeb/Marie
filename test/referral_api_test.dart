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

    test('SharePreviewModel.fromJson parses new API nested schema', () {
      final json = {
        "sharingAvailable": false,
        "unavailableReason":
            "Sharing unavailable: promotional video pending.",
        "referral": {
          "code": "ID-10023",
          "url": "https://ipro.legal/referral/join-now?ref=ID-10023"
        },
        "reward": {
          "discountPercentage": 10,
          "validityDays": 30,
          "oneTimePerUser": true,
          "appliesTo": "standard IPro plans"
        },
        "video": {
          "comingSoon": true,
          "title": null,
          "videoUrl": null,
          "thumbnailUrl": null,
          "captionsUrl": null
        },
        "sharePreview": {
          "screenTitle": "Share Preview",
          "shareHint":
              "Share the video on LinkedIn to earn 10% off. You'll get your code immediately after sharing.",
          "postMessageLabel": "LinkedIn Post Message",
          "postMessage":
              "Discover iPro — streamlined IP law practice! Use code: ID-10023. https://ipro.legal/referral/join-now?ref=ID-10023",
          "postMessageTemplate":
              "Discover iPro … {referral_code}. {referral_link}",
          "editable": true,
          "maxLength": 3000,
          "primaryButtonText": "Continue to Share",
          "secondaryButtonText": "How It Works",
          "footerNote": "Sharing unavailable: promotional video pending."
        },
        "howItWorks": {
          "screenTitle": "How it works",
          "title": "Share on LinkedIn. Get 10% off.",
          "steps": [
            {
              "step": 1,
              "title": "Review your post",
              "body":
                  "We have prepared a message with a short video explaining IPro and your personal link."
            },
            {
              "step": 2,
              "title": "Share on LinkedIn",
              "body":
                  "Tap Continue to Share, sign in to LinkedIn if prompted, and publish the post to your network."
            },
            {
              "step": 3,
              "title": "Get 10% off in the app",
              "body":
                  "Once posted, return to this app to receive your promo code."
            }
          ],
          "availabilityTitle": "Sharing is not available yet",
          "availabilityNote":
              "The video and website are still pending. We'll enable sharing as soon as they're ready."
        },
        "linkedinConnected": false,
        "shareRewardClaimed": false,
        "promoCode": null,
        "actions": {
          "connectEndpoint": "/api/v1/referral/linkedin/connect",
          "publishEndpoint": "/api/v1/referral/linkedin/share",
          "statusEndpoint": "/api/v1/referral/linkedin/status"
        }
      };

      final preview = SharePreviewModel.fromJson(json);

      expect(preview.sharingAvailable, isFalse);
      expect(preview.unavailableReason, contains('promotional video pending'));
      expect(preview.referral.code, 'ID-10023');
      expect(preview.referralCode, 'ID-10023');
      expect(preview.referralUrl,
          'https://ipro.legal/referral/join-now?ref=ID-10023');
      expect(preview.reward.discountPercentage, 10);
      expect(preview.reward.validityDays, 30);
      expect(preview.video.comingSoon, isTrue);
      expect(preview.sharePreview.primaryButtonText, 'Continue to Share');
      expect(preview.sharePreview.secondaryButtonText, 'How It Works');
      expect(preview.sharePreview.footerNote,
          'Sharing unavailable: promotional video pending.');
      expect(preview.howItWorks.steps.length, 3);
      expect(preview.howItWorks.steps[0].title, 'Review your post');
      expect(preview.howItWorks.availabilityTitle,
          'Sharing is not available yet');
      expect(preview.connectEndpoint, '/api/v1/referral/linkedin/connect');
      expect(preview.publishEndpoint, '/api/v1/referral/linkedin/share');
      expect(preview.statusEndpoint, '/api/v1/referral/linkedin/status');
    });
  });
}
