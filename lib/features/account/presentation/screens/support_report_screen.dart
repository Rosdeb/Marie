import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_shimmer.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';
import '../../../../core/widgets/promo_video_card.dart';

class SupportReportScreen extends ConsumerStatefulWidget {
  const SupportReportScreen({super.key});

  @override
  ConsumerState<SupportReportScreen> createState() => _SupportReportScreenState();
}

class _SupportReportScreenState extends ConsumerState<SupportReportScreen> {
  final _messageController = TextEditingController();
  final _questionIdController = TextEditingController();
  bool _isSubmitting = false;

  String? _supportEmail;
  String? _supportPhone;
  bool _isLoadingSupport = true;

  @override
  void initState() {
    super.initState();
    _fetchSupportContact();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _questionIdController.dispose();
    super.dispose();
  }

  /// Hands a mailto: or tel: link to the device.
  ///
  /// A device with no mail app configured - a tablet, a stripped Android
  /// build, the web build Marie gets with each TestFlight build - returns
  /// false from launchUrl rather than throwing, and some platforms throw
  /// instead. Either way the address is then shown in a message, so the tap
  /// never ends in silence with nothing the user can do.
  Future<void> _openExternal(Uri uri, {required String whenUnavailable}) async {
    bool opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      FloatingErrorBar.show(context, message: whenUnavailable);
    }
  }

  Future<void> _fetchSupportContact() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(ApiConstants.supportContact, requiresAuth: false);
      if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        // A field left empty in the dashboard means "do not show this".
        // There is no phone number for IPro, and the server sends an empty
        // string rather than omitting the key, so blank has to be treated
        // the same as missing or the screen shows a lone phone icon.
        String? present(dynamic value) {
          final text = value?.toString().trim() ?? '';
          return text.isEmpty ? null : text;
        }

        setState(() {
          _supportEmail = present(data['email']);
          _supportPhone = present(data['phoneNumber']);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingSupport = false);
    }
  }

  Future<void> _submitReport() async {
    final message = _messageController.text.trim();
    final questionId = _questionIdController.text.trim();

    if (message.isEmpty) {
      FloatingErrorBar.show(context, message: 'Please describe the problem you encountered');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'message': message,
      };
      if (questionId.isNotEmpty) {
        body['questionId'] = questionId;
      }

      final response = await apiClient.post(
        ApiConstants.reportProblem,
        body: body,
        requiresAuth: true,
      );

      if (!mounted) return;
      if (response['success'] == true) {
        FloatingSuccessBar.show(context, message: 'Report submitted successfully. Thank you!');
        context.pop();
      } else {
        FloatingErrorBar.show(context, message: response['message']?.toString() ?? 'Failed to submit report');
      }
    } catch (e) {
      if (mounted) {
        FloatingErrorBar.show(context, message: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Card
              Container(
                padding: const EdgeInsets.all(18),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.headset_mic_outlined, color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Direct Support Contact',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_isLoadingSupport)
                      const SupportContactShimmer()
                    else ...[
                      /*
                       * The address is tapped, not copied by hand.
                       *
                       * Marie, 8 November 2026, point 1.6: "I have entered
                       * iproexperience@gmail.com in the dashboard (Settings
                       * -> Legal & Support). Please confirm in the next build
                       * that it appears in Help & Support and that tapping it
                       * opens an e-mail."
                       *
                       * It appeared, but as plain text: there was nothing to
                       * tap. Both rows now open the right app - mailto: for
                       * the address, tel: for the number - and are styled as
                       * links so it is visible that they can be.
                       */
                      if (_supportEmail != null) ...[
                        _ContactRow(
                          icon: Icons.email_outlined,
                          label: _supportEmail!,
                          onTap: () => _openExternal(
                            Uri(scheme: 'mailto', path: _supportEmail!),
                            whenUnavailable: 'No e-mail app is set up on this device. '
                                'The address is ${_supportEmail!}.',
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_supportPhone != null) ...[
                        _ContactRow(
                          icon: Icons.phone_outlined,
                          label: _supportPhone!,
                          onTap: () => _openExternal(
                            Uri(scheme: 'tel', path: _supportPhone!),
                            whenUnavailable: 'This device cannot place calls. '
                                'The number is ${_supportPhone!}.',
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /*
               * What a subscription is, and how it is cancelled.
               *
               * Marie, 8 November 2026, agreeing to one App Store
               * subscription group per plan:
               *   "However, users must understand what this means. Before
               *    they buy a second plan, and in Help & Support, the app
               *    must explain clearly that each plan is a separate
               *    subscription on the iPhone and must be cancelled
               *    separately."
               *
               * This is the Help & Support half of that. The other place is
               * the sheet shown before a second plan is bought, in
               * plans_screen.dart; "How subscriptions work" carries the same
               * sentence in shorter form.
               *
               * It is here rather than in the account screen because this is
               * where somebody looks when they cannot work out how to stop
               * being charged, and because the sentence they need - each plan
               * is cancelled separately, and in the store rather than in IPro
               * - is the one that is easy to get wrong.
               */
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.layers_outlined, color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your subscriptions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Plans add up rather than replace each other. If you hold '
                      'two plans, your access is every office of both - and each '
                      'plan is a separate subscription.',
                      style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'That means each plan is billed on its own renewal date, '
                      'appears on its own line in your App Store or Google Play '
                      'subscriptions, and must be cancelled separately. '
                      'Cancelling one leaves the others running, and you keep '
                      'the offices they cover.',
                      style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Subscriptions are managed by the store, not by IPro, so '
                      'they cannot be cancelled from inside the app:',
                      style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'iPhone or iPad:  Settings > your name > Subscriptions\n'
                      'Android:  Play Store > profile > Payments and subscriptions',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.6,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Promotional video - the fourth of the four places of
              // section 1.2. Nothing is uploaded yet, so this reads "coming
              // soon" until a video is published under the help_support
              // placement on the dashboard.
              const PromoVideoCard(
                placement: 'help_support',
                heading: 'Getting started with IPro',
                caption:
                    'A short walk-through of the app. If your question is '
                    'answered faster in writing, the form below reaches us '
                    'either way.',
              ),

              const SizedBox(height: 24),

              // Report a problem header
              const Text(
                'Report a Problem',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Found a mistake or experiencing technical issues? Let us know and our legal & engineering team will look into it.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Question ID or Section (Optional)',
                hint: 'e.g. IPI-Patents_Beginner-1',
                controller: _questionIdController,
                prefixIcon: const Icon(Icons.tag, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 14),

              CustomTextField(
                label: 'Problem Description',
                hint: 'Describe the issue or error in detail...',
                controller: _messageController,
                prefixIcon: const Icon(Icons.description_outlined, color: AppColors.textSecondary, size: 20),
              ),
              const SizedBox(height: 28),

              CustomButton(
                text: 'Submit Problem Report',
                isLoading: _isSubmitting,
                onPressed: _submitReport,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A support contact that can be tapped.
///
/// Underlined and in the accent colour, because an address that opens the
/// mail app has to look different from one that is only printed - Marie asked
/// for the tap (point 1.6), and a tap nobody knows is there is not much use.
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
