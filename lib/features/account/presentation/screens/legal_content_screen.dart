import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_shimmer.dart';

enum LegalType {
  privacyPolicy,
  legalNotice,
  eula,
}

class LegalContentScreen extends ConsumerStatefulWidget {
  final LegalType type;

  const LegalContentScreen({
    super.key,
    required this.type,
  });

  @override
  ConsumerState<LegalContentScreen> createState() => _LegalContentScreenState();
}

class _LegalContentScreenState extends ConsumerState<LegalContentScreen> {
  String? _serverContent;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      String endpoint = ApiConstants.privacyPolicy;
      if (widget.type == LegalType.legalNotice || widget.type == LegalType.eula) {
        endpoint = ApiConstants.terms;
      }
      final response = await apiClient.get(endpoint, requiresAuth: false);
      if (response is Map<String, dynamic> && response['data'] != null) {
        final data = response['data'];
        if (data is String && data.isNotEmpty) {
          _serverContent = data;
        } else if (data is Map<String, dynamic> && data['content'] != null) {
          _serverContent = data['content'].toString();
        } else if (data is List && data.isNotEmpty) {
          _serverContent = data.map((e) => e.toString()).join('\n\n');
        }
      }
    } catch (_) {
      // Fallback to static text
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _title {
    switch (widget.type) {
      case LegalType.privacyPolicy:
        return 'Privacy Policy';
      case LegalType.legalNotice:
        return 'Legal Notice';
      case LegalType.eula:
        return 'Terms & Conditions (EULA)';
    }
  }

  String get _fallbackContent {
    switch (widget.type) {
      case LegalType.privacyPolicy:
        return '''
Last updated: January 2026

1. Information We Collect
We collect information you provide directly to us when you create an account, manage your profile, and use our study features.

2. How We Use Information
We use information collected to:
• Provide, maintain, and improve our services.
• Personalize your study recommendations and practice track.
• Send study reminders and security notices (if notifications are enabled).

3. Data Security
We implement strict technical safeguards to secure your personal information against unauthorized access, alteration, or disclosure.
''';

      case LegalType.legalNotice:
        return '''
Legal Notice & Disclaimers

1. Ownership
This application and all its original content, practice questions, review modules, and trademarks are owned by Study App Inc.

2. Educational Disclaimer
All practice exams and question sets are provided for exam preparation and informational purposes only. Results do not guarantee official certification exam scores.

3. Copyright & Intellectual Property
Unauthorized reproduction, distribution, or decompilation of study content is strictly prohibited without prior written consent.
''';

      case LegalType.eula:
        return '''
End User License Agreement (EULA)

1. Grant of License
Subject to the terms of this Agreement, we grant you a revocable, non-exclusive, non-transferable, limited license to download, install, and use the Application.

2. License Restrictions
You agree not to:
• License, sell, rent, lease, or distribute the application.
• Modify, make derivative works of, disassemble, or reverse engineer any part of the service.
• Share your single-user subscription credentials with third parties.

3. Termination
This agreement is effective until terminated by you or the company. Upon account deletion, all access privileges will cease immediately.
''';
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
        title: Text(
          _title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ContentDocumentShimmer(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Text(
                    _serverContent ?? _fallbackContent,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
