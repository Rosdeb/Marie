import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/referral_repository_impl.dart';
import 'referral_provider.dart';

/// Whether the "Share IPro & Get 10% Off" banner belongs on the home screen.
///
/// Marie, 10 November 2026, point 5:
///   "once a user has shared IPro on LinkedIn, the banner should disappear for
///    that user; people should not keep seeing it after sharing. I plan to keep
///    this offer for one or two months after launch and then remove it, so I
///    will need to be able to turn the banner off for everyone at that point,
///    ideally without a new app release."
///
/// Two separate questions, so two separate answers:
///
///  * **For everyone** - the dashboard already carries an Active switch on the
///    discount offer, and `GET /content/discount-offer` returns it. Switching
///    it off there hides the banner in every installed copy of the app at the
///    next launch, with no release. That is the second half of her point.
///  * **For one person** - `shareRewardClaimed` on the LinkedIn status says the
///    discount has been earned, so the offer has nothing left to give them.
///
/// It fails *open*: a request that does not come back leaves the banner where
/// it was. A network blip should not quietly retire Marie's offer, and showing
/// it once too often costs nothing, while hiding it wrongly costs her a share.
final referralBannerVisibleProvider = FutureProvider<bool>((ref) async {
  // The notifier already holds the status once anything has fetched it - the
  // referral screen, or a share that just finished. Reading it here is what
  // makes the banner disappear the moment a share is rewarded, without the
  // home screen having to know anything about sharing.
  if (ref.watch(referralProvider).status.shareRewardClaimed) return false;

  final repository = ref.watch(referralRepositoryProvider);

  try {
    final response = await repository.getDiscountOffer();
    final offer = _unwrap(response);
    // Absent means an older server that has no switch yet: treat as on.
    if (offer != null && offer['isActive'] == false) return false;
  } catch (_) {
    // Fail open - see the note above.
  }

  // The per-person half needs an account. A visitor who is not signed in has
  // nothing claimed yet, so the offer still stands for them.
  if (!ref.watch(authProvider).isAuthenticated) return true;

  try {
    final status = await repository.getLinkedInStatus();
    return !status.shareRewardClaimed;
  } catch (_) {
    return true;
  }
});

/// Both `{ "data": { ... } }` and a bare object are accepted, because the
/// public content endpoints are not consistent about the envelope.
Map<String, dynamic>? _unwrap(dynamic response) {
  if (response is! Map) return null;
  final data = response['data'];
  if (data is Map<String, dynamic>) return data;
  return response is Map<String, dynamic> ? response : null;
}
