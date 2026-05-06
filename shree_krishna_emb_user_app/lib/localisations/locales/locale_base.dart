/// Abstract base class for all locale implementations
/// Every locale must implement these getters to provide translated strings
abstract class LocaleStrings {
  // ========== App General ==========
  String get appName;
  String get appVersion;

  // ========== Common ==========
  String get confirm;
  String get cancel;
  String get ok;
  String get dismiss;
  String get back;
  String get next;
  String get skip;
  String get done;
  String get delete;
  String get edit;
  String get save;
  String get retry;
  String get refresh;
  String get loading;
  String get error;
  String get success;
  String get warning;
  String get info;
  String get close;

  // ========== Splash Screen ==========
  String get splashTitle;
  String get splashWelcomeTo;
  String get splashTagline;
  String get splashInitializing;
  String get madeWithLove;
  String get byNicentra;

  // ========== Walkthrough Screens ==========
  String get walkthroughSkip;
  String get walkthroughGetStarted;
  String get walkthroughNext;

  // Discover Page
  String get discoverTitle;
  String get discoverSubtitle;
  String get discoverFeature1Title;
  String get discoverFeature1Desc;
  String get discoverFeature2Title;
  String get discoverFeature2Desc;
  String get discoverFeature3Title;
  String get discoverFeature3Desc;

  // Collaborate Page
  String get collaborateTitle;
  String get collaborateSubtitle;
  String get collaborateFeature1Title;
  String get collaborateFeature1Desc;
  String get collaborateFeature2Title;
  String get collaborateFeature2Desc;
  String get collaborateFeature3Title;
  String get collaborateFeature3Desc;

  // Get Started Page
  String get getStartedTitle;
  String get getStartedSubtitle;
  String get getStartedSignUp;
  String get getStartedSignIn;

  // ========== Authentication ==========
  String get email;
  String get password;
  String get confirmPassword;
  String get forgotPassword;
  String get signIn;
  String get signUp;
  String get signOut;
  String get loginTitle;
  String get loginSubtitle;
  String get registerTitle;
  String get registerSubtitle;
  String get noAccount;
  String get haveAccount;
  String get rememberMe;

  // ========== Validation Errors ==========
  String get fieldRequired;
  String get invalidEmail;
  String get invalidPhone;
  String get passwordTooShort;
  String get passwordNoNumber;
  String get passwordsDoNotMatch;

  // ========== Notifications & Messages ==========
  String get noInternetConnection;
  String get serverError;
  String get unknownError;
  String get tryAgain;
  String get noData;
  String get noResults;
  String get emptyList;

  // ========== Dialog Messages ==========
  String get confirmDelete;
  String get deleteConfirmation;
  String get deleteSuccess;
  String get deleteError;

  // ========== Home Screen ==========
  String get home;
  String get search;
  String get cart;
  String get wishlist;
  String get profile;
  String get menu;
  String get settings;

  // ========== Products ==========
  String get products;
  String get productDetails;
  String get addToCart;
  String get buyNow;
  String get price;
  String get quantity;
  String get inStock;
  String get outOfStock;
  String get description;
  String get reviews;
  String get rating;

  // ========== Orders ==========
  String get orders;
  String get orderHistory;
  String get orderDetails;
  String get orderStatus;
  String get orderDate;
  String get orderTotal;
  String get trackOrder;
  String get orderPending;
  String get orderProcessing;
  String get orderShipped;
  String get orderDelivered;
  String get orderCancelled;

  // ========== Cart ==========
  String get cartEmpty;
  String get cartContinueShopping;
  String get subtotal;
  String get shipping;
  String get tax;
  String get total;
  String get checkout;
  String get removeFromCart;

  // ========== User Profile ==========
  String get myProfile;
  String get editProfile;
  String get myAddresses;
  String get paymentMethods;
  String get preferences;
  String get language;
  String get darkMode;
  String get notifications;
  String get aboutUs;
  String get contactUs;
  String get privacyPolicy;
  String get termsOfService;
  String get logout;

  // ========== Form Placeholders ==========
  String get enterEmail;
  String get enterPassword;
  String get enterName;
  String get enterPhone;
  String get searchProducts;
  String get enterSearchQuery;

  // ========== Image Picker ==========
  String get chooseFromGallery;
  String get takePhoto;
  String get camera;
  String get gallery;

  // ========== Custom Orders ==========
  String get customOrder;
  String get customOrderTitle;
  String get uploadImage;
  String get selectDesign;
  String get chooseColors;
  String get estimatedPrice;
  String get submitOrder;

  // ========== Work & Projects ==========
  String get myWorkDashboard;
  String get myPurchases;
  String get all;
  String get open;
  String get inProgress;
  String get completed;
  String get noProjectsFound;
  String get noOrdersFound;

  // ========== Home Screen Sections ==========
  String get newArrival2024;
  String get royalZardosiCollection;
  String get explore;
  String get authorizedSellers;
  String get viewAll;
  String get verified;
  String get trendingDesigns;
  String get sareeDesigns;
  String get exploreCollections;
  String get recentlyViewed;
}
