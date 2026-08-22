import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_catalog_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/category_model.dart';
import 'package:shree_krishna_emb_admin/data/models/collection_model.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  final CatalogDataSource _dataSource;

  CatalogRepositoryImpl({required CatalogDataSource dataSource})
    : _dataSource = dataSource;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  // Collections
  @override
  Future<Either<Failure, List<CollectionModel>>> getCollections({
    bool forceRefresh = false,
  }) => _guard(() => _dataSource.getCollections(forceRefresh: forceRefresh));

  @override
  Future<Either<Failure, CollectionModel>> createCollection(
    CollectionModel collection,
  ) => _guard(() => _dataSource.createCollection(collection));

  @override
  Future<Either<Failure, void>> updateCollection(CollectionModel collection) =>
      _guard(() => _dataSource.updateCollection(collection));

  @override
  Future<Either<Failure, void>> deleteCollection(String id) =>
      _guard(() => _dataSource.deleteCollection(id));

  // Categories
  @override
  Future<Either<Failure, List<CategoryModel>>> getCategories({
    String? collectionId,
    bool forceRefresh = false,
  }) => _guard(
    () => _dataSource.getCategories(
      collectionId: collectionId,
      forceRefresh: forceRefresh,
    ),
  );

  @override
  Future<Either<Failure, CategoryModel>> createCategory(
    CategoryModel category,
  ) => _guard(() => _dataSource.createCategory(category));

  @override
  Future<Either<Failure, void>> updateCategory(CategoryModel category) =>
      _guard(() => _dataSource.updateCategory(category));

  @override
  Future<Either<Failure, void>> deleteCategory(String id) =>
      _guard(() => _dataSource.deleteCategory(id));

  // Designs
  @override
  Future<Either<Failure, List<DesignModel>>> getDesigns({
    String? collectionId,
    String? categoryId,
    String? status,
    String? searchQuery,
    DesignSort sort = DesignSort.newest,
    bool forceRefresh = false,
    String? authorId,
  }) => _guard(
    () => _dataSource.getDesigns(
      collectionId: collectionId,
      categoryId: categoryId,
      status: status,
      searchQuery: searchQuery,
      sort: sort,
      forceRefresh: forceRefresh,
      authorId: authorId,
    ),
  );

  @override
  Future<Either<Failure, DesignModel>> createDesign(DesignModel design) =>
      _guard(() => _dataSource.createDesign(design));

  @override
  Future<Either<Failure, void>> updateDesign(DesignModel design) =>
      _guard(() => _dataSource.updateDesign(design));

  @override
  Future<Either<Failure, void>> deleteDesign(String id) =>
      _guard(() => _dataSource.deleteDesign(id));
}
