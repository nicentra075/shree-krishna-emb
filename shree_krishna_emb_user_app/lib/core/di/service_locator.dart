import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shree_krishna_emb/bloc/walkthrough/walkthrough_bloc.dart';
import 'package:shree_krishna_emb/bloc/splash/splash_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/data/datasources/local_user_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_auth_datasource.dart';
import 'package:shree_krishna_emb/data/repositories/auth_repository_impl.dart';
import 'package:shree_krishna_emb/domain/repositories/auth_repository.dart';
import 'package:shree_krishna_emb/domain/usecases/auth_usecases.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator(SharedPreferences prefs) async {
  // Firebase instances
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);
  getIt.registerSingleton<FirebaseStorage>(FirebaseStorage.instance);

  // Initialize GoogleSignIn (v7.2.0+) with proper credentials
  // NOTE: clientId and serverClientId should be configured from Firebase config
  // For web: from your Firebase Console OAuth configuration
  // For mobile: flutterfire configure handles this from google-services.json/GoogleService-Info.plist
  final googleSignIn = GoogleSignIn.instance;
  await googleSignIn.initialize(
    // These can be null - GoogleSignIn will use platform defaults from config files
    clientId: null,
    serverClientId: null,
  );
  getIt.registerSingleton<GoogleSignIn>(googleSignIn);

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
  getIt.registerSingleton<FirebaseAuthDataSource>(
    FirebaseAuthDataSourceImpl(
      firebaseAuth: getIt(),
      firestore: getIt(),
      googleSignIn: getIt(),
    ),
  );

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(dataSource: getIt()),
  );

  // Use cases
  getIt.registerSingleton<SignUpUseCase>(SignUpUseCase(getIt()));
  getIt.registerSingleton<SignInUseCase>(SignInUseCase(getIt()));
  getIt.registerSingleton<SignInWithGoogleUseCase>(SignInWithGoogleUseCase(getIt()));
  getIt.registerSingleton<SendPhoneOtpUseCase>(SendPhoneOtpUseCase(getIt()));
  getIt.registerSingleton<VerifyPhoneOtpUseCase>(VerifyPhoneOtpUseCase(getIt()));
  getIt.registerSingleton<CompleteGoogleProfileUseCase>(
    CompleteGoogleProfileUseCase(getIt()),
  );
  getIt.registerSingleton<CompletePhoneProfileUseCase>(
    CompletePhoneProfileUseCase(getIt()),
  );
  getIt.registerSingleton<SignOutUseCase>(SignOutUseCase(getIt()));
  getIt.registerSingleton<GetCurrentUserUseCase>(GetCurrentUserUseCase(getIt()));
  getIt.registerSingleton<SendPasswordResetEmailUseCase>(
    SendPasswordResetEmailUseCase(getIt()),
  );

  // BLoCs
  getIt.registerSingleton<SplashBloc>(SplashBloc(localDataSource: getIt()));
  getIt.registerSingleton<WalkthroughBloc>(WalkthroughBloc(localDataSource: getIt()));
  getIt.registerSingleton<AuthBloc>(
    AuthBloc(
      signUpUseCase: getIt(),
      signInUseCase: getIt(),
      signInWithGoogleUseCase: getIt(),
      sendPhoneOtpUseCase: getIt(),
      verifyPhoneOtpUseCase: getIt(),
      completeGoogleProfileUseCase: getIt(),
      completePhoneProfileUseCase: getIt(),
      signOutUseCase: getIt(),
      getCurrentUserUseCase: getIt(),
      sendPasswordResetEmailUseCase: getIt(),
    ),
  );
}
