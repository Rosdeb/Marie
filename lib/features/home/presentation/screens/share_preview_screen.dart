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
import '../../../referral/presentation/widgets/referral_video_player.dart';

class SharePreviewScreen extends ConsumerStatefulWidget {
  const SharePreviewScreen({super.key});

  @override
  ConsumerState<SharePreviewScreen> createState() =>
      _SharePreviewScreenState();
}

class _SharePreviewScreenState extends ConsumerState<SharePreviewScreen>
    with WidgetsBindingObserver {
  late TextEditingController _messageController;
  bool _isEditing = false;
  bool _hasInitializedText = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check LinkedIn connection status when returning from external browser
      ref.read(referralProvider.notifier).fetchData();
    }
  }

  void _syncInitialText(SharePreviewModel preview) {
    if (!_hasInitializedText &&
        preview.sharePreview.postMessage.isNotEmpty) {
      _messageController.text = preview.sharePreview.postMessage;
      _hasInitializedText = true;
    }
  }

  Future<void> _handlePrimaryAction(
    SharePreviewModel preview,
    LinkedInStatusModel status,
  ) async {
    // 1. If not connected yet -> Step 4: POST /referral/linkedin/connect -> OAuth
    if (!status.connected) {
      final success = await ref
          .read(referralProvider.notifier)
          .launchLinkedInAuthorization();
      if (!success && mounted) {
        final err = ref.read(referralProvider).errorMessage;
        if (err != null && err.isNotEmpty) {
          FloatingErrorBar.show(context, message: err);
        }
      }
      return;
    }

    // 2. Already connected -> Step 5: POST /referral/linkedin/share { postMessage }
    final textToShare = _messageController.text.trim();
    final result = await ref
        .read(referralProvider.notifier)
        .shareOnLinkedIn(postMessage: textToShare);

    if (!mounted) return;

    if (result.success) {
      FloatingSuccessBar.show(
        context,
        message: 'Published to LinkedIn! 10% discount claimed.',
      );
      _showRewardClaimedDialog(result.promoCode ?? status.promoCode ?? preview.promoCode);
      return;
    }

    if (result.requiresAuth) {
      // Server reported connection expired or required
      if (result.authorizationUrl != null &&
          result.authorizationUrl!.isNotEmpty) {
        final uri = Uri.parse(result.authorizationUrl!);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await ref
            .read(referralProvider.notifier)
            .launchLinkedInAuthorization();
      }
    } else {
      FloatingErrorBar.show(
        context,
        message: result.message.isNotEmpty
            ? result.message
            : 'Failed to publish post to LinkedIn.',
      );
    }
  }

  void _showRewardClaimedDialog(String? code) {
    final promoCode = code ?? 'IPRO-10-OFF';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thank you for sharing IPro on LinkedIn! Here is your exclusive 10% discount promo code for checkout:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: promoCode));
                        FloatingSuccessBar.show(
                          context,
                          message: 'Promo code copied to clipboard!',
                        );
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
              child: const Text(
                'Awesome!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
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

    final isConnected = status.connected || preview.linkedinConnected;
    final hasClaimedReward =
        status.shareRewardClaimed || preview.shareRewardClaimed;
    final activeCode =
        refState.activePromoCode ?? status.promoCode ?? preview.promoCode;

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
        title: Text(
          preview.sharePreview.screenTitle.isNotEmpty
              ? preview.sharePreview.screenTitle
              : 'Share Preview',
          style: const TextStyle(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Reward Already Claimed Banner (if claimed)
                            if (hasClaimedReward && activeCode != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.successLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.success
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      size: 20,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Reward Unlocked: $activeCode',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: activeCode),
                                        );
                                        FloatingSuccessBar.show(
                                          context,
                                          message:
                                              'Promo code copied to clipboard!',
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // 2. Connection Status Bar
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: isConnected
                                      ? AppColors.successLight
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isConnected
                                        ? AppColors.success
                                            .withValues(alpha: 0.3)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isConnected
                                          ? Icons.check_circle_rounded
                                          : Icons.link_rounded,
                                      size: 18,
                                      color: isConnected
                                          ? AppColors.success
                                          : const Color(0xFF0077B5),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isConnected
                                            ? 'LinkedIn connected • Ready to auto-share'
                                            : 'Connect LinkedIn to publish your post',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isConnected
                                              ? AppColors.success
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!isConnected)
                                      TextButton(
                                        onPressed: refState.isConnecting
                                            ? null
                                            : () {
                                                ref
                                                    .read(referralProvider
                                                        .notifier)
                                                    .launchLinkedInAuthorization();
                                              },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize
                                              .shrinkWrap,
                                        ),
                                        child: Text(
                                          refState.isConnecting
                                              ? 'Opening...'
                                              : 'Connect',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0077B5),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],

                            // 3. Video Player / Coming Soon Card
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
                                  ReferralVideoPlayer(
                                    videoUrl: preview.video.videoUrl,
                                    thumbnailUrl: preview.video.thumbnailUrl,
                                    title: preview.video.title ?? preview.title,
                                    comingSoon: preview.video.comingSoon,
                                    height: 190,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                  ),

                                  // Hint under video
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          preview.video.title ?? preview.title,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          preview.sharePreview.shareHint,
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

                            // 4. LinkedIn Post Message Header with Edit Toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  preview.sharePreview.postMessageLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (preview.sharePreview.editable)
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

                            // 5. Post Box (App-side editing only)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: _isEditing
                                    ? Border.all(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      )
                                    : null,
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
                                      maxLength:
                                          preview.sharePreview.maxLength,
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
                                          : preview.sharePreview.postMessage,
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

                    // 6. Primary Button (Continue to Share / Share on LinkedIn)
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
                        onPressed: (refState.isSharing || refState.isConnecting)
                            ? null
                            : () => _handlePrimaryAction(preview, status),
                        icon: (refState.isSharing || refState.isConnecting)
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.share,
                                color: Colors.white,
                                size: 18,
                              ),
                        label: Text(
                          refState.isSharing
                              ? 'Publishing...'
                              : refState.isConnecting
                                  ? 'Connecting...'
                                  : (isConnected
                                      ? 'Share on LinkedIn'
                                      : preview.sharePreview.primaryButtonText),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // 7. Footer Note / Unavailable text
                    if (preview.sharePreview.footerNote != null &&
                        preview.sharePreview.footerNote!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: Text(
                            preview.sharePreview.footerNote!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // 8. Secondary Button (How It Works)
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/home/how-it-works');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            preview.sharePreview.secondaryButtonText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
