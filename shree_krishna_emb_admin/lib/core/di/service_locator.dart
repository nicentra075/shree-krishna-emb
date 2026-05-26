import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_admin_auth_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_user_list_datasource.dart';
import 'package:shree_krishna_emb_admin/data/repositories/admin_auth_repository_impl.dart';
import 'package:shree_krishna_emb_admin/data/repositories/user_list_repository_impl.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/admin_auth_repository.dart';
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

  // ADMIN AUTH - Clean Architecture Pattern
  // Data Layer
  getIt.registerSingleton<AdminAuthDataSource>(
    FirebaseAdminAuthDataSource(
      firebaseAuth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
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

  // Register future admin-specific data sources, repositories, and services here
  // TODO: Register admin-specific datasources for other features
  // TODO: Register admin repositories for other features
  // TODO: Register admin use cases
  // TODO: Register admin BLoCs for other features
}
