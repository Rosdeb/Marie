import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';
import '../storage/local_storage.dart';
import '../theme/app_colors.dart';

Future<Map<String, dynamic>> submitQuestionReport({
  required ApiClient apiClient,
  required String questionId,
  required String message,
  String? office,
  String? sheet,
  String? caseNo,
  String? userAnswer,
  String? reporterEmail,
  String? authToken,
}) async {
  final hasToken = authToken != null && authToken.isNotEmpty;
  final email = reporterEmail?.trim() ?? '';

  final body = <String, dynamic>{
    if (questionId.isNotEmpty) 'questionId': questionId,
    'message': message,
    'comment': message,
    if (office != null && office.isNotEmpty) 'office': office,
    if (sheet != null && sheet.isNotEmpty) ...{
      'sheet': sheet,
      'discipline': sheet,
    },
    if (caseNo != null && caseNo.isNotEmpty) ...{
      'caseNo': caseNo,
      'Case_No': caseNo,
    },
    if (userAnswer != null && userAnswer.isNotEmpty) ...{
      'userAnswer': userAnswer,
      'user_answer': userAnswer,
    },
    if (!hasToken && email.isNotEmpty) ...{
      'reporterEmail': email,
    },
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
    String? office,
    String? sheet,
    String? caseNo,
    String? userAnswer,
  }) async {
    final token = await ref.read(localStorageProvider).getAccessToken();
    final isAuthenticated = token != null && token.isNotEmpty;

    if (!context.mounted) return;

    final successMessage = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestionReportModalContent(
        questionId: questionId,
        office: office,
        sheet: sheet,
        caseNo: caseNo,
        userAnswer: userAnswer,
        isAuthenticated: isAuthenticated,
        token: token,
      ),
    );

    if (!context.mounted) return;
    if (successMessage != null && successMessage.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  successMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

class QuestionReportModalContent extends ConsumerStatefulWidget {
  final String questionId;
  final String? office;
  final String? sheet;
  final String? caseNo;
  final String? userAnswer;
  final bool isAuthenticated;
  final String? token;

  const QuestionReportModalContent({
    super.key,
    required this.questionId,
    this.office,
    this.sheet,
    this.caseNo,
    this.userAnswer,
    required this.isAuthenticated,
    this.token,
  });

  @override
  ConsumerState<QuestionReportModalContent> createState() =>
      _QuestionReportModalContentState();
}

class _QuestionReportModalContentState
    extends ConsumerState<QuestionReportModalContent> {
  late final TextEditingController _messageController;
  late final TextEditingController _emailController;
  bool _isSubmitting = false;
  String? _inlineError;

  static const List<String> _quickIssues = [
    'The marked correct answer is wrong.',
    'The legal basis or explanation is incorrect or outdated.',
    'Two options say the same thing.',
    'Typo or formatting error in question.',
    'Question is unclear or misleading.',
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) {
      setState(() {
        _inlineError = 'Please describe the issue with this question';
      });
      return;
    }

    final email = _emailController.text.trim();
    if (!widget.isAuthenticated && email.isNotEmpty) {
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(email)) {
        setState(() {
          _inlineError = 'Please enter a valid email address or leave it blank';
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final resp = await submitQuestionReport(
        apiClient: apiClient,
        questionId: widget.questionId,
        message: msg,
        office: widget.office,
        sheet: widget.sheet,
        caseNo: widget.caseNo,
        userAnswer: widget.userAnswer,
        reporterEmail: email,
        authToken: widget.token,
      );

      if (mounted) {
        final successMsg = resp['message']?.toString() ??
            'Report submitted successfully. Thank you!';
        Navigator.of(context).pop(successMsg);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _inlineError = e.toString()
              .replaceFirst('ApiException: ', '')
              .replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
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
              // Sheet Header
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
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.questionId.isNotEmpty) ...[
                        Text(
                          'Question Ref: ${widget.questionId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Auth status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isAuthenticated
                              ? AppColors.primaryLight
                              : AppColors.badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isAuthenticated
                                  ? Icons.verified_user_outlined
                                  : Icons.account_circle_outlined,
                              size: 14,
                              color: widget.isAuthenticated
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.isAuthenticated
                                  ? 'Reporting as signed-in user'
                                  : 'Reporting without account',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.isAuthenticated
                                  ? AppColors.primaryDeep
                                  : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Quick Issue Options
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
                        children: _quickIssues.map((issue) {
                          final isSelected = _messageController.text == issue;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _messageController.text = issue;
                                _inlineError = null;
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

                      // Message / Description Field
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
                        controller: _messageController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13),
                        onChanged: (_) {
                          if (_inlineError != null) {
                            setState(() => _inlineError = null);
                          }
                        },
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

                      // Email Field (optional for guest)
                      if (!widget.isAuthenticated) ...[
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
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 13),
                          onChanged: (_) {
                            if (_inlineError != null) {
                              setState(() => _inlineError = null);
                            }
                          },
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

              // Inline Error Notice
              if (_inlineError != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _inlineError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action Buttons
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
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
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
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
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
      ),
    );
  }
}
