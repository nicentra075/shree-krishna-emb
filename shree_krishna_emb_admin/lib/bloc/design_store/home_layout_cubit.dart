import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/data/models/home_feed_config_model.dart';
import 'package:shree_krishna_emb_admin/domain/entities/home_section.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/home_config_repository.dart';

enum HomeLayoutStatus { initial, loading, loaded, error }

class HomeLayoutState extends Equatable {
  final HomeLayoutStatus status;
  final int version;
  final List<HomeSectionConfig> sections;
  final bool dirty;
  final bool saving;
  final String? error;

  const HomeLayoutState({
    this.status = HomeLayoutStatus.initial,
    this.version = 1,
    this.sections = const [],
    this.dirty = false,
    this.saving = false,
    this.error,
  });

  HomeLayoutState copyWith({
    HomeLayoutStatus? status,
    int? version,
    List<HomeSectionConfig>? sections,
    bool? dirty,
    bool? saving,
    String? error,
  }) =>
      HomeLayoutState(
        status: status ?? this.status,
        version: version ?? this.version,
        sections: sections ?? this.sections,
        dirty: dirty ?? this.dirty,
        saving: saving ?? this.saving,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, version, sections, dirty, saving, error];
}

class HomeLayoutCubit extends Cubit<HomeLayoutState> {
  final HomeConfigRepository repository;
  int _idSeed = 0;

  HomeLayoutCubit({required this.repository}) : super(const HomeLayoutState());

  Future<void> load() async {
    emit(state.copyWith(status: HomeLayoutStatus.loading));
    final result = await repository.read();
    if (isClosed) return; // screen left while the read was in flight
    result.fold(
      (failure) => emit(state.copyWith(
          status: HomeLayoutStatus.error, error: failure.message)),
      (config) => emit(HomeLayoutState(
        status: HomeLayoutStatus.loaded,
        version: config.version,
        sections: config.sections,
      )),
    );
  }

  String _newId(HomeSectionType type) {
    _idSeed++;
    return '${type.value}-${DateTime.now().millisecondsSinceEpoch}-$_idSeed';
  }

  void addSection(HomeSectionType type) {
    final defaultSource = switch (type) {
      HomeSectionType.banner =>
        const HomeSourceConfig(kind: HomeSourceKind.manual),
      HomeSectionType.authorisedSellersHorizontal =>
        const HomeSourceConfig(kind: HomeSourceKind.authorisedSellers, limit: 12),
      HomeSectionType.recentlyViewed =>
        const HomeSourceConfig(kind: HomeSourceKind.recentlyViewed, limit: 10),
      HomeSectionType.collectionsGrid ||
      HomeSectionType.categoriesHorizontal =>
        const HomeSourceConfig(kind: HomeSourceKind.query, limit: 8),
      _ => const HomeSourceConfig(kind: HomeSourceKind.query, limit: 10),
    };
    final section = HomeSectionConfig(
      id: _newId(type),
      type: type,
      position: state.sections.length,
      source: defaultSource,
    );
    emit(state.copyWith(
      sections: [...state.sections, section],
      dirty: true,
    ));
  }

  void removeSection(String id) {
    emit(state.copyWith(
      sections: state.sections.where((s) => s.id != id).toList(),
      dirty: true,
    ));
  }

  void toggleSection(String id) {
    emit(state.copyWith(
      sections: state.sections
          .map((s) => s.id == id ? s.copyWith(enabled: !s.enabled) : s)
          .toList(),
      dirty: true,
    ));
  }

  void editSection(HomeSectionConfig updated) {
    emit(state.copyWith(
      sections:
          state.sections.map((s) => s.id == updated.id ? updated : s).toList(),
      dirty: true,
    ));
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state.sections];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    emit(state.copyWith(sections: list, dirty: true));
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> save() async {
    emit(state.copyWith(saving: true));
    final config = HomeFeedConfig(version: state.version, sections: state.sections);
    final result = await repository.save(config);
    if (isClosed) return null;
    return result.fold(
      (failure) {
        emit(state.copyWith(saving: false, error: failure.message));
        return failure.message;
      },
      (_) {
        emit(state.copyWith(saving: false, dirty: false, version: state.version + 1));
        return null;
      },
    );
  }
}
