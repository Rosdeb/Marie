import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_shimmer.dart';
import '../../../../core/widgets/floating_error_bar.dart';
import '../../../../core/widgets/floating_success_bar.dart';

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

  Future<void> _fetchSupportContact() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(ApiConstants.supportContact, requiresAuth: false);
      if (response is Map<String, dynamic> && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        setState(() {
          _supportEmail = data['email']?.toString();
          _supportPhone = data['phoneNumber']?.toString();
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
                      if (_supportEmail != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _supportEmail!,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_supportPhone != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _supportPhone!,
                              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
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
