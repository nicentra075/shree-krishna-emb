import 'locale_base.dart';

class EnUSStrings implements LocaleStrings {
  @override
  String get appName => 'Shree Krishna Embroidery - Admin';
  @override
  String get appVersion => 'v1.0.0';

  @override
  String get confirm => 'Confirm';
  @override
  String get cancel => 'Cancel';
  @override
  String get ok => 'OK';
  @override
  String get dismiss => 'Dismiss';
  @override
  String get back => 'Back';
  @override
  String get next => 'Next';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get save => 'Save';
  @override
  String get retry => 'Retry';
  @override
  String get refresh => 'Refresh';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'Error';
  @override
  String get success => 'Success';
  @override
  String get warning => 'Warning';
  @override
  String get info => 'Information';
  @override
  String get close => 'Close';
  @override
  String get add => 'Add';
  @override
  String get create => 'Create';
  @override
  String get update => 'Update';
  @override
  String get view => 'View';
  @override
  String get export => 'Export';
  @override
  String get import_ => 'Import';
  @override
  String get search => 'Search';
  @override
  String get filter => 'Filter';
  @override
  String get sort => 'Sort';
  @override
  String get settings => 'Settings';

  @override
  String get dashboard => 'Dashboard';
  @override
  String get adminDashboard => 'Admin Dashboard';
  @override
  String get dashboardWelcome => 'Welcome to Admin Dashboard';
  @override
  String get totalOrders => 'Total Orders';
  @override
  String get totalRevenue => 'Total Revenue';
  @override
  String get totalUsers => 'Total Users';
  @override
  String get totalProducts => 'Total Products';
  @override
  String get recentOrders => 'Recent Orders';
  @override
  String get recentActivity => 'Recent Activity';
  @override
  String get newDesign => 'New Design';
  @override
  String get by => 'by';
  @override
  String get justNow => 'Just now';
  @override
  String minutesAgo(int minutes) =>
      '$minutes minute${minutes == 1 ? '' : 's'} ago';
  @override
  String hoursAgo(int hours) => '$hours hour${hours == 1 ? '' : 's'} ago';
  @override
  String daysAgo(int days) => '$days day${days == 1 ? '' : 's'} ago';
  @override
  String get analytics => 'Analytics';
  @override
  String get statistics => 'Statistics';

  @override
  String get products => 'Products';
  @override
  String get manageProducts => 'Manage Products';
  @override
  String get addProduct => 'Add Product';
  @override
  String get editProduct => 'Edit Product';
  @override
  String get productName => 'Product Name';
  @override
  String get productDescription => 'Description';
  @override
  String get productPrice => 'Price';
  @override
  String get productCategory => 'Category';
  @override
  String get productStock => 'Stock';
  @override
  String get productImage => 'Product Image';
  @override
  String get productStatus => 'Status';
  @override
  String get active => 'Active';
  @override
  String get inactive => 'Inactive';
  @override
  String get allLabel => 'All';
  @override
  String get perPage => 'Per page';
  @override
  String get mediaLibrary => 'Media Library';
  @override
  String get uploadImages => 'Upload';
  @override
  String get uploading => 'Uploading';
  @override
  String uploadingPercent(int percent) => 'Uploading $percent%';
  @override
  String uploadingBatch(int done, int total, int percent) =>
      'Uploading $done/$total · $percent%';
  @override
  String get dragDropHint =>
      'Drag & drop images here, or use Upload to add them in one shot.';
  @override
  String get useImage => 'Use';
  @override
  String get chooseFromLibrary => 'Choose from Library';
  @override
  String get addImage => 'Add image';
  @override
  String get changeImage => 'Change image';
  @override
  String get uploadFromDevice => 'Upload from device';
  @override
  String get selectFromDevice => 'Select from device';
  @override
  String get selected => 'selected';
  @override
  String get designFiles => 'Design Files';
  @override
  String get designFileLibrary => 'Design File Library';
  @override
  String get uploadDesignFiles => 'Upload Design Files';
  @override
  String get addDesignFile => 'Add file';
  @override
  String get useFile => 'Use';
  @override
  String get alsoDeleteCategoriesDesigns =>
      'Also delete its categories and designs';
  @override
  String get alsoDeleteDesigns => 'Also delete its designs';
  @override
  String get deleteImpactTitle => 'What happens';
  @override
  String get deleteCollectionOnlyNote =>
      'Only this collection will be deleted. Its categories and designs are kept '
      'but become unlinked — they will no longer appear under any collection in '
      'the app, and any home section bound to this collection will show nothing.';
  @override
  String get deleteCollectionCascadeNote =>
      'This collection AND all of its categories and designs will be permanently '
      'deleted from the app. This cannot be undone.';
  @override
  String get deleteCategoryOnlyNote =>
      'Only this category will be deleted. Its designs are kept but become '
      'unlinked — they will no longer appear under any category, and any home '
      'section bound to this category will show nothing.';
  @override
  String get deleteCategoryCascadeNote =>
      'This category AND all of its designs will be permanently deleted from the '
      'app. This cannot be undone.';
  @override
  String get noProducts => 'No products found';
  @override
  String get productAdded => 'Product added successfully';
  @override
  String get productUpdated => 'Product updated successfully';
  @override
  String get productDeleted => 'Product deleted successfully';

