import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../theme/app_colors.dart';
import 'floating_error_bar.dart';
import 'floating_success_bar.dart';

class QuestionReportDialog {
  static void show(
    BuildContext context,
    WidgetRef ref, {
    required String questionId,
  }) {
    final messageController = TextEditingController();
    final emailController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Row(
                children: [
                  Icon(Icons.flag_outlined, color: AppColors.error, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Report Question',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (questionId.isNotEmpty) ...[
                      Text(
                        'Question Ref: $questionId',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    const Text(
                      'Describe the issue with this question (e.g. incorrect key, typo, outdated legal reference):',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter details...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Your email (optional)',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final msg = messageController.text.trim();
                          if (msg.isEmpty) {
                            FloatingErrorBar.show(
                              context,
                              message: 'Please provide description of the issue',
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          try {
                            final apiClient = ref.read(apiClientProvider);
                            final token = await ref
                                .read(localStorageProvider)
                                .getAccessToken();
                            final hasToken = token != null && token.isNotEmpty;

                            final email = emailController.text.trim();
                            final body = <String, dynamic>{
                              'questionId': questionId,
                              'message': msg,
                              if (!hasToken && email.isNotEmpty)
                                'reporterEmail': email,
                            };

                            final resp = await apiClient.post(
                              ApiConstants.reportProblem,
                              body: body,
                              requiresAuth: hasToken,
                            );

                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              FloatingSuccessBar.show(
                                context,
                                message: resp['message']?.toString() ??
                                    'Report submitted successfully. Thank you!',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              FloatingErrorBar.show(
                                context,
                                message: e.toString().replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
