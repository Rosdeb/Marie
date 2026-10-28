import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../theme/app_colors.dart';
import 'floating_error_bar.dart';
import 'floating_success_bar.dart';

Future<Map<String, dynamic>> submitQuestionReport({
  required ApiClient apiClient,
  required String questionId,
  required String message,
  String? reporterEmail,
  String? authToken,
}) async {
  final hasToken = authToken != null && authToken.isNotEmpty;
  final email = reporterEmail?.trim() ?? '';

  final body = <String, dynamic>{
    'questionId': questionId,
    'message': message,
    if (!hasToken && email.isNotEmpty) 'reporterEmail': email,
  };

  final response = await apiClient.post(
    ApiConstants.reportProblem,
    body: body,
    requiresAuth: hasToken,
  );

  return response is Map<String, dynamic> ? response : <String, dynamic>{};
}

class QuestionReportDialog {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required String questionId,
  }) async {
    final token = await ref.read(localStorageProvider).getAccessToken();
    final isAuthenticated = token != null && token.isNotEmpty;

    if (!context.mounted) return;

    final messageController = TextEditingController();
    final emailController = TextEditingController();
    bool isSubmitting = false;

    const quickIssues = [
      'The legal basis cites an article repealed in 2023.',
      'Two options say the same thing.',
      'The marked correct answer is wrong.',
      'Typo or formatting error in question.',
    ];

    await showDialog(
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
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isAuthenticated
                            ? AppColors.primaryLight
                            : AppColors.badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAuthenticated
                                ? Icons.verified_user_outlined
                                : Icons.account_circle_outlined,
                            size: 14,
                            color: isAuthenticated
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAuthenticated
                                ? 'Reporting as signed-in user'
                                : 'Reporting without account',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isAuthenticated
                                  ? AppColors.primaryDeep
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Quick Select Common Issue:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quickIssues.map((issue) {
                        final isSelected = messageController.text == issue;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              messageController.text = issue;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              issue,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.primaryDeep
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Details / Description:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: messageController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Describe the issue with this question...',
                        hintStyle: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    if (!isAuthenticated) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Your Email (optional):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'optional@example.com',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: AppColors.primary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
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
                              message:
                                  'Please describe the issue with this question',
                            );
                            return;
                          }

                          setState(() => isSubmitting = true);
                          try {
                            final apiClient = ref.read(apiClientProvider);
                            final resp = await submitQuestionReport(
                              apiClient: apiClient,
                              questionId: questionId,
                              message: msg,
                              reporterEmail: emailController.text.trim(),
                              authToken: token,
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
