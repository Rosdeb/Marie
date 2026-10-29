import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_shimmer.dart';

/// The three legal documents, each on its own screen.
///
/// They are three distinct texts with three distinct endpoints. None of them
/// substitutes for another, and the app never carries a copy of its own: a
/// legal text that disagrees with the published one is worse than no text at
/// all, so when the server has nothing this screen says so.
enum LegalType {
  privacyPolicy,
  termsOfUse,
  legalNotice,
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
  String? _content;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  String get _endpoint {
    switch (widget.type) {
      case LegalType.privacyPolicy:
        return ApiConstants.privacyPolicy;
      case LegalType.termsOfUse:
        return ApiConstants.terms;
      case LegalType.legalNotice:
        return ApiConstants.legalNotice;
    }
  }

  String get _title {
    switch (widget.type) {
      case LegalType.privacyPolicy:
        return 'Privacy Policy';
      case LegalType.termsOfUse:
        return 'Terms of Use';
      case LegalType.legalNotice:
        return 'Legal Notice';
    }
  }

  /// The endpoint answers either a single document or a list holding one.
  static String? _readContent(dynamic data) {
    if (data is Map<String, dynamic>) {
      final content = data['content'];
      return content is String && content.trim().isNotEmpty ? content : null;
    }
    if (data is List && data.isNotEmpty) {
      return _readContent(data.first);
    }
    return null;
  }

  Future<void> _fetchContent() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(_endpoint, requiresAuth: false);
      if (response is Map<String, dynamic>) {
        _content = _readContent(response['data']);
      }
    } catch (_) {
      // Leave _content null: the screen then says the document is unavailable
      // rather than showing something nobody approved.
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios,
              size: 18, color: AppColors.textPrimary),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Container(
                  width: double.infinity,
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
                  child: _content == null
                      ? _unavailable()
                      : _LegalDocument(html: _content!),
                ),
              ),
      ),
    );
  }

  Widget _unavailable() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(Icons.description_outlined,
                size: 36, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              'The $_title is not available right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
}

/// Renders the stored document.
///
/// The documents are simple HTML - headings, paragraphs and lists - so they
/// are laid out directly rather than through an HTML package. Anything the
/// parser does not recognise still comes through as readable text, which
/// matters more here than exact formatting.
class _LegalDocument extends StatelessWidget {
  final String html;

  const _LegalDocument({required this.html});

  static final RegExp _block = RegExp(
    r'<(h1|h2|h3|p|li)[^>]*>(.*?)</\1>',
    caseSensitive: false,
    dotAll: true,
  );

  static const Map<String, String> _entities = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&mdash;': '—',
    '&ndash;': '–',
    '&eacute;': 'é',
    '&egrave;': 'è',
    '&agrave;': 'à',
    '&acirc;': 'â',
    '&ccedil;': 'ç',
  };

  static String _plain(String value) {
    var text = value.replaceAll(RegExp(r'<[^>]*>'), '');
    _entities.forEach((entity, char) {
      text = text.replaceAll(entity, char);
    });
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _block.allMatches(html).toList();

    // No recognisable markup: show the text as it stands rather than nothing.
    if (matches.isEmpty) {
      return Text(
        _plain(html),
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.6,
        ),
      );
    }

    final children = <Widget>[];

    for (final match in matches) {
      final tag = match.group(1)!.toLowerCase();
      final text = _plain(match.group(2) ?? '');
      if (text.isEmpty) continue;

      if (children.isNotEmpty) {
        children.add(SizedBox(height: tag == 'li' ? 6 : 14));
      }

      switch (tag) {
        case 'h1':
          children.add(Text(
            text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ));
          break;
        case 'h2':
          children.add(Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ));
          break;
        case 'h3':
          children.add(Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ));
          break;
        case 'li':
          children.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle, size: 5, color: AppColors.textSecondary),
              ),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ));
          break;
        default:
          children.add(Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
