import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/bloc/walkthrough/walkthrough_bloc.dart';
import 'package:shree_krishna_emb/bloc/splash/splash_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/home_feed/home_feed_cubit.dart';
import 'package:shree_krishna_emb/bloc/suggested_designs/suggested_designs_cubit.dart';
import 'package:shree_krishna_emb/bloc/sellers/authorised_sellers_cubit.dart';
import 'package:shree_krishna_emb/bloc/wishlist/wishlist_cubit.dart';
import 'package:shree_krishna_emb/bloc/cart/cart_cubit.dart';
import 'package:shree_krishna_emb/bloc/purchases/purchases_cubit.dart';
import 'package:shree_krishna_emb/bloc/platform_config/platform_config_cubit.dart';
import 'package:shree_krishna_emb/bloc/checkout/checkout_cubit.dart';
import 'package:shree_krishna_emb/bloc/notifications/notification_cubit.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_fcm_token_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_notifications_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_wishlist_datasource.dart';
import 'package:shree_krishna_emb/data/repositories/fcm_token_repository_impl.dart';
import 'package:shree_krishna_emb/data/repositories/notifications_repository_impl.dart';
import 'package:shree_krishna_emb/data/repositories/wishlist_repository_impl.dart';
import 'package:shree_krishna_emb/data/services/notification_service.dart';
import 'package:shree_krishna_emb/domain/repositories/fcm_token_repository.dart';
import 'package:shree_krishna_emb/domain/repositories/notifications_repository.dart';
import 'package:shree_krishna_emb/domain/repositories/wishlist_repository.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_cart_datasource.dart';
import 'package:shree_krishna_emb/data/repositories/cart_repository_impl.dart';
import 'package:shree_krishna_emb/domain/repositories/cart_repository.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_purchases_datasource.dart';
import 'package:shree_krishna_emb/data/repositories/purchases_repository_impl.dart';
import 'package:shree_krishna_emb/domain/repositories/purchases_repository.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_platform_config_datasource.dart';
import 'package:shree_krishna_emb/data/repositories/platform_config_repository_impl.dart';
import 'package:shree_krishna_emb/domain/repositories/platform_config_repository.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_order_writer.dart';
import 'package:shree_krishna_emb/data/services/checkout_service_factory.dart';
import 'package:shree_krishna_emb/data/datasources/local_user_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_auth_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_catalog_query_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_home_feed_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_seller_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/local_home_feed_cache.dart';
import 'package:shree_krishna_emb/data/datasources/local_recently_viewed_store.dart';
import 'package:shree_krishna_emb/data/repositories/auth_repository_impl.dart';
import 'package:shree_krishna_emb/data/repositories/home_feed_repository_impl.dart';
import 'package:shree_krishna_emb/data/repositories/seller_repository_impl.dart';
import 'package:shree_krishna_emb/domain/repositories/auth_repository.dart';
import 'package:shree_krishna_emb/domain/repositories/home_feed_repository.dart';
import 'package:shree_krishna_emb/domain/repositories/seller_repository.dart';
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
  final homeFeedCacheBox = await Hive.openBox<String>('home_feed_cache');
  final recentlyViewedBox = await Hive.openBox<String>('recently_viewed');

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

  // Shared theme state (persistent light/dark/system mode)
  getIt.registerSingleton<ThemeCubit>(ThemeCubit(prefs));

  // Data sources (Firebase implementations)
  getIt.registerSingleton<FirebaseAuthDataSource>(
    FirebaseAuthDataSourceImpl(
      firebaseAuth: getIt(),
      firestore: getIt(),
      googleSignIn: getIt(),
    ),
  );

  getIt.registerSingleton<SellerDataSource>(
    FirebaseSellerDataSource(firestore: getIt()),
  );

  // Repositories
  getIt.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(dataSource: getIt()),
  );
  getIt.registerSingleton<SellerRepository>(
    SellerRepositoryImpl(dataSource: getIt()),
  );

  // HOME FEED (server-driven UI) - Phase C
  getIt.registerSingleton<RecentlyViewedStore>(
    RecentlyViewedStore(recentlyViewedBox),
  );
  getIt.registerSingleton<LocalHomeFeedCache>(
    LocalHomeFeedCache(homeFeedCacheBox),
  );
  getIt.registerSingleton<HomeFeedDataSource>(
    FirebaseHomeFeedDataSource(
      firestore: getIt(),
      sellerDataSource: getIt(),
      recentStore: getIt(),
    ),
  );
  getIt.registerSingleton<HomeFeedRepository>(
    HomeFeedRepositoryImpl(dataSource: getIt(), cache: getIt()),
  );

  // Catalog queries for View-All + design detail (Phase D)
  getIt.registerSingleton<CatalogQueryDataSource>(
    CatalogQueryDataSource(firestore: getIt(), sellerDataSource: getIt()),
  );

  // Favorites / wishlist
  getIt.registerSingleton<WishlistDataSource>(
    FirebaseWishlistDataSource(firestore: getIt(), auth: getIt()),
  );
  getIt.registerSingleton<WishlistRepository>(
    WishlistRepositoryImpl(dataSource: getIt()),
  );
  // Singleton so heart state is shared app-wide.
  getIt.registerSingleton<WishlistCubit>(WishlistCubit(repository: getIt()));

  // ===== Platform settings (fee%, gst%, payment mode, razorpay key) =====
  getIt.registerSingleton<PlatformConfigDataSource>(
    FirebasePlatformConfigDataSource(firestore: getIt()),
  );
  getIt.registerSingleton<PlatformConfigRepository>(
    PlatformConfigRepositoryImpl(dataSource: getIt()),
  );
  getIt.registerSingleton<PlatformConfigCubit>(
    PlatformConfigCubit(repository: getIt()),
  );

  // ===== Cart =====
  getIt.registerSingleton<CartDataSource>(
    FirebaseCartDataSource(firestore: getIt(), auth: getIt()),
  );
  getIt.registerSingleton<CartRepository>(
    CartRepositoryImpl(dataSource: getIt()),
  );
  // Singleton so the app-bar badge + detail CTA stay in sync app-wide.
  getIt.registerSingleton<CartCubit>(CartCubit(repository: getIt()));

  // ===== Purchases (ownership) =====
  getIt.registerSingleton<PurchasesDataSource>(
    FirebasePurchasesDataSource(firestore: getIt(), auth: getIt()),
  );
  getIt.registerSingleton<PurchasesRepository>(
    PurchasesRepositoryImpl(dataSource: getIt()),
  );
  getIt.registerSingleton<PurchasesCubit>(PurchasesCubit(repository: getIt()));

  // ===== Push notifications (FCM token registry + in-app feed) =====
  getIt.registerSingleton<FcmTokenDataSource>(
    FirebaseFcmTokenDataSource(firestore: getIt()),
  );
  getIt.registerSingleton<FcmTokenRepository>(
    FcmTokenRepositoryImpl(dataSource: getIt()),
  );
  getIt.registerSingleton<NotificationService>(
    NotificationService(tokenRepository: getIt()),
  );
  getIt.registerSingleton<NotificationsDataSource>(
    FirebaseNotificationsDataSource(firestore: getIt()),
  );
  getIt.registerSingleton<NotificationsRepository>(
    NotificationsRepositoryImpl(dataSource: getIt()),
  );
  // Singleton so the notification bell/badge stays in sync app-wide.
  getIt.registerSingleton<NotificationCubit>(
    NotificationCubit(repository: getIt()),
  );

  // ===== Checkout =====
  // Client-side order writer (test/demo paths only).
  getIt.registerSingleton<FirebaseOrderWriter>(
    FirebaseOrderWriter(firestore: getIt(), auth: getIt()),
  );
  getIt.registerSingleton<CheckoutServiceFactory>(
    CheckoutServiceFactory(orderWriter: getIt()),
  );
  // New cubit per checkout attempt (owns a native Razorpay instance).
  getIt.registerFactory<CheckoutCubit>(() => CheckoutCubit(factory: getIt()));

  // Cubits / Blocs
  getIt.registerFactory<AuthorisedSellersCubit>(
    () => AuthorisedSellersCubit(repository: getIt()),
  );
  getIt.registerFactory<HomeFeedCubit>(
    () => HomeFeedCubit(repository: getIt()),
  );
  getIt.registerFactory<SuggestedDesignsCubit>(
    () => SuggestedDesignsCubit(catalog: getIt()),
  );

  // Use cases
  getIt.registerSingleton<SignUpUseCase>(SignUpUseCase(getIt()));
  getIt.registerSingleton<SignInUseCase>(SignInUseCase(getIt()));
  getIt.registerSingleton<SignInWithGoogleUseCase>(
    SignInWithGoogleUseCase(getIt()),
  );
  getIt.registerSingleton<SendPhoneOtpUseCase>(SendPhoneOtpUseCase(getIt()));
  getIt.registerSingleton<VerifyPhoneOtpUseCase>(
    VerifyPhoneOtpUseCase(getIt()),
  );
  getIt.registerSingleton<CompleteGoogleProfileUseCase>(
    CompleteGoogleProfileUseCase(getIt()),
  );
  getIt.registerSingleton<CompletePhoneProfileUseCase>(
    CompletePhoneProfileUseCase(getIt()),
  );
  getIt.registerSingleton<SignOutUseCase>(SignOutUseCase(getIt()));
  getIt.registerSingleton<GetCurrentUserUseCase>(
    GetCurrentUserUseCase(getIt()),
  );
  getIt.registerSingleton<SendPasswordResetEmailUseCase>(
    SendPasswordResetEmailUseCase(getIt()),
  );

  // BLoCs
  getIt.registerSingleton<SplashBloc>(SplashBloc(localDataSource: getIt()));
  getIt.registerSingleton<WalkthroughBloc>(
    WalkthroughBloc(localDataSource: getIt()),
  );
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
