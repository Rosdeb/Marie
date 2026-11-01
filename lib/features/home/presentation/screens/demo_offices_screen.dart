import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_shimmer.dart';
import '../../../practice/domain/entities/office_entity.dart';
import '../../../practice/presentation/providers/offices_provider.dart';

class DemoOfficesScreen extends ConsumerStatefulWidget {
  const DemoOfficesScreen({super.key});

  @override
  ConsumerState<DemoOfficesScreen> createState() => _DemoOfficesScreenState();
}

class _DemoOfficesScreenState extends ConsumerState<DemoOfficesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(officesProvider);
    final notifier = ref.read(officesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Demo Offices',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filter Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Search Field
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: notifier.search,
                      decoration: InputDecoration(
                        hintText: 'Search office or territory...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  notifier.search('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Territory Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterPill('All', state.selectedTerritory, notifier),
                        const SizedBox(width: 8),
                        _buildFilterPill('National', state.selectedTerritory, notifier),
                        const SizedBox(width: 8),
                        _buildFilterPill('Regional', state.selectedTerritory, notifier),
                        const SizedBox(width: 8),
                        _buildFilterPill('International', state.selectedTerritory, notifier),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Expanded(
              child: RefreshIndicator(
                onRefresh: notifier.fetchOffices,
                color: AppColors.primary,
                child: _buildBody(state, notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(
    String label,
    String currentSelected,
    OfficesNotifier notifier,
  ) {
    final isSelected = label.toLowerCase() == currentSelected.toLowerCase();
    return InkWell(
      onTap: () => notifier.selectTerritory(label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(OfficesState state, OfficesNotifier notifier) {
    if (state.isLoading && state.offices.isEmpty) {
      return const OfficeCatalogueShimmer(count: 5);
    }

    if (state.errorMessage != null && state.offices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load offices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: notifier.fetchOffices,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.filteredOffices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.business_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'No offices found',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Try adjusting your search query or territory filter.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: state.filteredOffices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final office = state.filteredOffices[index];
        return _buildOfficeCard(context, office);
      },
    );
  }

  Widget _buildOfficeCard(BuildContext context, OfficeEntity office) {
    final displayName = _formatOfficeName(office.code, office.name);
    final isAvailable = office.isAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primaryDeep,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3050).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFF10B981).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAvailable
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  isAvailable ? 'Available' : 'Coming Soon',
                  style: TextStyle(
                    color: isAvailable ? const Color(0xFF34D399) : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isAvailable
                ? '${office.territory} · 20 questions · No account required'
                : '${office.territory} · Questions importing soon',
            style: const TextStyle(fontSize: 12, color: Color(0xFFB0BEC5)),
          ),
          if (office.disciplines.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: office.disciplines.map((discipline) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    discipline.name,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable ? Colors.white : Colors.white.withValues(alpha: 0.2),
                foregroundColor: isAvailable ? const Color(0xFF1A3050) : Colors.white70,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _onSelectOffice(context, office),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAvailable ? 'Start the demo' : 'Coming Soon',
                    style: TextStyle(
                      color: isAvailable ? const Color(0xFF1A3050) : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isAvailable) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF1A3050),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSelectOffice(BuildContext context, OfficeEntity office) {
    if (!office.isAvailable) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            _formatOfficeName(office.code, office.name),
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          content: Text(
            '${_formatOfficeName(office.code, office.name)} questions are currently being imported.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
      return;
    }

    ref.read(officesProvider.notifier).selectOffice(office);
    context.push('/home/demo-config');
  }

  static String _formatOfficeName(String code, String rawName) {
    final upper = code.toUpperCase().trim();
    if (upper == 'IPAU') return 'IP Australia';
    if (upper == 'INDIA' || upper == 'IPO INDIA') return 'IPO India';
    if (upper == 'INPI') return 'INPI';
    if (upper == 'UKIPO') return 'UKIPO';
    if (upper == 'USPTO') return 'USPTO';
    if (upper == 'EPO') return 'EPO';
    if (upper == 'EUIPO') return 'EUIPO';
    if (upper == 'WIPO') return 'WIPO';
    if (upper == 'UPC') return 'UPC';
    if (upper == 'IPI') return 'IPI';
    if (upper == 'DPMA') return 'DPMA';
    if (upper == 'JPO') return 'JPO';
    if (upper == 'CNIPA') return 'CNIPA';
    if (upper == 'CIPO') return 'CIPO';
    if (upper == 'KIPO') return 'KIPO';
    if (rawName.isNotEmpty && rawName != code) {
      return rawName;
    }
    return code;
  }
}
