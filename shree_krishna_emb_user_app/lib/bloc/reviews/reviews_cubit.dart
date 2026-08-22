import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/models/review_model.dart';
import 'package:shree_krishna_emb/domain/repositories/reviews_repository.dart';

enum ReviewsStatus { initial, loading, loaded, error }

/// One-shot action outcomes the screen surfaces as toasts (D6).
enum ReviewActionResult { none, submitted, deleted, failed }

class ReviewsState extends Equatable {
  final ReviewsStatus status;
  final List<ReviewModel> reviews;
  final ReviewModel? myReview;
  final bool submitting;
  final ReviewActionResult lastAction;
  final String? error;

  const ReviewsState({
    this.status = ReviewsStatus.initial,
    this.reviews = const [],
    this.myReview,
    this.submitting = false,
    this.lastAction = ReviewActionResult.none,
    this.error,
  });

  double get avgRating {
    if (reviews.isEmpty) return 0;
    final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
    return sum / reviews.length;
  }

  ReviewsState copyWith({
    ReviewsStatus? status,
    List<ReviewModel>? reviews,
    ReviewModel? myReview,
    bool clearMyReview = false,
    bool? submitting,
    ReviewActionResult? lastAction,
    String? error,
  }) {
    return ReviewsState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
      myReview: clearMyReview ? null : (myReview ?? this.myReview),
      submitting: submitting ?? this.submitting,
      lastAction: lastAction ?? ReviewActionResult.none,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    reviews,
    myReview,
    submitting,
    lastAction,
    error,
  ];
}

/// Per-design reviews: the list, the signed-in user's own review, and
/// submit/delete actions. Created per detail screen.
class ReviewsCubit extends Cubit<ReviewsState> {
  final ReviewsRepository _repository;
  final String designId;

  ReviewsCubit({required ReviewsRepository repository, required this.designId})
    : _repository = repository,
      super(const ReviewsState());

  Future<void> load() async {
    emit(state.copyWith(status: ReviewsStatus.loading));

    final reviewsResult = await _repository.getReviews(designId);
    final myResult = await _repository.getMyReview(designId);

    reviewsResult.fold(
      (failure) => emit(
        state.copyWith(status: ReviewsStatus.error, error: failure.message),
      ),
      (reviews) {
        final my = myResult.fold((_) => null, (r) => r);
        emit(
          state.copyWith(
            status: ReviewsStatus.loaded,
            reviews: reviews,
            myReview: my,
            clearMyReview: my == null,
          ),
        );
      },
    );
  }

  Future<void> submit({required int rating, required String comment}) async {
    emit(state.copyWith(submitting: true));

    final result = await _repository.upsertReview(
      designId: designId,
      rating: rating,
      comment: comment,
    );

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            submitting: false,
            lastAction: ReviewActionResult.failed,
            error: failure.message,
          ),
        );
      },
      (_) async {
        emit(
          state.copyWith(
            submitting: false,
            lastAction: ReviewActionResult.submitted,
          ),
        );
        await load();
      },
    );
  }

  Future<void> deleteMyReview() async {
    final result = await _repository.deleteReview(designId);

    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            lastAction: ReviewActionResult.failed,
            error: failure.message,
          ),
        );
      },
      (_) async {
        emit(state.copyWith(lastAction: ReviewActionResult.deleted));
        await load();
      },
    );
  }
}
