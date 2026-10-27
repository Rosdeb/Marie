import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_shimmer.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../../../referral/data/models/referral_models.dart';
import '../../../referral/presentation/providers/referral_provider.dart';

class SharePreviewScreen extends ConsumerStatefulWidget {
  const SharePreviewScreen({super.key});

  @override
  ConsumerState<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends ConsumerState<SharePreviewScreen> {
  late TextEditingController _messageController;
  bool _isEditing = false;
  bool _hasInitializedText = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _syncInitialText(SharePreviewModel preview) {
    if (!_hasInitializedText && preview.shareText.isNotEmpty) {
      _messageController.text = '${preview.shareText}\n${preview.referralUrl}';
      _hasInitializedText = true;
    }
  }

  Future<void> _handleShare(SharePreviewModel preview, LinkedInStatusModel status) async {
    final textToShare = _messageController.text.trim();
    await Clipboard.setData(ClipboardData(text: textToShare));

    final result = await ref
        .read(referralProvider.notifier)
        .shareOnLinkedIn(message: textToShare);

    if (!mounted) return;

    if (result.success) {
      FloatingSuccessBar.show(
        context,
        message: 'Published to LinkedIn! 10% discount claimed.',
      );
      _showRewardClaimedDialog();
      return;
    }

    if (result.requiresAuth || !status.connected) {
      _showConnectOrShareDialog(result.authorizationUrl, preview.referralUrl);
    } else {
      FloatingErrorBar.show(context, message: result.message);
    }
  }

  void _showConnectOrShareDialog(String? authUrl, String referralUrl) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.share_outlined, color: Color(0xFF0077B5), size: 24),
              SizedBox(width: 10),
              Text(
                'Share on LinkedIn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your referral post message and link have been copied to your clipboard!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Connect your LinkedIn to publish automatically, or open LinkedIn directly to paste and share:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0077B5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                if (authUrl != null && authUrl.isNotEmpty) {
                  final uri = Uri.parse(authUrl);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  // Direct LinkedIn share URL
                  final shareUrl = Uri.parse(
                    'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(referralUrl)}',
                  );
                  await launchUrl(shareUrl, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text(
                'Open LinkedIn',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRewardClaimedDialog() {
    final state = ref.read(referralProvider);
    final promoCode = state.activePromoCode ?? state.status.promoCode ?? state.sharePreview.referralCode;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFFFFCC00), size: 28),
              SizedBox(width: 8),
              Text(
                '10% Discount Unlocked!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thank you for sharing IPro with your network! Here is your exclusive 10% discount promo code:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      promoCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.primaryDeep,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: promoCode));
                        FloatingSuccessBar.show(context, message: 'Promo code copied!');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final refState = ref.watch(referralProvider);
    final preview = refState.sharePreview;
    final status = refState.status;

    _syncInitialText(preview);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Share Preview',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: refState.isLoading && !_hasInitializedText
            ? const SharePreviewShimmer()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Connection Status Bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: status.connected
                                    ? AppColors.successLight
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: status.connected
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    status.connected
                                        ? Icons.check_circle_rounded
                                        : Icons.link_rounded,
                                    size: 18,
                                    color: status.connected
                                        ? AppColors.success
                                        : const Color(0xFF0077B5),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      status.connected
                                          ? 'LinkedIn connected • Ready to auto-share'
                                          : 'Connect LinkedIn to automatically share',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: status.connected
                                            ? AppColors.success
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (!status.connected)
                                    TextButton(
                                      onPressed: () {
                                        ref
                                            .read(referralProvider.notifier)
                                            .launchLinkedInAuthorization();
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Connect',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0077B5),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Card Preview Unit
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.network(
                                        preview.previewImageUrl ??
                                            'https://iter-bene.s3.eu-north-1.amazonaws.com/15206766-215b-415e-8016-dd1bd32c4ad6.png',
                                        height: 180,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          height: 180,
                                          width: double.infinity,
                                          color: AppColors.primaryDeep,
                                          child: const Center(
                                            child: Icon(
                                              Icons.share_rounded,
                                              size: 48,
                                              color: Colors.white54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Link Info Container
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          preview.previewDomain,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          preview.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          preview.description,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // LinkedIn Post Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'LinkedIn Post Message',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isEditing = !_isEditing;
                                    });
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isEditing
                                            ? Icons.check_rounded
                                            : Icons.edit_outlined,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isEditing ? 'Done' : 'Edit',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Editable Text Container
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _isEditing
                                  ? TextField(
                                      controller: _messageController,
                                      maxLines: null,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    )
                                  : Text(
                                      _messageController.text.isNotEmpty
                                          ? _messageController.text
                                          : '${preview.shareText}\n${preview.referralUrl}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // Bottom Actions
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0077B5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: refState.isSharing
                            ? null
                            : () => _handleShare(preview, status),
                        icon: refState.isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share, color: Colors.white, size: 18),
                        label: Text(
                          refState.isSharing
                              ? 'Sharing...'
                              : (status.connected
                                  ? 'Share on LinkedIn'
                                  : preview.bannerDescription.isNotEmpty
                                      ? 'Continue to Share'
                                      : 'Share on LinkedIn'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/home/how-it-works');
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text(
                            'How it works',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
      ),
    );
  }
}

class SharePreviewShimmer extends StatelessWidget {
  const SharePreviewShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          CustomShimmer(
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          CustomShimmer(
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
