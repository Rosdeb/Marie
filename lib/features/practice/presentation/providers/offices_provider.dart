import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/office_entity.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../data/repositories/practice_repository_impl.dart';

class OfficesState {
  final bool isLoading;
  final List<OfficeEntity> offices;
  final List<OfficeEntity> filteredOffices;
  final String selectedTerritory;
  final String searchQuery;
  final OfficeEntity? selectedOffice;
  final String? errorMessage;
  final bool isStartingSession;

  const OfficesState({
    this.isLoading = false,
    this.offices = const [],
    this.filteredOffices = const [],
    this.selectedTerritory = 'All',
    this.searchQuery = '',
    this.selectedOffice,
    this.errorMessage,
    this.isStartingSession = false,
  });

  OfficesState copyWith({
    bool? isLoading,
    List<OfficeEntity>? offices,
    List<OfficeEntity>? filteredOffices,
    String? selectedTerritory,
    String? searchQuery,
    OfficeEntity? selectedOffice,
    String? errorMessage,
    bool? isStartingSession,
    bool clearError = false,
  }) {
    return OfficesState(
      isLoading: isLoading ?? this.isLoading,
      offices: offices ?? this.offices,
      filteredOffices: filteredOffices ?? this.filteredOffices,
      selectedTerritory: selectedTerritory ?? this.selectedTerritory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedOffice: selectedOffice ?? this.selectedOffice,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isStartingSession: isStartingSession ?? this.isStartingSession,
    );
  }
}

class OfficesNotifier extends Notifier<OfficesState> {
  late final PracticeRepository _repository;

  @override
  OfficesState build() {
    _repository = ref.watch(practiceRepositoryProvider);
    Future.microtask(() => fetchOffices());
    return const OfficesState(isLoading: true);
  }

  Future<void> fetchOffices() async {
    if (!state.isLoading) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final list = await _repository.getOffices();
      state = state.copyWith(
        isLoading: false,
        offices: list,
        filteredOffices: _applyFilters(list, state.selectedTerritory, state.searchQuery),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', ''),
      );
    }
  }

  void selectTerritory(String territory) {
    state = state.copyWith(
      selectedTerritory: territory,
      filteredOffices: _applyFilters(state.offices, territory, state.searchQuery),
    );
  }

  void search(String query) {
    state = state.copyWith(
      searchQuery: query,
      filteredOffices: _applyFilters(state.offices, state.selectedTerritory, query),
    );
  }

  void selectOffice(OfficeEntity? office) {
    state = state.copyWith(selectedOffice: office);
  }

  List<OfficeEntity> _applyFilters(
    List<OfficeEntity> list,
    String territory,
    String query,
  ) {
    return list.where((office) {
      // Filter by territory type
      final matchesTerritory = switch (territory.toLowerCase()) {
        'all' => true,
        'national' => office.type.toLowerCase() == 'national',
        'regional' => office.type.toLowerCase() == 'regional',
        'international' => office.type.toLowerCase() == 'international',
        _ => true,
      };

      if (!matchesTerritory) return false;

      // Filter by search query
      if (query.trim().isEmpty) return true;
      final q = query.toLowerCase().trim();
      final inName = office.name.toLowerCase().contains(q);
      final inCode = office.code.toLowerCase().contains(q);
      final inTerritory = office.territory.toLowerCase().contains(q);
      return inName || inCode || inTerritory;
    }).toList();
  }
}

final officesProvider =
    NotifierProvider<OfficesNotifier, OfficesState>(OfficesNotifier.new);
