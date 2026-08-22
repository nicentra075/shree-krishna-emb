import 'package:shree_krishna_core/errors/failures.dart';
import 'package:shree_krishna_core/models/review_model.dart';
import 'package:shree_krishna_core/utils/either.dart';

/// Backend-agnostic contract for design reviews.
abstract class ReviewsRepository {
  Future<Either<Failure, List<ReviewModel>>> getReviews(
    String designId, {
    int limit,
  });

  Future<Either<Failure, ReviewModel?>> getMyReview(String designId);

  Future<Either<Failure, void>> upsertReview({
    required String designId,
    required int rating,
    required String comment,
  });

  Future<Either<Failure, void>> deleteReview(String designId);
}
