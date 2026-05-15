/// Abstract base class for all admin locale implementations
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
  String get add;
  String get create;
  String get update;
  String get view;
  String get export;
  String get import_;
  String get search;
  String get filter;
  String get sort;
  String get settings;

  // ========== Dashboard ==========
  String get dashboard;
  String get adminDashboard;
  String get dashboardWelcome;
  String get totalOrders;
  String get totalRevenue;
  String get totalUsers;
  String get totalProducts;
  String get recentOrders;
  String get recentActivity;
  String get analytics;
  String get statistics;

  // ========== Products Management ==========
  String get products;
  String get manageProducts;
  String get addProduct;
  String get editProduct;
  String get productName;
  String get productDescription;
  String get productPrice;
  String get productCategory;
  String get productStock;
  String get productImage;
  String get productStatus;
  String get active;
  String get inactive;
  String get noProducts;
  String get productAdded;
  String get productUpdated;
  String get productDeleted;

  // ========== Orders Management ==========
  String get orders;
  String get manageOrders;
  String get orderID;
  String get orderDate;
  String get orderStatus;
  String get orderTotal;
  String get orderCustomer;
  String get orderDetails;
  String get orderItems;
  String get shippingAddress;
  String get billingAddress;
  String get paymentMethod;
  String get trackingNumber;
  String get pending;
  String get processing;
  String get shipped;
  String get delivered;
  String get cancelled;
  String get returned;
  String get noOrders;
  String get orderUpdated;

  // ========== Users Management ==========
  String get users;
  String get manageUsers;
  String get userName;
  String get userEmail;
  String get userPhone;
  String get userStatus;
  String get userJoinDate;
  String get userOrders;
  String get userDetails;
  String get blockUser;
  String get unblockUser;
  String get noUsers;

  // ========== Categories ==========
  String get categories;
  String get manageCategories;
  String get addCategory;
  String get categoryName;
  String get categoryDescription;
  String get categoryImage;
  String get noCategories;
  String get categoryAdded;
  String get categoryUpdated;
  String get categoryDeleted;

  // ========== Theme Configuration ==========
  String get themeConfiguration;
  String get manageTheme;
  String get primaryColor;
  String get secondaryColor;
  String get accentColor;
  String get fontFamily;
  String get borderRadius;
  String get spacing;
  String get darkMode;
  String get lightMode;
  String get themeUpdated;
  String get previewChanges;
  String get applyChanges;

  // ========== Analytics & Reports ==========
  String get reports;
  String get generateReport;
  String get salesReport;
  String get userReport;
  String get inventoryReport;
  String get dateRange;
  String get from;
  String get to;
  String get download;
  String get noData;

  // ========== Settings ==========
  String get appSettings;
  String get generalSettings;
  String get securitySettings;
  String get notificationSettings;
  String get emailNotifications;
  String get pushNotifications;
  String get currency;
  String get timezone;
  String get language;
  String get settingsSaved;

  // ========== Validation & Errors ==========
  String get fieldRequired;
  String get invalidEmail;
  String get invalidPhone;
  String get invalidPrice;
  String get invalidQuantity;
  String get serverError;
  String get unknownError;
  String get networkError;

  // ========== Confirmation Dialogs ==========
  String get confirmDelete;
  String get confirmDeleteMessage;
  String get deleteSuccess;
  String get deleteError;

  // ========== Admin Actions ==========
  String get logout;
  String get login;
  String get email;
  String get password;
  String get forgotPassword;
  String get resetPassword;
  String get changePassword;
  String get profile;
  String get editProfile;
  String get aboutUs;
  String get contactSupport;
  String get help;
  String get documentation;

  // ========== Splash Screen ==========
  String get splashTitle;
  String get splashWelcomeTo;
  String get splashTagline;
  String get splashInitializing;
  String get madeWithLove;
  String get byNicentra;

  // ========== Admin Login Screen ==========
  String get adminLoginTitle;
  String get adminLoginSubtitle;
  String get adminLoginDescription;
  String get adminLoginTagline;
  String get adminLoginWelcome;
  String get adminEmail;
  String get adminPassword;
  String get adminPasswordHint;
  String get adminRememberMe;
  String get adminForgotPassword;
  String get adminSignIn;
  String get adminWelcomeSuccess;
  String get adminCopyright;

  // ========== Forgot Password Screen ==========
  String get enterYourEmail;
  String get resetLinkMessage;
  String get sendResetLink;
  String get resetLinkSentMessage;
}