  @override
  String get orders => 'Orders';
  @override
  String get manageOrders => 'Manage Orders';
  @override
  String get orderID => 'Order ID';
  @override
  String get orderDate => 'Order Date';
  @override
  String get orderStatus => 'Status';
  @override
  String get orderTotal => 'Total';
  @override
  String get orderCustomer => 'Customer';
  @override
  String get orderDetails => 'Order Details';
  @override
  String get orderItems => 'Items';
  @override
  String get shippingAddress => 'Shipping Address';
  @override
  String get billingAddress => 'Billing Address';
  @override
  String get paymentMethod => 'Payment Method';
  @override
  String get trackingNumber => 'Tracking Number';
  @override
  String get pending => 'Pending';
  @override
  String get processing => 'Processing';
  @override
  String get shipped => 'Shipped';
  @override
  String get delivered => 'Delivered';
  @override
  String get cancelled => 'Cancelled';
  @override
  String get returned => 'Returned';
  @override
  String get noOrders => 'No orders found';
  @override
  String get orderUpdated => 'Order updated successfully';

  @override
  String get users => 'Users';
  @override
  String get manageUsers => 'Manage Users';
  @override
  String get userName => 'User Name';
  @override
  String get userEmail => 'Email';
  @override
  String get userPhone => 'Phone';
  @override
  String get userStatus => 'Status';
  @override
  String get userJoinDate => 'Join Date';
  @override
  String get userOrders => 'Orders';
  @override
  String get userDetails => 'User Details';
  @override
  String get blockUser => 'Block User';
  @override
  String get unblockUser => 'Unblock User';
  @override
  String get noUsers => 'No users found';

  @override
  String get categories => 'Categories';
  @override
  String get manageCategories => 'Manage Categories';
  @override
  String get addCategory => 'Add Category';
  @override
  String get categoryName => 'Category Name';
  @override
  String get categoryDescription => 'Description';
  @override
  String get categoryImage => 'Category Image';
  @override
  String get noCategories => 'No categories found';
  @override
  String get categoryAdded => 'Category added successfully';
  @override
  String get categoryUpdated => 'Category updated successfully';
  @override
  String get categoryDeleted => 'Category deleted successfully';

  @override
  String get themeConfiguration => 'Theme Configuration';
  @override
  String get manageTheme => 'Manage App Theme';
  @override
  String get primaryColor => 'Primary Color';
  @override
  String get secondaryColor => 'Secondary Color';
  @override
  String get accentColor => 'Accent Color';
  @override
  String get fontFamily => 'Font Family';
  @override
  String get borderRadius => 'Border Radius';
  @override
  String get spacing => 'Spacing';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get lightMode => 'Light Mode';
  @override
  String get themeUpdated => 'Theme updated successfully';
  @override
  String get previewChanges => 'Preview Changes';
  @override
  String get applyChanges => 'Apply Changes';

  @override
  String get reports => 'Reports';
  @override
  String get generateReport => 'Generate Report';
  @override
  String get salesReport => 'Sales Report';
  @override
  String get userReport => 'User Report';
  @override
  String get inventoryReport => 'Inventory Report';
  @override
  String get dateRange => 'Date Range';
  @override
  String get from => 'From';
  @override
  String get to => 'To';
  @override
  String get download => 'Download';
  @override
  String get noData => 'No data available';

  @override
  String get appearance => 'Appearance';
  @override
  String get systemDefault => 'System Default';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageHindi => 'हिन्दी (Hindi)';
  @override
  String get languageChanged => 'Language updated';

  @override
  String get adminPanel => 'Admin Panel';
  @override
  String get approvalQueue => 'Approval Queue';
  @override
  String get designStore => 'Design Store';
  @override
  String get userManagement => 'User Management';
  @override
  String get transactions => 'Transactions';
  @override
  String get platformFees => 'Platform Fees';
  @override
  String get payouts => 'Payouts';
  @override
  String get support => 'Support';
  @override
  String get searchPlaceholder =>
      'Search designers, designs or transactions...';
  @override
  String get insightsTitle => 'Shree Krishna Insights';
  @override
  String get approvedDesigns => 'Approved Designs';

