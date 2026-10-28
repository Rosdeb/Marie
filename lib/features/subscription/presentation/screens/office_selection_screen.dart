import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../practice/domain/entities/office_entity.dart';
import '../../../practice/presentation/providers/offices_provider.dart';
import '../../../practice/presentation/providers/practice_provider.dart';
import '../../domain/entities/entitlement_entity.dart';
import '../providers/entitlement_provider.dart';

class OfficeSelectionScreen extends ConsumerStatefulWidget {
  const OfficeSelectionScreen({super.key});

  @override
  ConsumerState<OfficeSelectionScreen> createState() =>
      _OfficeSelectionScreenState();
}

class _OfficeSelectionScreenState extends ConsumerState<OfficeSelectionScreen> {
  String? _selectedFocusCode;
  String? _selectedNationalCode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(entitlementProvider.notifier).refresh();
      if (!mounted) return;
      final entitlement = ref.read(entitlementProvider);
      final isTrack = entitlement.planId == PlanTier.track;

      if (isTrack) {
        for (final code in entitlement.selectedOffices) {
          final upper = code.toUpperCase();
          if (!{'WIPO', 'EPO', 'EUIPO', 'UPC'}.contains(upper)) {
            _selectedNationalCode = upper;
          }
        }
      } else {
        if (entitlement.selectedOffices.isNotEmpty) {
          _selectedFocusCode = entitlement.selectedOffices.first.toUpperCase();
        }
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final entitlement = ref.watch(entitlementProvider);
    final officesState = ref.watch(officesProvider);

    final isTrack = entitlement.planId == PlanTier.track;
    final isMajorsOrGlobal =
        entitlement.planId == PlanTier.majors ||
        entitlement.planId == PlanTier.global;
    final isInitialSelection =
        entitlement.selectedOffices.isEmpty || entitlement.needsOfficeSelection;
    final canChange = isInitialSelection || entitlement.officeChangeAllowed;
    final nextDate = entitlement.nextOfficeChangeDate;
    final dateStr = nextDate != null
        ? '${nextDate.day}/${nextDate.month}/${nextDate.year}'
        : 'next billing period';

    if (isMajorsOrGlobal) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Office Access',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 56,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${entitlement.planId.displayName} Plan Active',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entitlement.planId == PlanTier.global
                      ? 'You have complete access to all 15 international, regional, and national IP offices. No manual office selection is required.'
                      : 'You have complete access to all 6 major IP offices (USPTO, EPO, JPO, CNIPA, KIPO, WIPO). No manual office selection is required.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Start Practicing',
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isSelectionValid = isTrack
        ? _selectedNationalCode != null
        : _selectedFocusCode != null;

    final buttonText = isTrack
        ? (isSelectionValid
              ? 'Continue with $_selectedNationalCode'
              : 'Select 1 National office')
        : (isSelectionValid
              ? 'Continue with $_selectedFocusCode'
              : 'Select an office to continue');

    final allOffices = officesState.offices.isNotEmpty
        ? officesState.offices
        : _standardOffices;

    final internationalOffices = allOffices
        .where((o) => o.type.toLowerCase() == 'international')
        .toList();
    final regionalOffices = allOffices
        .where((o) => o.type.toLowerCase() == 'regional')
        .toList();
    final nationalOffices = allOffices
        .where((o) => o.type.toLowerCase() == 'national')
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Choose your office',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildPlanGuidanceCard(
                      isTrack: isTrack,
                      canChange: canChange,
                      isInitialSelection: isInitialSelection,
                    ),

