import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';

/// The three published legal documents, as addresses rather than text.
///
/// Marie, 31 October 2026:
///   "I would prefer the app to simply open my Google Site pages, using the
///    three links already in App Settings, and the copies to be removed. That
///    way there is only one version to update, and no risk of the app showing
///    an outdated text."
///
/// That is the whole design of this file. The app holds no copy of any legal
/// text: it asks the server for the three addresses she maintains and opens
/// them. A link she changes in the dashboard takes effect on every phone
/// immediately, with no release and nothing to remember.
///
/// A missing link is an empty string, never a guess. Guessing an address for
/// a legal document is worse than showing nothing: it would send the reader
/// to a page nobody published.
@immutable
class LegalLinks {
  final String privacyPolicyUrl;
  final String termsOfUseUrl;
  final String legalNoticeUrl;

  const LegalLinks({
    this.privacyPolicyUrl = '',
    this.termsOfUseUrl = '',
    this.legalNoticeUrl = '',
  });

  factory LegalLinks.fromJson(Map<String, dynamic> json) {
    String read(String key) {
      final value = json[key];
      return value is String ? value.trim() : '';
    }

    return LegalLinks(
      privacyPolicyUrl: read('privacyPolicyUrl'),
      // The dashboard field is named after the Terms of Service; the document
      // itself is the Terms of Use. Same text, and the name on screen follows
      // the document.
      termsOfUseUrl: read('termsOfServiceUrl'),
      legalNoticeUrl: read('legalNoticeUrl'),
    );
  }
}

/// Reads the links once per app run.
///
/// `requiresAuth: false` matters: the Privacy Policy and the Terms of Use have
/// to be reachable from the sign-up screen, before there is an account.
final legalLinksProvider = FutureProvider<LegalLinks>((ref) async {
  final response = await ref
      .read(apiClientProvider)
      .get(ApiConstants.publicAppSettings, requiresAuth: false);

  if (response is Map<String, dynamic>) {
    final data = response['data'];
    if (data is Map<String, dynamic>) return LegalLinks.fromJson(data);
  }

  return const LegalLinks();
});

/// Opens a published document.
///
/// `inAppBrowserView` keeps the reader inside IPro: the page slides up over
/// the app with a close button, rather than handing them to Chrome or Safari
/// and leaving the app behind. The address bar stays visible, which for a
/// legal text is a feature - the reader can see it is the published document
/// on Marie's own site and not something the app wrote.
///
/// Returns false when there is nothing to open or the page could not be
/// reached, so the caller can say so instead of appearing to do nothing.
Future<bool> openLegalDocument(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (opened) return true;

    // Some devices have no in-app browser component. Rather than fail on a
    // legal document, fall back to whatever browser they do have.
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