  @override
  String get appSettings => 'App Settings';
  @override
  String get generalSettings => 'General Settings';
  @override
  String get securitySettings => 'Security Settings';
  @override
  String get notificationSettings => 'Notification Settings';
  @override
  String get emailNotifications => 'Email Notifications';
  @override
  String get pushNotifications => 'Push Notifications';
  @override
  String get currency => 'Currency';
  @override
  String get timezone => 'Timezone';
  @override
  String get language => 'Language';
  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get fieldRequired => 'This field is required';
  @override
  String get invalidEmail => 'Please enter a valid email';
  @override
  String get invalidPhone => 'Please enter a valid phone number';
  @override
  String get invalidPrice => 'Please enter a valid price';
  @override
  String get invalidQuantity => 'Please enter a valid quantity';
  @override
  String get serverError => 'Server error. Please try again';
  @override
  String get unknownError => 'An unknown error occurred';
  @override
  String get networkError => 'Network error. Check your connection';

  @override
  String get confirmDelete => 'Are you sure?';
  @override
  String get confirmDeleteMessage => 'This action cannot be undone.';
  @override
  String get deleteSuccess => 'Deleted successfully';
  @override
  String get deleteError => 'Failed to delete. Please try again';

  @override
  String get logout => 'Logout';
  @override
  String get logoutConfirmTitle => 'Log out?';
  @override
  String get logoutConfirmMessage =>
      'You will need to sign in again to access the admin panel.';
  @override
  String get login => 'Login';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get forgotPassword => 'Forgot Password?';
  @override
  String get resetPassword => 'Reset Password';
  @override
  String get changePassword => 'Change Password';
  @override
  String get profile => 'Profile';
  @override
  String get editProfile => 'Edit Profile';
  @override
  String get aboutUs => 'About Us';
  @override
  String get contactSupport => 'Contact Support';
  @override
  String get help => 'Help';
  @override
  String get documentation => 'Documentation';

  @override
  String get splashTitle => 'Shree Krishna Embroidery';
  @override
  String get splashWelcomeTo => 'Welcome to';
  @override
  String get splashTagline => 'Manage Your Embroidery Business with Ease';
  @override
  String get splashInitializing => 'Initializing...';
  @override
  String get madeWithLove => 'Made with';
  @override
  String get byNicentra => 'by Nicentra';

  @override
  String get adminLoginTitle => 'Shree Krishna Embroidery';
  @override
  String get adminLoginSubtitle => 'Manage Your Embroidery Empire';
  @override
  String get adminLoginDescription => 'Sign in to access the admin dashboard';
  @override
  String get adminLoginTagline =>
      'Streamline operations, track orders, and grow your embroidery business with our powerful admin dashboard.';
  @override
  String get adminLoginWelcome => 'Welcome Admin';
  @override
  String get adminEmail => 'Admin Email';
  @override
  String get adminPassword => 'Admin Password';
  @override
  String get adminPasswordHint => 'Enter your password';
  @override
  String get adminRememberMe => 'Remember me';
  @override
  String get adminWelcomeSuccess => 'Welcome Admin!';
  @override
  String get adminForgotPassword => 'Forgot Password?';
  @override
  String get adminSignIn => 'Sign In';
  @override
  String get adminCopyright =>
      '© 2026 Shree Krishna Embroidery. All rights reserved.';

  @override
  String get enterYourEmail => 'Enter your email address';
  @override
  String get resetLinkMessage =>
      'We\'ll send you a link to reset your password';
  @override
  String get sendResetLink => 'Send Reset Link';
  @override
  String get resetLinkSentMessage => 'Reset link sent to email';

