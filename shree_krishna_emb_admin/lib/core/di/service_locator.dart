import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/dashboard/dashboard_stats_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/categories_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/designs_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/home_layout_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/media/media_library_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/media/design_file_library_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/payouts/payouts_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/platform_config/platform_config_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/reports/reports_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/transactions/orders_cubit.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_admin_auth_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_image_storage_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_media_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_design_file_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_catalog_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_dashboard_stats_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_home_config_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_orders_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_payouts_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_platform_config_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_reports_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_user_list_datasource.dart';
import 'package:shree_krishna_emb_admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/catalog_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/dashboard_stats_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/home_config_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/media_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/design_file_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/orders_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/payouts_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/platform_config_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/reports_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/user_list_repository_impl.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/dashboard_stats_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/media_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/design_file_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/admin_auth_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/catalog_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/home_config_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/orders_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/payouts_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/platform_config_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/reports_repository.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/user_list_repository.dart';

final getIt = GetIt.instance;

Future<void> setupAdminServiceLocator(SharedPreferences prefs) async {
  // Firebase instances
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  getIt.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);

  // Initialize Hive local storage
  await Hive.initFlutter();

  // Open Hive boxes for caching
  await Hive.openBox<String>('user_cache');
  await Hive.openBox<String>('user_list_cache');
  await Hive.openBox<String>('product_cache');
  await Hive.openBox<String>('product_list_cache');

  // Register SharedPreferences instance
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Shared theme state (persistent light/dark/system mode)
  getIt.registerSingleton<ThemeCubit>(ThemeCubit(prefs));

  // ADMIN AUTH - Clean Architecture Pattern
  // Data Layer
  getIt.registerSingleton<AdminAuthDataSource>(
    FirebaseAdminAuthDataSource(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );

  // Repository Layer (switches backends here if needed)
  getIt.registerSingleton<AdminAuthRepository>(
    AdminAuthRepositoryImpl(dataSource: getIt<AdminAuthDataSource>()),
  );

  // Presentation Layer (BLoC)
  getIt.registerSingleton<AdminAuthBloc>(
    AdminAuthBloc(repository: getIt<AdminAuthRepository>()),
  );

  // USER LIST MANAGEMENT - Clean Architecture Pattern
  // Data Layer
  getIt.registerSingleton<UserListDataSource>(
    FirebaseUserListDataSource(firestore: getIt<FirebaseFirestore>()),
  );

  // Repository Layer
  getIt.registerSingleton<UserListRepository>(
    UserListRepositoryImpl(dataSource: getIt<UserListDataSource>()),
  );

  // Note: UserListBloc is registered per-screen in UserManagementScreen

  // DESIGN STORE (Collections / Categories / Designs) - Clean Architecture
  getIt.registerSingleton<CatalogDataSource>(
    FirebaseCatalogDataSource(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerSingleton<CatalogRepository>(
    CatalogRepositoryImpl(dataSource: getIt<CatalogDataSource>()),
  );
  // Cubits are created per-screen (factories) by DesignStoreContentView.
  // IMAGES — Storage upload + Media Library (registered before the catalog
  // cubits so their factories can resolve it for delete-image-on-delete).
  getIt.registerSingleton<ImageStorageDataSource>(
    ImageStorageDataSource(storage: getIt<FirebaseStorage>()),
  );
  getIt.registerFactory<CollectionsCubit>(
    () => CollectionsCubit(
      repository: getIt<CatalogRepository>(),
      imageStorage: getIt<ImageStorageDataSource>(),
    ),
  );
  getIt.registerFactory<CategoriesCubit>(
    () => CategoriesCubit(
      repository: getIt<CatalogRepository>(),
      imageStorage: getIt<ImageStorageDataSource>(),
    ),
  );
  getIt.registerFactory<DesignsCubit>(
    () => DesignsCubit(
      repository: getIt<CatalogRepository>(),
      imageStorage: getIt<ImageStorageDataSource>(),
    ),
  );

  getIt.registerSingleton<FirebaseMediaDataSource>(
    FirebaseMediaDataSource(
      firestore: getIt<FirebaseFirestore>(),
      imageStorage: getIt<ImageStorageDataSource>(),
    ),
  );
  getIt.registerSingleton<MediaRepository>(
    MediaRepositoryImpl(dataSource: getIt<FirebaseMediaDataSource>()),
  );
  getIt.registerFactory<MediaLibraryCubit>(
    () => MediaLibraryCubit(repository: getIt<MediaRepository>()),
  );

  // DESIGN FILE LIBRARY — downloadable source files (.dst/.emb/.dhe) under the
  // `design_files/` Storage folder + `design_files/{id}` index docs.
  getIt.registerSingleton<FirebaseDesignFileDataSource>(
    FirebaseDesignFileDataSource(
      firestore: getIt<FirebaseFirestore>(),
      storage: getIt<ImageStorageDataSource>(),
    ),
  );
  getIt.registerSingleton<DesignFileRepository>(
    DesignFileRepositoryImpl(dataSource: getIt<FirebaseDesignFileDataSource>()),
  );
  getIt.registerFactory<DesignFileLibraryCubit>(
    () => DesignFileLibraryCubit(repository: getIt<DesignFileRepository>()),
  );

  // DESIGN STORE - Home Layout config (Phase B)
  getIt.registerSingleton<HomeConfigDataSource>(
    FirebaseHomeConfigDataSource(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerSingleton<HomeConfigRepository>(
    HomeConfigRepositoryImpl(dataSource: getIt<HomeConfigDataSource>()),
  );
  getIt.registerFactory<HomeLayoutCubit>(
    () => HomeLayoutCubit(repository: getIt<HomeConfigRepository>()),
  );

  // Cloud Functions (region-pinned) — used to call `initiateRefund`.
  getIt.registerSingleton<FirebaseFunctions>(
    FirebaseFunctions.instanceFor(region: CloudFunctionNames.region),
  );

  // PLATFORM CONFIG (`config/platform`) - fee/gst, payment mode, Razorpay keys
  getIt.registerSingleton<PlatformConfigDataSource>(
    FirebasePlatformConfigDataSource(
      firestore: getIt<FirebaseFirestore>(),
      functions: getIt<FirebaseFunctions>(),
    ),
  );
  getIt.registerSingleton<PlatformConfigRepository>(
    PlatformConfigRepositoryImpl(dataSource: getIt<PlatformConfigDataSource>()),
  );
  getIt.registerFactory<PlatformConfigCubit>(
    () => PlatformConfigCubit(repository: getIt<PlatformConfigRepository>()),
  );

  // ORDERS / TRANSACTIONS - shared orders cache + refund callable.
  getIt.registerSingleton<OrdersDataSource>(
    FirebaseOrdersDataSource(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerSingleton<OrdersRepository>(
    OrdersRepositoryImpl(
      dataSource: getIt<OrdersDataSource>(),
      functions: getIt<FirebaseFunctions>(),
    ),
  );
  getIt.registerFactory<OrdersCubit>(
    () => OrdersCubit(repository: getIt<OrdersRepository>()),
  );

  // DASHBOARD live stats (aggregate counts + revenue summary/chart).
  getIt.registerSingleton<DashboardStatsDataSource>(
    FirebaseDashboardStatsDataSource(firestore: getIt<FirebaseFirestore>()),
  );
  getIt.registerSingleton<DashboardStatsRepository>(
    DashboardStatsRepositoryImpl(dataSource: getIt<DashboardStatsDataSource>()),
  );
  getIt.registerFactory<DashboardStatsCubit>(
    () => DashboardStatsCubit(repository: getIt<DashboardStatsRepository>()),
  );

  // REPORTS (sales summary + CSV export) - reuses the orders cache.
  getIt.registerSingleton<ReportsDataSource>(
    FirebaseReportsDataSource(
      firestore: getIt<FirebaseFirestore>(),
      ordersDataSource: getIt<OrdersDataSource>(),
    ),
  );
  getIt.registerSingleton<ReportsRepository>(
    ReportsRepositoryImpl(dataSource: getIt<ReportsDataSource>()),
  );
  getIt.registerFactory<ReportsCubit>(
    () => ReportsCubit(repository: getIt<ReportsRepository>()),
  );

  // PAYOUTS (interim read-only earnings owed per designer).
  getIt.registerSingleton<PayoutsDataSource>(
    FirebasePayoutsDataSource(
      firestore: getIt<FirebaseFirestore>(),
      ordersDataSource: getIt<OrdersDataSource>(),
    ),
  );
  getIt.registerSingleton<PayoutsRepository>(
    PayoutsRepositoryImpl(dataSource: getIt<PayoutsDataSource>()),
  );
  getIt.registerFactory<PayoutsCubit>(
    () => PayoutsCubit(repository: getIt<PayoutsRepository>()),
  );
}