                    if (!canChange && !isInitialSelection) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              color: Color(0xFFDC2626),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You already used your office change for this billing cycle. Next change available on $dateStr.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF991B1B),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // International Offices
                    _buildSectionHeader(
                      isTrack
                          ? 'International Systems (Included Automatically)'
                          : 'International Systems',
                    ),
                    const SizedBox(height: 8),
                    ...internationalOffices.map(
                      (o) => _buildOfficeItem(
                        office: o,
                        isSelected: isTrack
                            ? true
                            : _selectedFocusCode == o.code,
                        isFixedIncluded: isTrack,
                        canChange: canChange,
                        onTap: isTrack
                            ? null
                            : () => setState(() => _selectedFocusCode = o.code),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Regional Offices
                    _buildSectionHeader(
                      isTrack
                          ? 'Regional Offices (Included Automatically)'
                          : 'Regional Offices',
                    ),
                    const SizedBox(height: 8),
                    ...regionalOffices.map(
                      (o) => _buildOfficeItem(
                        office: o,
                        isSelected: isTrack
                            ? true
                            : _selectedFocusCode == o.code,
                        isFixedIncluded: isTrack,
                        canChange: canChange,
                        onTap: isTrack
                            ? null
                            : () => setState(() => _selectedFocusCode = o.code),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // National Offices
                    _buildSectionHeader(
                      isTrack
                          ? 'National Office (Select 1)'
                          : 'National Offices',
                    ),
                    const SizedBox(height: 8),
                    ...nationalOffices.map(
                      (o) => _buildOfficeItem(
                        office: o,
                        isSelected: isTrack
                            ? _selectedNationalCode == o.code
                            : _selectedFocusCode == o.code,
                        isFixedIncluded: false,
                        canChange: canChange,
                        onTap: isTrack
                            ? () =>
                                  setState(() => _selectedNationalCode = o.code)
                            : () => setState(() => _selectedFocusCode = o.code),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: CustomButton(
                text: !canChange
                    ? 'Office Access Locked for this Billing Period'
                    : buttonText,
                isLoading: _isSaving,
                onPressed: isSelectionValid && canChange
                    ? () async {
                        setState(() => _isSaving = true);
                        final bool success;
                        if (isTrack) {
                          success = await ref
                              .read(entitlementProvider.notifier)
                              .chooseOffices(national: _selectedNationalCode);
                        } else {
                          success = await ref
                              .read(entitlementProvider.notifier)
                              .chooseOffices(single: _selectedFocusCode);
                        }
                        setState(() => _isSaving = false);

                        if (context.mounted) {
                          if (success) {
                            final selectedCode = isTrack
                                ? _selectedNationalCode
                                : _selectedFocusCode;
                            if (selectedCode != null) {
                              ref
                                  .read(practiceProvider.notifier)
                                  .setJurisdiction(selectedCode);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isTrack
                                      ? 'WIPO, all regional offices & $_selectedNationalCode activated!'
                                      : '$_selectedFocusCode activated for your practice!',
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                            context.pop();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not update office. Please try again.',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPlanGuidanceCard({
    required bool isTrack,
    required bool canChange,
    bool isInitialSelection = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Plan Badge & Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isTrack
                      ? const Color(0xFFEFF6FF)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isTrack
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Text(
                  isTrack ? 'Track Plan' : 'Focus Plan',
                  style: TextStyle(
                    color: isTrack
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF15803D),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isInitialSelection || canChange)
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isInitialSelection
                      ? 'Selection required'
                      : (canChange ? '1 change available' : 'Limit reached'),
                  style: TextStyle(
                    color: (isInitialSelection || canChange)
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          // Dynamic Subtitle Text
          Text(
            isTrack
                ? 'Select your primary national office. WIPO and regional systems (EPO, EUIPO, UPC) are automatically included.'
                : 'Select any 1 of the 15 IP offices. You can change your choice once per billing period without extra fees.',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 5),
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1),
          const SizedBox(height: 5),

          // Plan Guidance Section
          const Text(
            'Plan Guidance',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),

          _buildGuidanceItem(
            title: 'Focus',
            description: 'Choose any one of the 15 offices below.',
          ),
          _buildGuidanceItem(
            title: 'Track',
            description:
                'Choose one national office. WIPO, EPO, EUIPO, and UPC are included automatically.',
          ),
          _buildGuidanceItem(
            description:
                'All offices include all available disciplines and four levels. You can change your selected office once per subscription period.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuidanceItem({String? title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6.0, right: 8.0),
            child: Icon(Icons.circle, size: 5, color: Color(0xFF64748B)),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12.5,
                  height: 1.4,
                ),
                children: [
                  if (title != null) ...[
                    TextSpan(
                      text: '$title: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildOfficeItem({
    required OfficeEntity office,
    required bool isSelected,
    required bool isFixedIncluded,
    required bool canChange,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isFixedIncluded
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isFixedIncluded ? null : (canChange ? onTap : null),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isFixedIncluded
                        ? const Color(0xFFECFDF5)
                        : (isSelected
                              ? AppColors.primaryLight
                              : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    office.code,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isFixedIncluded
                          ? const Color(0xFF059669)
                          : (isSelected
                                ? AppColors.primary
                                : const Color(0xFF64748B)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        office.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        office.territory,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isFixedIncluded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Included in Track',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                  )
                else
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off,
                    color: isSelected
                        ? AppColors.primary
                        : Colors.grey.shade400,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const List<OfficeEntity> _standardOffices = [
  OfficeEntity(
    code: 'WIPO',
    name: 'WIPO',
    territory: 'International',
    type: 'international',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'EPO',
    name: 'European Patent Office',
    territory: 'Europe',
    type: 'regional',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'EUIPO',
    name: 'European Union IP Office',
    territory: 'European Union',
    type: 'regional',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'UPC',
    name: 'Unified Patent Court',
    territory: 'Europe',
    type: 'regional',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'USPTO',
    name: 'United States Patent & Trademark Office',
    territory: 'United States',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'UKIPO',
    name: 'UK Intellectual Property Office',
    territory: 'United Kingdom',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'JPO',
    name: 'Japan Patent Office',
    territory: 'Japan',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'CNIPA',
    name: 'China National IP Administration',
    territory: 'China',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'KIPO',
    name: 'Korean Intellectual Property Office',
    territory: 'South Korea',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'INDIA',
    name: 'Indian Patent Office',
    territory: 'India',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'INPI',
    name: 'National Institute of Industrial Property',
    territory: 'France',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'IPI',
    name: 'Swiss Federal Institute of IP',
    territory: 'Switzerland',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'DPMA',
    name: 'German Patent and Trade Mark Office',
    territory: 'Germany',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'IPAU',
    name: 'IP Australia',
    territory: 'Australia',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
  OfficeEntity(
    code: 'CIPO',
    name: 'Canadian Intellectual Property Office',
    territory: 'Canada',
    type: 'national',
    disciplines: [],
    sheets: 0,
    questions: 0,
    levels: [],
    hasAccess: false,
    isAvailable: true,
  ),
];