  // ========== Design Store ==========
  @override
  String get collections => 'Collections';
  @override
  String get designs => 'Designs';
  @override
  String get homeLayout => 'Home Layout';
  @override
  String get addSection => 'Add Section';
  @override
  String get addSectionSubtitle => 'Pick a block to add to the Home screen';
  @override
  String get publish => 'Publish';
  @override
  String get publishNow => 'Publish now';
  @override
  String get published => 'Published';
  @override
  String get unpublishedChanges => 'Unpublished changes';
  @override
  String get unpublishedBannerMessage =>
      'You have unpublished changes. They are not live in the app until you publish.';
  @override
  String get addCollection => 'Add Collection';
  @override
  String get addDesign => 'Add Design';
  @override
  String get editCollection => 'Edit Collection';
  @override
  String get editCategory => 'Edit Category';
  @override
  String get editDesign => 'Edit Design';
  @override
  String get collectionName => 'Collection Name';
  @override
  String get designName => 'Design Name';
  @override
  String get imageUrl => 'Image URL';
  @override
  String get descriptionLabel => 'Description';
  @override
  String get positionLabel => 'Position';
  @override
  String get isActiveLabel => 'Active';
  @override
  String get selectCollection => 'Select Collection';
  @override
  String get selectCategory => 'Select Category';
  @override
  String get code => 'Code';
  @override
  String get authorName => 'Author Name';
  @override
  String get price => 'Price';
  @override
  String get discountAmount => 'Discount Amount';
  @override
  String get isFree => 'Free Design';
  @override
  String get finalPrice => 'Final Price';
  @override
  String get free => 'Free';
  @override
  String get colorOrNeedleCount => 'Color / Needle Count';
  @override
  String get designFormat => 'Design Format';
  @override
  String get stitchCount => 'Stitch Count';
  @override
  String get heightLabel => 'Height';
  @override
  String get widthLabel => 'Width';
  @override
  String get designImages => 'Design Images';
  @override
  String get addImageUrl => 'Add Image URL';
  @override
  String get noCollections => 'No collections yet';
  @override
  String get noDesigns => 'No designs yet';
  @override
  String get sortBy => 'Sort by';
  @override
  String get sortPopularity => 'Popularity';
  @override
  String get sortNewest => 'Newest';
  @override
  String get sortPriceLowHigh => 'Price: Low to High';
  @override
  String get sortPriceHighLow => 'Price: High to Low';
  @override
  String get statusLabel => 'Status';

  // ---- Transactions / Orders ----
  @override
  String get orderId => 'Order ID';
  @override
  String get buyer => 'Buyer';
  @override
  String get items => 'Items';
  @override
  String get amount => 'Amount';
  @override
  String get allStatuses => 'All statuses';
  @override
  String get statusCreated => 'Created';
  @override
  String get statusPaid => 'Paid';
  @override
  String get statusFailed => 'Failed';
  @override
  String get statusRefundInitiated => 'Refund Initiated';
  @override
  String get statusRefunded => 'Refunded';
  @override
  String get paymentId => 'Payment ID';
  @override
  String get invoice => 'Invoice';
  @override
  String get timeline => 'Timeline';
  @override
  String get orderPlaced => 'Order placed';
  @override
  String get paidOn => 'Paid';
  @override
  String get refundedOn => 'Refunded';
  @override
  String get subtotal => 'Subtotal';
  @override
  String get platformFee => 'Platform Fee';
  @override
  String get gst => 'GST';
  @override
  String get total => 'Total';
  @override
  String get refund => 'Refund';
  @override
  String get refundOrder => 'Refund Order';
  @override
  String get refundReason => 'Refund Reason';
  @override
  String get refundReasonHint => 'Reason for the refund';
  @override
  String get refundConfirmTitle => 'Refund this order?';
  @override
  String get refundConfirmMessage =>
      'This initiates a refund via the payment gateway. This cannot be undone.';
  @override
  String get refundSuccess => 'Refund initiated successfully';
  @override
  String get refundFailed => 'Refund failed';
  @override
  String get noTransactions => 'No transactions yet';
  @override
  String get filterByStatus => 'Filter by status';
  @override
  String get clearFilters => 'Clear filters';
  @override
  String get selectDateRange => 'Select date range';

  // ---- Dashboard (live) ----
  @override
  String get totalDesigns => 'Total Designs';
  @override
  String get activeDesigns => 'Active Designs';
  @override
  String get pendingDesigns => 'Pending Designs';
  @override
  String get totalDesigners => 'Designers';
  @override
  String get ordersToday => 'Orders Today';
  @override
  String get revenueToday => 'Revenue Today';
  @override
  String get revenueLast7Days => 'Revenue (7 days)';
  @override
  String get totalRevenueAllTime => 'Total Revenue';
  @override
  String get revenueTrend => 'Revenue Trend';
  @override
  String get last7Days => 'Last 7 days';
  @override
  String get retryLabel => 'Retry';

