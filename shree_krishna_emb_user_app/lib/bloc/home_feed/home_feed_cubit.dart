import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';
import 'package:shree_krishna_emb/domain/repositories/home_feed_repository.dart';

enum HomeFeedStatus { initial, loading, loaded, error }

class HomeFeedState extends Equatable {
  final HomeFeedStatus status;
  final HomeFeed feed;
  final String? error;

  const HomeFeedState({
    this.status = HomeFeedStatus.initial,
    this.feed = const HomeFeed(),
    this.error,
  });

  HomeFeedState copyWith({
    HomeFeedStatus? status,
    HomeFeed? feed,
    String? error,
  }) =>
      HomeFeedState(
        status: status ?? this.status,
        feed: feed ?? this.feed,
        error: error,
      );

  @override
  List<Object?> get props => [status, feed, error];
}

class HomeFeedCubit extends Cubit<HomeFeedState> {
  final HomeFeedRepository repository;

  HomeFeedCubit({required this.repository}) : super(const HomeFeedState());

  /// Called once when the Home screen opens (cache-first).
  Future<void> load() async {
    emit(state.copyWith(status: HomeFeedStatus.loading));
    _emitResult(await repository.load());
  }

  /// Pull-to-refresh — bypasses the cache.
  Future<void> refresh() async {
    _emitResult(await repository.load(forceRefresh: true));
  }

  void _emitResult(Either<Failure, HomeFeed> result) {
    result.fold(
      (failure) => emit(state.copyWith(
          status: HomeFeedStatus.error, error: failure.message)),
      (feed) => emit(HomeFeedState(status: HomeFeedStatus.loaded, feed: feed)),
    );
  }
}
