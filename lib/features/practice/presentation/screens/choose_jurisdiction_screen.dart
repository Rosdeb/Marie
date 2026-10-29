import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../subscription/domain/entities/entitlement_entity.dart';
import '../../../subscription/presentation/providers/entitlement_provider.dart';
import '../../../subscription/presentation/widgets/plan_upsell_bottom_sheet.dart';
import '../../domain/entities/office_entity.dart';
import '../providers/offices_provider.dart';
import '../providers/practice_provider.dart';

class ChooseJurisdictionScreen extends ConsumerStatefulWidget {
  const ChooseJurisdictionScreen({super.key});

  @override
  ConsumerState<ChooseJurisdictionScreen> createState() =>
      _ChooseJurisdictionScreenState();
}

class _ChooseJurisdictionScreenState
    extends ConsumerState<ChooseJurisdictionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(entitlementProvider.notifier).refresh();
      if (mounted) {
        _applyDefaultSelection();
      }
    });
  }

  void _applyDefaultSelection() {
    final selection = ref.read(practiceProvider);
    final entitlement = ref.read(entitlementProvider);

    // Preselect user's selected office (Focus/Track) or first included office
    if (selection.jurisdiction == null ||
        !entitlement.canAccessOffice(selection.jurisdiction!)) {
      if (entitlement.selectedOffices.isNotEmpty &&
          entitlement.canAccessOffice(entitlement.selectedOffices.first)) {
        ref
            .read(practiceProvider.notifier)
            .setJurisdiction(entitlement.selectedOffices.first);
      } else if (entitlement.includedOffices.isNotEmpty) {
        ref
            .read(practiceProvider.notifier)
            .setJurisdiction(entitlement.includedOffices.first);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(practiceProvider);
    final entitlement = ref.watch(entitlementProvider);
    final officesState = ref.watch(officesProvider);

    // Fallback list of 15 standard offices if remote catalogue is still loading
    final allOffices = officesState.offices.isNotEmpty
        ? officesState.offices
        : _standardOffices;

    final internationalOffices =
        allOffices.where((o) => o.type.toLowerCase() == 'international').toList();
    final regionalOffices =
        allOffices.where((o) => o.type.toLowerCase() == 'regional').toList();
    final nationalOffices =
        allOffices.where((o) => o.type.toLowerCase() == 'national').toList();

    final isSelectedJurisdictionEntitled = selection.jurisdiction != null &&
        entitlement.canAccessOffice(selection.jurisdiction!);

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
          'Choose Office',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await Future.wait([
                  ref.read(entitlementProvider.notifier).refresh(),
                  ref.read(officesProvider.notifier).fetchOffices(),
                ]);
                if (mounted) {
                  _applyDefaultSelection();
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Discipline: ${selection.topic ?? "Patents"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (entitlement.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entitlement.planId.displayName} Plan',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 4),
                const Text(
                  'Select an IP office to practice official exam-level questions.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // 1. International Systems
                if (internationalOffices.isNotEmpty) ...[
                  _buildSectionHeader('International Systems'),
                  const SizedBox(height: 10),
                  ...internationalOffices.map((office) => _buildOfficeCard(
                        context: context,
                        office: office,
                        isSelected: selection.jurisdiction == office.code,
                        entitlement: entitlement,
                      )),
                  const SizedBox(height: 16),
                ],

                // 2. Regional Systems
                if (regionalOffices.isNotEmpty) ...[
                  _buildSectionHeader('Regional Systems'),
                  const SizedBox(height: 10),
                  ...regionalOffices.map((office) => _buildOfficeCard(
                        context: context,
                        office: office,
                        isSelected: selection.jurisdiction == office.code,
                        entitlement: entitlement,
                      )),
                  const SizedBox(height: 16),
                ],

                // 3. National Systems
                if (nationalOffices.isNotEmpty) ...[
                  _buildSectionHeader('National Offices'),
                  const SizedBox(height: 10),
                  ...nationalOffices.map((office) => _buildOfficeCard(
                        context: context,
                        office: office,
                        isSelected: selection.jurisdiction == office.code,
                        entitlement: entitlement,
                      )),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),

          // Bottom Continue Action
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                CustomButton(
                  text: isSelectedJurisdictionEntitled
                      ? 'Continue'
                      : (selection.jurisdiction != null
                          ? 'Unlock ${selection.jurisdiction}'
                          : 'Select an Office'),
                  onPressed: selection.jurisdiction != null
                      ? () {
                          final selectedCode = selection.jurisdiction!;
                          if (entitlement.canAccessOffice(selectedCode)) {
                            context.push('/practice/choose-subdiscipline');
                          } else {
                            final targetOffice = allOffices.firstWhere(
                              (o) => o.code == selectedCode,
                              orElse: () => OfficeEntity(
                                code: selectedCode,
                                name: selectedCode,
                                territory: '',
                                type: 'national',
                                disciplines: const [],
                                sheets: 0,
                                questions: 0,
                                levels: const [],
                                hasAccess: false,
                                isAvailable: true,
                              ),
                            );
                            PlanUpsellBottomSheet.show(
                              context,
                              officeCode: targetOffice.code,
                              officeName: targetOffice.name,
                              territory: targetOffice.territory,
                            );
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 12),
              ],
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
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildOfficeCard({
    required BuildContext context,
    required OfficeEntity office,
    required bool isSelected,
    required EntitlementEntity entitlement,
  }) {
    final canAccess = entitlement.canAccessOffice(office.code);
    final meta = _officeDetailsMap[office.code.toUpperCase().trim()];
    final fullName =
        meta?.fullName ?? (office.name.isNotEmpty ? office.name : office.code);
    final specialNote = meta?.specialNote;

    final List<_DisciplineInfo> displayDisciplines = [];
    if (office.disciplines.isNotEmpty) {
      for (final d in office.disciplines) {
        displayDisciplines.add(
          _DisciplineInfo(
            name: d.name,
            levels: '4 levels',
            questions: d.questions > 0 ? d.questions : null,
          ),
        );
      }
    } else if (meta != null && meta.disciplines.isNotEmpty) {
      displayDisciplines.addAll(meta.disciplines);
    } else {
      displayDisciplines.add(const _DisciplineInfo(name: 'Patents', levels: '4 levels'));
      displayDisciplines.add(const _DisciplineInfo(name: 'Trademarks', levels: '4 levels'));
      displayDisciplines.add(const _DisciplineInfo(name: 'Designs', levels: '4 levels'));
    }

    final totalSheets =
        office.sheets > 0 ? office.sheets : (meta?.defaultSheets ?? 12);
    final totalQuestions = office.questions > 0
        ? office.questions
        : (meta?.defaultQuestions ?? 2400);

    final statusText = canAccess
        ? (entitlement.planId != PlanTier.none
            ? 'Included with your ${entitlement.planId.displayName} plan'
            : 'Access granted')
        : (entitlement.isActive
            ? 'Not included with your current ${entitlement.planId.displayName} plan'
            : 'Subscription required to access');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isSelected ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref.read(practiceProvider.notifier).setJurisdiction(office.code);
            if (!canAccess) {
              PlanUpsellBottomSheet.show(
                context,
                officeCode: office.code,
                officeName: fullName,
                territory: office.territory,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code Pill + Territory Tag + Lock/Selected Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (canAccess
                                ? AppColors.primaryLight
                                : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        office.code,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : (canAccess
                                  ? AppColors.primary
                                  : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (office.territory.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
                        ),
                        child: Text(
                          office.territory,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 24,
                      )
                    else if (canAccess)
                      const Icon(
                        Icons.radio_button_unchecked_rounded,
                        color: AppColors.border,
                        size: 24,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_rounded, size: 12, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text(
                              'Locked',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Office Code Header & Full Name
                Text(
                  office.code,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),

                // Plan Access Status Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: canAccess
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: canAccess
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        canAccess
                            ? Icons.check_circle_rounded
                            : Icons.lock_outline_rounded,
                        size: 14,
                        color: canAccess
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: canAccess
                                ? const Color(0xFF059669)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Disciplines & Levels Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...displayDisciplines.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0), width: 0.8),
                                ),
                                child: Text(
                                  item.levels,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Special inclusion note (e.g. WIPO access includes PCT, Madrid, and Hague.)
                if (specialNote != null && specialNote.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          specialNote,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Footer stats: Total sheets & Total questions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total sheets: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '$totalSheets sheets',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Total questions: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              '${_formatNumber(totalQuestions)} questions',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatNumber(int n) {
    if (n <= 0) return '0';
    final s = n.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(s[i]);
    }
    return result.toString();
  }
}

class _OfficeDetails {
  final String fullName;
  final String? specialNote;
  final List<_DisciplineInfo> disciplines;
  final int defaultSheets;
  final int defaultQuestions;

  const _OfficeDetails({
    required this.fullName,
    this.specialNote,
    this.disciplines = const [],
    this.defaultSheets = 12,
    this.defaultQuestions = 2400,
  });
}

class _DisciplineInfo {
  final String name;
  final String levels;
  final int? questions;

  const _DisciplineInfo({
    required this.name,
    this.levels = '4 levels',
    this.questions,
  });
}

final Map<String, _OfficeDetails> _officeDetailsMap = {
  'WIPO': const _OfficeDetails(
    fullName: 'World Intellectual Property Organization',
    specialNote: 'WIPO access includes PCT, Madrid, and Hague.',
    disciplines: [
      _DisciplineInfo(name: 'PCT · Patents', levels: '4 levels'),
      _DisciplineInfo(name: 'Madrid · Trademarks', levels: '4 levels'),
      _DisciplineInfo(name: 'Hague · Designs', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2740,
  ),
  'EPO': const _OfficeDetails(
    fullName: 'European Patent Office',
    specialNote: 'EPC patent grant, opposition, and legal procedures.',
    disciplines: [
      _DisciplineInfo(name: 'European Patents (EPC)', levels: '4 levels'),
      _DisciplineInfo(name: 'Opposition & Appeals', levels: '4 levels'),
      _DisciplineInfo(name: 'Unitary Patent (UP)', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'EUIPO': const _OfficeDetails(
    fullName: 'European Union Intellectual Property Office',
    specialNote: 'EU-wide protection for trademarks and industrial designs.',
    disciplines: [
      _DisciplineInfo(name: 'EU Trademarks (EUTM)', levels: '4 levels'),
      _DisciplineInfo(name: 'Registered Community Designs (RCD)', levels: '4 levels'),
      _DisciplineInfo(name: 'Cancellation & Opposition', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'UPC': const _OfficeDetails(
    fullName: 'Unified Patent Court',
    specialNote: 'Unified litigation and patent revocation across participating EU states.',
    disciplines: [
      _DisciplineInfo(name: 'Unitary Patents Litigation', levels: '4 levels'),
      _DisciplineInfo(name: 'Court Proceedings & Rules', levels: '4 levels'),
      _DisciplineInfo(name: 'Revocation & Infringement', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'USPTO': const _OfficeDetails(
    fullName: 'United States Patent and Trademark Office',
    specialNote: 'Complete coverage of Title 35 (Patents), MPEP, and Lanham Act.',
    disciplines: [
      _DisciplineInfo(name: 'Utility & Plant Patents', levels: '4 levels'),
      _DisciplineInfo(name: 'Trademarks & Lanham Act', levels: '4 levels'),
      _DisciplineInfo(name: 'Design Patents', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'CNIPA': const _OfficeDetails(
    fullName: 'China National Intellectual Property Administration',
    specialNote: 'Chinese Patent Law, Trademark Law, and Copyright Administration.',
    disciplines: [
      _DisciplineInfo(name: 'Invention & Utility Model Patents', levels: '4 levels'),
      _DisciplineInfo(name: 'Trademarks', levels: '4 levels'),
      _DisciplineInfo(name: 'Designs', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'UKIPO': const _OfficeDetails(
    fullName: 'Intellectual Property Office of the United Kingdom',
    specialNote: 'UK Patents Act 1977, Trade Marks Act 1994, and Registered Designs Act 1949.',
    disciplines: [
      _DisciplineInfo(name: 'UK Patents', levels: '4 levels'),
      _DisciplineInfo(name: 'Trade Marks', levels: '4 levels'),
      _DisciplineInfo(name: 'Registered Designs', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'JPO': const _OfficeDetails(
    fullName: 'Japan Patent Office',
    specialNote: 'Japanese Patent Act, Utility Model Act, and Trademark Act.',
    disciplines: [
      _DisciplineInfo(name: 'Patents & Utility Models', levels: '4 levels'),
      _DisciplineInfo(name: 'Trademarks', levels: '4 levels'),
      _DisciplineInfo(name: 'Designs', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'KIPO': const _OfficeDetails(
    fullName: 'Korean Intellectual Property Office',
    specialNote: 'Korean Patent Act, Trademark Act, and Design Protection Act.',
    disciplines: [
      _DisciplineInfo(name: 'Patents', levels: '4 levels'),
      _DisciplineInfo(name: 'Trademarks', levels: '4 levels'),
      _DisciplineInfo(name: 'Designs', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'INDIA': const _OfficeDetails(
    fullName: 'Indian Patent Office (CGPDTM)',
    specialNote: 'The Patents Act 1970, Trade Marks Act 1999, and The Designs Act 2000.',
    disciplines: [
      _DisciplineInfo(name: 'Patents & Examination', levels: '4 levels'),
      _DisciplineInfo(name: 'Trademarks', levels: '4 levels'),
      _DisciplineInfo(name: 'Designs', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'INPI': const _OfficeDetails(
    fullName: 'National Institute of Industrial Property',
    specialNote: 'French Intellectual Property Code for Brevets, Marques, and Dessins.',
    disciplines: [
      _DisciplineInfo(name: 'Brevets (Patents)', levels: '4 levels'),
      _DisciplineInfo(name: 'Marques (Trademarks)', levels: '4 levels'),
      _DisciplineInfo(name: 'Dessins et Modèles (Designs)', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'IPI': const _OfficeDetails(
    fullName: 'Swiss Federal Institute of Intellectual Property',
    specialNote: 'Swiss federal legislation on Patents, Trade Marks, and Designs.',
    disciplines: [
      _DisciplineInfo(name: 'Patents', levels: '4 levels', questions: 800),
      _DisciplineInfo(name: 'Trademarks', levels: '4 levels', questions: 800),
      _DisciplineInfo(name: 'Designs', levels: '4 levels', questions: 800),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'DPMA': const _OfficeDetails(
    fullName: 'German Patent and Trade Mark Office',
    specialNote: 'German Patent Act (PatG), Trade Mark Act (MarkenG), and Design Act (DesignG).',
    disciplines: [
      _DisciplineInfo(name: 'Patents & Utility Models (PatG)', levels: '4 levels'),
      _DisciplineInfo(name: 'Trade Marks (MarkenG)', levels: '4 levels'),
      _DisciplineInfo(name: 'Designs (DesignG)', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'IPAU': const _OfficeDetails(
    fullName: 'IP Australia',
    specialNote: 'Australian Patents Act 1990, Trade Marks Act 1995, and Designs Act 2003.',
    disciplines: [
      _DisciplineInfo(name: 'Standard Patents', levels: '4 levels'),
      _DisciplineInfo(name: 'Trade Marks', levels: '4 levels'),
      _DisciplineInfo(name: 'Designs', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
  'CIPO': const _OfficeDetails(
    fullName: 'Canadian Intellectual Property Office',
    specialNote: 'Canadian Patent Act, Trademarks Act, and Industrial Design Act.',
    disciplines: [
      _DisciplineInfo(name: 'Patents', levels: '4 levels'),
      _DisciplineInfo(name: 'Trademarks', levels: '4 levels'),
      _DisciplineInfo(name: 'Industrial Designs', levels: '4 levels'),
    ],
    defaultSheets: 12,
    defaultQuestions: 2400,
  ),
};

// Fallback office list of 15 official IP offices when remote catalogue is loading
const List<OfficeEntity> _standardOffices = [
  OfficeEntity(
    code: 'WIPO',
    name: 'WIPO',
    territory: 'International (PCT, Madrid, Hague)',
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