  // ---- Reports ----
  @override
  String get totalSales => 'Total Sales';
  @override
  String get ordersCount => 'Orders';
  @override
  String get averageOrderValue => 'Avg. Order Value';
  @override
  String get newUsers => 'New Users';
  @override
  String get topDesigns => 'Top Designs';
  @override
  String get topCategories => 'Top Categories';
  @override
  String get exportCsv => 'Export CSV';
  @override
  String get exportSalesSummary => 'Export Summary';
  @override
  String get exportLineItems => 'Export Line Items';
  @override
  String get unitsSold => 'Units';
  @override
  String get revenue => 'Revenue';
  @override
  String get exportSuccess => 'Exported successfully';
  @override
  String get exportCopiedToClipboard => 'CSV copied to clipboard';
  @override
  String get noReportData => 'No data for this period';

  // ---- Payouts ----
  @override
  String get designer => 'Designer';
  @override
  String get earningsOwed => 'Earnings Owed';
  @override
  String get totalOwed => 'Total Owed';
  @override
  String get owed => 'Owed';
  @override
  String get grossSales => 'Gross Sales';
  @override
  String get noEarnings => 'No designer earnings yet';
  @override
  String get payoutsInterimNote =>
      'Interim read-only view. Actual payouts arrive with the wallet module.';

  // ---- Platform Fees / Payments settings ----
  @override
  String get platformFeePercent => 'Platform Fee (%)';
  @override
  String get gstPercent => 'GST (%)';
  @override
  String get sellerInfo => 'Seller Info';
  @override
  String get invoicePrefix => 'Invoice Prefix';
  @override
  String get sellerName => 'Seller Name';
  @override
  String get payments => 'Payments';
  @override
  String get paymentMode => 'Payment Mode';
  @override
  String get testMode => 'Test';
  @override
  String get liveMode => 'Live';
  @override
  String get liveModeWarning =>
      'Live mode processes REAL payments. Make sure your live Razorpay keys are correct.';
  @override
  String get razorpayTestKey => 'Razorpay Test Key ID';
  @override
  String get razorpayLiveKey => 'Razorpay Live Key ID';
  @override
  String get razorpayKeyHint => 'rzp_xxx (Key ID only — not the Secret Key)';
  @override
  String get razorpayTestKeyHint => 'rzp_test_xxxxxxxx (Key ID only — not the Secret Key)';
  @override
  String get razorpayLiveKeyHint => 'rzp_live_xxxxxxxx (Key ID only — not the Secret Key)';
  @override
  String get razorpaySecretNote =>
      'The Secret Key is encrypted and stored securely on the server — it is never shown again after saving. You can update it anytime.';
  @override
  String get razorpayTestSecretKey => 'Razorpay Test Secret Key';
  @override
  String get razorpayLiveSecretKey => 'Razorpay Live Secret Key';
  @override
  String get razorpaySecretHint => 'Paste the Key Secret';
  @override
  String get razorpaySecretSavedHint => 'Saved — leave blank to keep current';
  @override
  String get razorpaySecretSaved => 'Secret key saved securely';
  @override
  String get feeValidationError => 'Enter a value between 0 and 100';
  @override
  String get settingsTabGeneral => 'General';
  @override
  String get settingsTabPayments => 'Payments';
  @override
  String get settingsTabNotifications => 'Notifications';
  @override
  String get settingsTabSeed => 'Seed';
  @override
  String get demoData => 'Demo Data';
  @override
  String get notificationSettingsComingSoon =>
      'Notification settings coming soon';

  // ---- Notification settings (admin) ----
  @override
  String get notifications => 'Notifications';
  @override
  String get enablePushNotifications => 'Enable push notifications';
  @override
  String get purchaseAlerts => 'Purchase alerts';
  @override
  String get newDesignAlerts => 'New-design alerts to users';
  @override
  String get dailySendTimes => 'Daily send times (max 4)';
  @override
  String get addSendTime => 'Add send time';
  @override
  String get maxFourSlots => 'You can set up to 4 send times per day.';

  // ---- Broadcast (admin) ----
  @override
  String get sendBroadcast => 'Send broadcast';
  @override
  String get broadcastTitle => 'Title';
  @override
  String get broadcastBody => 'Message';
  @override
  String get sendToAllUsers => 'Send to all users';
  @override
  String get broadcastSent => 'Notification sent to all users';
  @override
  String get broadcastConfirmMessage =>
      'This will send a push notification to every user. Continue?';
  @override
  String get broadcastTitleRequired => 'Title is required';
  @override
  String get broadcastTitleTooLong => 'Title must be 120 characters or fewer';
  @override
  String get broadcastBodyRequired => 'Message is required';

  // ---- Admin notification inbox ----
  @override
  String get markAllRead => 'Mark all read';
  @override
  String get noAdminNotifications => 'No notifications yet';
  @override
  String get adminNotificationsTitle => 'Notifications';
}
