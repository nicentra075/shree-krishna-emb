import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_reviews_datasource.dart';
import 'package:shree_krishna_emb/domain/repositories/reviews_repository.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsDataSource _dataSource;

  ReviewsRepositoryImpl({required ReviewsDataSource dataSource})
    : _dataSource = dataSource;

  @override
  Future<Either<Failure, List<ReviewModel>>> getReviews(
    String designId, {
    int limit = 50,
  }) async {
    try {
      final reviews = await _dataSource.getReviews(designId, limit: limit);
      return Right(reviews);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReviewModel?>> getMyReview(String designId) async {
    try {
      final review = await _dataSource.getMyReview(designId);
      return Right(review);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> upsertReview({
    required String designId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _dataSource.upsertReview(
        designId: designId,
        rating: rating,
        comment: comment,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(String designId) async {
    try {
      await _dataSource.deleteReview(designId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
