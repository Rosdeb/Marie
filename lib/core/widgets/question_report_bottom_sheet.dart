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

class QuestionReportBottomSheet {
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

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: !isSubmitting,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final screenHeight = MediaQuery.sizeOf(context).height;
              return ConstrainedBox(
                constraints: BoxConstraints(maxHeight: screenHeight * .9),
                child: Material(
                  color: Colors.white,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
                        child: Column(
                          children: [
                            Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              //crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.report_gmailerrorred_outlined,
                                  color: Colors.black,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Report Question',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Close',
                                  onPressed: isSubmitting
                                      ? null
                                      : () => Navigator.pop(sheetContext),
                                  icon: const Icon(Icons.close_rounded),
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      Flexible(
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                                            : Colors.white,
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
                                  hintText:
                                      'Describe the issue with this question...',
                                  hintStyle: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                    ),
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
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                      ),
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
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(sheetContext),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 13,
                                ),
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
                                        final apiClient = ref.read(
                                          apiClientProvider,
                                        );
                                        final resp = await submitQuestionReport(
                                          apiClient: apiClient,
                                          questionId: questionId,
                                          message: msg,
                                          reporterEmail: emailController.text
                                              .trim(),
                                          authToken: token,
                                        );

                                        if (context.mounted) {
                                          Navigator.pop(sheetContext);
                                          FloatingSuccessBar.show(
                                            context,
                                            message:
                                                resp['message']?.toString() ??
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
                                        if (sheetContext.mounted) {
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    messageController.dispose();
    emailController.dispose();
  }
}
