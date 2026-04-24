import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shree_krishna_emb/bloc/walkthrough/walkthrough_bloc.dart';
import 'package:shree_krishna_emb/bloc/splash/splash_bloc.dart';
import 'package:shree_krishna_emb/data/datasources/local_user_datasource.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator(SharedPreferences prefs) async {
  // Firebase instances
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  getIt.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);

  // Initialize Hive for local caching
  await Hive.initFlutter();
  final userCacheBox = await Hive.openBox<String>('user_cache');
  final userListCacheBox = await Hive.openBox<String>('user_list_cache');

  // Local data sources (Hive implementations)
  getIt.registerSingleton<LocalUserDataSource>(
    HiveLocalUserDataSource(
      userBox: userCacheBox,
      userListBox: userListCacheBox,
      prefs: prefs,
    ),
  );

  // Register SharedPreferences singleton for direct BLoC access
  getIt.registerSingleton<SharedPreferences>(prefs);

  // Data sources (Firebase implementations)
  // TODO: Register Firebase datasources here
  // Example:
  // getIt.registerSingleton<AuthRemoteDataSource>(
  //   FirebaseAuthRemoteDataSource(firebaseAuth: getIt()),
  // );

  // Repositories
  // TODO: Register repositories here
  // Example:
  // getIt.registerSingleton<AuthRepository>(
  //   AuthRepositoryImpl(remoteDataSource: getIt(), localDataSource: getIt()),
  // );

  // Use cases
  // TODO: Register use cases here

  // BLoCs
  getIt.registerSingleton<SplashBloc>(SplashBloc(localDataSource: getIt()));
  getIt.registerSingleton<WalkthroughBloc>(WalkthroughBloc(localDataSource: getIt()));
}
