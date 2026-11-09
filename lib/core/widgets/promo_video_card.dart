import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/referral/presentation/widgets/referral_video_player.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';

/// The promotional video, in the four places section 1.2 of the guide asks for:
/// Welcome, Home, Share & Save and Help & Support.
///
/// There is no video yet, so what this shows today is the placeholder - the
/// same "Promotional Video Coming Soon" card Share & Save already shows. The
/// point of going through the server rather than hard-coding the card is that
/// the day a video is uploaded on the dashboard under the matching placement,
/// it appears here on its own. No release, no code change.
///
/// Nothing here can fail loudly: if the request errors, or there is no row for
/// this placement, or the row has no URL, the placeholder stays. A screen like
/// Welcome must not break because a video is missing.
class PromoVideoCard extends ConsumerWidget {
  /// The placement to read, as the dashboard files it: `welcome`, `home`,
  /// `referral_guide` or `help_support`.
  final String placement;

  /// Heading above the card. Omitted, no heading is drawn.
  final String? heading;

  /// Line under the card, for a screen that wants to say what the video is for.
  final String? caption;

  final double height;
  final EdgeInsetsGeometry padding;

  const PromoVideoCard({
    super.key,
    required this.placement,
    this.heading,
    this.caption,
    this.height = 180,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final video = ref.watch(promoVideoProvider(placement));

    // While loading, and on any failure, the placeholder is what shows. It is
    // the honest state either way: there is no video to play.
    final data = video.asData?.value;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) ...[
            Text(
              heading!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: ReferralVideoPlayer(
              videoUrl: data?.videoUrl,
              thumbnailUrl: data?.thumbnailUrl,
              title: data?.title,
              comingSoon: data?.videoUrl == null,
              height: height,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 8),
            Text(
              caption!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// What the app needs of a content video row. Deliberately small: the card
/// plays it or shows the placeholder, nothing else.
class PromoVideo {
  final String? title;
  final String? videoUrl;
  final String? thumbnailUrl;

  const PromoVideo({this.title, this.videoUrl, this.thumbnailUrl});

  static const PromoVideo none = PromoVideo();
}

String? _text(dynamic value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// The first published video of a placement, or [PromoVideo.none].
///
/// One request per placement per app run, cached by Riverpod - these screens
/// are revisited often and the answer does not change between visits.
final promoVideoProvider =
    FutureProvider.family<PromoVideo, String>((ref, placement) async {
  final client = ref.watch(apiClientProvider);

  try {
    final response = await client.get(
      ApiConstants.contentVideosFor(placement),
      requiresAuth: false,
    );

    if (response is Map<String, dynamic> && response['data'] is List) {
      final rows = response['data'] as List;
      for (final row in rows) {
        if (row is! Map) continue;
        final url = _text(row['videoUrl']);
        if (url == null) continue;
        return PromoVideo(
          title: _text(row['title']),
          videoUrl: url,
          thumbnailUrl: _text(row['thumbnailUrl']),
        );
      }
    }
  } catch (_) {
    // Swallowed on purpose - see the class comment.
  }

  return PromoVideo.none;
});
