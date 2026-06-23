import 'package:shree_krishna_core/utils/either.dart';
import 'package:shree_krishna_emb_admin/core/errors/failures.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_catalog_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/category_model.dart';
import 'package:shree_krishna_emb_admin/data/models/collection_model.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';

/// Backend-agnostic contract for the Design Store catalog
/// (collections, categories, designs).
abstract class CatalogRepository {
  Future<Either<Failure, List<CollectionModel>>> getCollections({
    bool forceRefresh,
  });
  Future<Either<Failure, CollectionModel>> createCollection(
    CollectionModel collection,
  );
  Future<Either<Failure, void>> updateCollection(CollectionModel collection);
  Future<Either<Failure, void>> deleteCollection(String id);

  Future<Either<Failure, List<CategoryModel>>> getCategories({
    String? collectionId,
    bool forceRefresh,
  });
  Future<Either<Failure, CategoryModel>> createCategory(CategoryModel category);
  Future<Either<Failure, void>> updateCategory(CategoryModel category);
  Future<Either<Failure, void>> deleteCategory(String id);

  Future<Either<Failure, List<DesignModel>>> getDesigns({
    String? collectionId,
    String? categoryId,
    String? status,
    String? searchQuery,
    DesignSort sort,
    bool forceRefresh,
  });
  Future<Either<Failure, DesignModel>> createDesign(DesignModel design);
  Future<Either<Failure, void>> updateDesign(DesignModel design);
  Future<Either<Failure, void>> deleteDesign(String id);
}
