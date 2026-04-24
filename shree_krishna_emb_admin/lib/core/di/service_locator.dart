import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Register future admin-specific data sources, repositories, and services here
  // TODO: Register admin-specific datasources
  // TODO: Register admin repositories
  // TODO: Register admin use cases
  // TODO: Register admin BLoCs
}
