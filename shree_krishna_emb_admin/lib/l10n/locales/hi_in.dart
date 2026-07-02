import 'locale_base.dart';

class HiINStrings implements LocaleStrings {
  @override
  String get appName => 'श्री कृष्ण कढ़ाई - प्रशासन';
  @override
  String get appVersion => 'v1.0.0';

  @override
  String get confirm => 'पुष्टि करें';
  @override
  String get cancel => 'रद्द करें';
  @override
  String get ok => 'ठीक है';
  @override
  String get dismiss => 'खारिज करें';
  @override
  String get back => 'वापस';
  @override
  String get next => 'अगला';
  @override
  String get delete => 'हटाएँ';
  @override
  String get edit => 'संपादित करें';
  @override
  String get save => 'सहेजें';
  @override
  String get retry => 'पुनः प्रयास करें';
  @override
  String get refresh => 'रीफ्रेश करें';
  @override
  String get loading => 'लोड हो रहा है...';
  @override
  String get error => 'त्रुटि';
  @override
  String get success => 'सफल';
  @override
  String get warning => 'चेतावनी';
  @override
  String get info => 'सूचना';
  @override
  String get close => 'बंद करें';
  @override
  String get add => 'जोड़ें';
  @override
  String get create => 'बनाएँ';
  @override
  String get update => 'अपडेट करें';
  @override
  String get view => 'देखें';
  @override
  String get export => 'निर्यात करें';
  @override
  String get import_ => 'आयात करें';
  @override
  String get search => 'खोजें';
  @override
  String get filter => 'फिल्टर करें';
  @override
  String get sort => 'क्रमबद्ध करें';
  @override
  String get settings => 'सेटिंग्स';

  @override
  String get dashboard => 'डैशबोर्ड';
  @override
  String get adminDashboard => 'एडमिन डैशबोर्ड';
  @override
  String get dashboardWelcome => 'प्रशासन डैशबोर्ड में आपका स्वागत है';
  @override
  String get totalOrders => 'कुल ऑर्डर';
  @override
  String get totalRevenue => 'कुल राजस्व';
  @override
  String get totalUsers => 'कुल उपयोगकर्ता';
  @override
  String get totalProducts => 'कुल उत्पाद';
  @override
  String get recentOrders => 'हाल के ऑर्डर';
  @override
  String get recentActivity => 'हाल की गतिविधि';
  @override
  String get newDesign => 'नया डिज़ाइन';
  @override
  String get by => 'द्वारा';
  @override
  String get justNow => 'अभी';
  @override
  String minutesAgo(int minutes) => '$minutes मिनट पहले';
  @override
  String hoursAgo(int hours) => '$hours घंटे पहले';
  @override
  String daysAgo(int days) => '$days दिन पहले';
  @override
  String get analytics => 'विश्लेषण';
  @override
  String get statistics => 'आंकड़े';

  @override
  String get products => 'उत्पाद';
  @override
  String get manageProducts => 'उत्पाद प्रबंधित करें';
  @override
  String get addProduct => 'उत्पाद जोड़ें';
  @override
  String get editProduct => 'उत्पाद संपादित करें';
  @override
  String get productName => 'उत्पाद नाम';
  @override
  String get productDescription => 'विवरण';
  @override
  String get productPrice => 'कीमत';
  @override
  String get productCategory => 'श्रेणी';
  @override
  String get productStock => 'स्टॉक';
  @override
  String get productImage => 'उत्पाद छवि';
  @override
  String get productStatus => 'स्थिति';
  @override
  String get active => 'सक्रिय';
  @override
  String get inactive => 'निष्क्रिय';
  @override
  String get allLabel => 'सभी';
  @override
  String get perPage => 'प्रति पृष्ठ';
  @override
  String get mediaLibrary => 'मीडिया लाइब्रेरी';
  @override
  String get uploadImages => 'अपलोड करें';
  @override
  String get uploading => 'अपलोड हो रहा है';
  @override
  String uploadingPercent(int percent) => 'अपलोड हो रहा है $percent%';
  @override
  String uploadingBatch(int done, int total, int percent) =>
      'अपलोड हो रहा है $done/$total · $percent%';
  @override
  String get dragDropHint =>
      'छवियाँ यहाँ खींचें और छोड़ें, या एक साथ जोड़ने के लिए अपलोड का उपयोग करें।';
  @override
  String get useImage => 'उपयोग करें';
  @override
  String get chooseFromLibrary => 'लाइब्रेरी से चुनें';
  @override
  String get addImage => 'छवि जोड़ें';
  @override
  String get changeImage => 'छवि बदलें';
  @override
  String get uploadFromDevice => 'डिवाइस से अपलोड करें';
  @override
  String get selectFromDevice => 'डिवाइस से चुनें';
  @override
  String get selected => 'चयनित';
  @override
  String get designFiles => 'डिज़ाइन फ़ाइलें';
  @override
  String get designFileLibrary => 'डिज़ाइन फ़ाइल लाइब्रेरी';
  @override
  String get uploadDesignFiles => 'डिज़ाइन फ़ाइलें अपलोड करें';
  @override
  String get addDesignFile => 'फ़ाइल जोड़ें';
  @override
  String get useFile => 'उपयोग करें';
  @override
  String get alsoDeleteCategoriesDesigns =>
      'इसकी श्रेणियाँ और डिज़ाइन भी हटाएँ';
  @override
  String get alsoDeleteDesigns => 'इसके डिज़ाइन भी हटाएँ';
  @override
  String get deleteImpactTitle => 'क्या होगा';
  @override
  String get deleteCollectionOnlyNote =>
      'केवल यह संग्रह हटाया जाएगा। इसकी श्रेणियाँ और डिज़ाइन बने रहेंगे पर असंबद्ध हो '
      'जाएँगे — वे किसी भी संग्रह के अंतर्गत नहीं दिखेंगे, और इस संग्रह से जुड़ा कोई भी '
      'होम सेक्शन खाली दिखेगा।';
  @override
  String get deleteCollectionCascadeNote =>
      'यह संग्रह और इसकी सभी श्रेणियाँ व डिज़ाइन ऐप से स्थायी रूप से हटा दिए जाएँगे। '
      'इसे पूर्ववत नहीं किया जा सकता।';
  @override
  String get deleteCategoryOnlyNote =>
      'केवल यह श्रेणी हटाई जाएगी। इसके डिज़ाइन बने रहेंगे पर असंबद्ध हो जाएँगे — वे किसी '
      'भी श्रेणी के अंतर्गत नहीं दिखेंगे, और इस श्रेणी से जुड़ा कोई भी होम सेक्शन खाली दिखेगा।';
  @override
  String get deleteCategoryCascadeNote =>
      'यह श्रेणी और इसके सभी डिज़ाइन ऐप से स्थायी रूप से हटा दिए जाएँगे। इसे पूर्ववत '
      'नहीं किया जा सकता।';
  @override
  String get noProducts => 'कोई उत्पाद नहीं मिला';
  @override
  String get productAdded => 'उत्पाद सफलतापूर्वक जोड़ा गया';
  @override
  String get productUpdated => 'उत्पाद सफलतापूर्वक अपडेट किया गया';
  @override
  String get productDeleted => 'उत्पाद सफलतापूर्वक हटाया गया';

  @override
  String get orders => 'ऑर्डर';
  @override
  String get manageOrders => 'ऑर्डर प्रबंधित करें';
  @override
  String get orderID => 'ऑर्डर आईडी';
  @override
  String get orderDate => 'ऑर्डर की तारीख';
  @override
  String get orderStatus => 'स्थिति';
  @override
  String get orderTotal => 'कुल';
  @override
  String get orderCustomer => 'ग्राहक';
  @override
  String get orderDetails => 'ऑर्डर विवरण';
  @override
  String get orderItems => 'आइटम';
  @override
  String get shippingAddress => 'शिपिंग पता';
  @override
  String get billingAddress => 'बिलिंग पता';
  @override
  String get paymentMethod => 'भुगतान विधि';
  @override
  String get trackingNumber => 'ट्रैकिंग नंबर';
  @override
  String get pending => 'लंबित';
  @override
  String get processing => 'प्रसंस्करण';
  @override
  String get shipped => 'भेजा गया';
  @override
  String get delivered => 'पहुंचाया गया';
  @override
  String get cancelled => 'रद्द किया गया';
  @override
  String get returned => 'लौटाया गया';
  @override
  String get noOrders => 'कोई ऑर्डर नहीं मिला';
  @override
  String get orderUpdated => 'ऑर्डर सफलतापूर्वक अपडेट किया गया';

  @override
  String get users => 'उपयोगकर्ता';
  @override
  String get manageUsers => 'उपयोगकर्ता प्रबंधित करें';
  @override
  String get userName => 'उपयोगकर्ता नाम';
  @override
  String get userEmail => 'ईमेल';
  @override
  String get userPhone => 'फोन';
  @override
  String get userStatus => 'स्थिति';
  @override
  String get userJoinDate => 'शामिल होने की तारीख';
  @override
  String get userOrders => 'ऑर्डर';
  @override
  String get userDetails => 'उपयोगकर्ता विवरण';
  @override
  String get blockUser => 'उपयोगकर्ता को ब्लॉक करें';
  @override
  String get unblockUser => 'उपयोगकर्ता को अनब्लॉक करें';
  @override
  String get noUsers => 'कोई उपयोगकर्ता नहीं मिला';

  @override
  String get categories => 'श्रेणियाँ';
  @override
  String get manageCategories => 'श्रेणियाँ प्रबंधित करें';
  @override
  String get addCategory => 'श्रेणी जोड़ें';
  @override
  String get categoryName => 'श्रेणी का नाम';
  @override
  String get categoryDescription => 'विवरण';
  @override
  String get categoryImage => 'श्रेणी छवि';
  @override
  String get noCategories => 'कोई श्रेणी नहीं मिली';
  @override
  String get categoryAdded => 'श्रेणी सफलतापूर्वक जोड़ी गई';
  @override
  String get categoryUpdated => 'श्रेणी सफलतापूर्वक अपडेट की गई';
  @override
  String get categoryDeleted => 'श्रेणी सफलतापूर्वक हटाई गई';

  @override
  String get themeConfiguration => 'थीम कॉन्फ़िगरेशन';
  @override
  String get manageTheme => 'ऐप थीम प्रबंधित करें';
  @override
  String get primaryColor => 'प्राथमिक रंग';
  @override
  String get secondaryColor => 'माध्यमिक रंग';
  @override
  String get accentColor => 'अभिव्यक्ति रंग';
  @override
  String get fontFamily => 'फ़ॉन्ट परिवार';
  @override
  String get borderRadius => 'सीमा त्रिज्या';
  @override
  String get spacing => 'रिक्ति';
  @override
  String get darkMode => 'डार्क मोड';
  @override
  String get lightMode => 'लाइट मोड';
  @override
  String get themeUpdated => 'थीम सफलतापूर्वक अपडेट किया गया';
  @override
  String get previewChanges => 'परिवर्तन प्रिव्यू करें';
  @override
  String get applyChanges => 'परिवर्तन लागू करें';

  @override
  String get reports => 'रिपोर्ट';
  @override
  String get generateReport => 'रिपोर्ट बनाएँ';
  @override
  String get salesReport => 'बिक्रय रिपोर्ट';
  @override
  String get userReport => 'उपयोगकर्ता रिपोर्ट';
  @override
  String get inventoryReport => 'इन्वेंटरी रिपोर्ट';
  @override
  String get dateRange => 'तारीख रेंज';
  @override
  String get from => 'से';
  @override
  String get to => 'तक';
  @override
  String get download => 'डाउनलोड करें';
  @override
  String get noData => 'कोई डेटा उपलब्ध नहीं';

  @override
  String get appearance => 'दिखावट';
  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageHindi => 'हिन्दी (Hindi)';
  @override
  String get languageChanged => 'भाषा बदल दी गई';

  @override
  String get adminPanel => 'एडमिन पैनल';
  @override
  String get approvalQueue => 'अनुमोदन कतार';
  @override
  String get designStore => 'डिज़ाइन स्टोर';
  @override
  String get userManagement => 'उपयोगकर्ता प्रबंधन';
  @override
  String get transactions => 'लेन-देन';
  @override
  String get platformFees => 'प्लेटफ़ॉर्म शुल्क';
  @override
  String get payouts => 'भुगतान';
  @override
  String get support => 'सहायता';
  @override
  String get searchPlaceholder => 'डिज़ाइनर, डिज़ाइन या लेन-देन खोजें...';
  @override
  String get insightsTitle => 'श्री कृष्ण इनसाइट्स';
  @override
  String get approvedDesigns => 'अनुमोदित डिज़ाइन';

  @override
  String get appSettings => 'ऐप सेटिंग्स';
  @override
  String get generalSettings => 'सामान्य सेटिंग्स';
  @override
  String get securitySettings => 'सुरक्षा सेटिंग्स';
  @override
  String get notificationSettings => 'सूचना सेटिंग्स';
  @override
  String get emailNotifications => 'ईमेल सूचनाएँ';
  @override
  String get pushNotifications => 'पुश सूचनाएँ';
  @override
  String get currency => 'मुद्रा';
  @override
  String get timezone => 'समय क्षेत्र';
  @override
  String get language => 'भाषा';
  @override
  String get settingsSaved => 'सेटिंग्स सफलतापूर्वक सहेजी गई';

  @override
  String get fieldRequired => 'यह फील्ड आवश्यक है';
  @override
  String get invalidEmail => 'कृपया एक वैध ईमेल दर्ज करें';
  @override
  String get invalidPhone => 'कृपया एक वैध फोन नंबर दर्ज करें';
  @override
  String get invalidPrice => 'कृपया एक वैध कीमत दर्ज करें';
  @override
  String get invalidQuantity => 'कृपया एक वैध मात्रा दर्ज करें';
  @override
  String get serverError => 'सर्वर त्रुटि। कृपया पुनः प्रयास करें';
  @override
  String get unknownError => 'एक अज्ञात त्रुटि हुई';
  @override
  String get networkError => 'नेटवर्क त्रुटि। अपना कनेक्शन जांचें';

  @override
  String get confirmDelete => 'क्या आप निश्चित हैं?';
  @override
  String get confirmDeleteMessage => 'यह कार्रवाई पूर्ववत नहीं की जा सकती।';
  @override
  String get deleteSuccess => 'सफलतापूर्वक हटाया गया';
  @override
  String get deleteError => 'हटाने में विफल। कृपया पुनः प्रयास करें';

  @override
  String get logout => 'लॉगआउट करें';
  @override
  String get logoutConfirmTitle => 'लॉगआउट करें?';
  @override
  String get logoutConfirmMessage =>
      'एडमिन पैनल तक पहुँचने के लिए आपको फिर से साइन इन करना होगा।';
  @override
  String get login => 'लॉगिन करें';
  @override
  String get email => 'ईमेल';
  @override
  String get password => 'पासवर्ड';
  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';
  @override
  String get resetPassword => 'पासवर्ड रीसेट करें';
  @override
  String get changePassword => 'पासवर्ड बदलें';
  @override
  String get profile => 'प्रोफाइल';
  @override
  String get editProfile => 'प्रोफाइल संपादित करें';
  @override
  String get aboutUs => 'हमारे बारे में';
  @override
  String get contactSupport => 'समर्थन से संपर्क करें';
  @override
  String get help => 'मदद';
  @override
  String get documentation => 'प्रलेखन';

  @override
  String get splashTitle => 'श्री कृष्ण कढ़ाई';
  @override
  String get splashWelcomeTo => 'में आपका स्वागत है';
  @override
  String get splashTagline => 'आसानी से अपने कढ़ाई व्यवसाय का प्रबंधन करें';
  @override
  String get splashInitializing => 'प्रारंभ किया जा रहा है...';
  @override
  String get madeWithLove => 'द्वारा बनाया गया';
  @override
  String get byNicentra => 'Nicentra';

  @override
  String get adminLoginTitle => 'श्री कृष्ण कढ़ाई';
  @override
  String get adminLoginSubtitle => 'अपने कढ़ाई साम्राज्य को संभालें';
  @override
  String get adminLoginDescription =>
      'एडमिन डैशबोर्ड एक्सेस करने के लिए साइन इन करें';
  @override
  String get adminLoginTagline =>
      'ऑपरेशन को सुव्यवस्थित करें, ऑर्डर ट्रैक करें, और हमारे शक्तिशाली एडमिन डैशबोर्ड के साथ अपने कढ़ाई व्यवसाय को बढ़ाएं।';
  @override
  String get adminLoginWelcome => 'स्वागत है एडमिन';
  @override
  String get adminEmail => 'एडमिन ईमेल';
  @override
  String get adminPassword => 'एडमिन पासवर्ड';
  @override
  String get adminPasswordHint => 'अपना पासवर्ड दर्ज करें';
  @override
  String get adminRememberMe => 'मुझे याद रखें';
  @override
  String get adminWelcomeSuccess => 'स्वागत है एडमिन!';
  @override
  String get adminForgotPassword => 'पासवर्ड भूल गए?';
  @override
  String get adminSignIn => 'साइन इन करें';
  @override
  String get adminCopyright => '© 2026 श्री कृष्ण कढ़ाई। सर्वाधिकार सुरक्षित।';

  @override
  String get enterYourEmail => 'अपना ईमेल पता दर्ज करें';
  @override
  String get resetLinkMessage =>
      'हम आपको पासवर्ड रीसेट करने के लिए एक लिंक भेजेंगे';
  @override
  String get sendResetLink => 'रीसेट लिंक भेजें';
  @override
  String get resetLinkSentMessage => 'रीसेट लिंक ईमेल पर भेजा गया';

  // ========== Design Store ==========
  @override
  String get collections => 'संग्रह';
  @override
  String get designs => 'डिज़ाइन';
  @override
  String get homeLayout => 'होम लेआउट';
  @override
  String get addSection => 'सेक्शन जोड़ें';
  @override
  String get addSectionSubtitle =>
      'होम स्क्रीन में जोड़ने के लिए एक ब्लॉक चुनें';
  @override
  String get publish => 'प्रकाशित करें';
  @override
  String get publishNow => 'अभी प्रकाशित करें';
  @override
  String get published => 'प्रकाशित';
  @override
  String get unpublishedChanges => 'अप्रकाशित बदलाव';
  @override
  String get unpublishedBannerMessage =>
      'आपके पास अप्रकाशित बदलाव हैं। प्रकाशित करने तक वे ऐप में लाइव नहीं होंगे।';
  @override
  String get addCollection => 'संग्रह जोड़ें';
  @override
  String get addDesign => 'डिज़ाइन जोड़ें';
  @override
  String get editCollection => 'संग्रह संपादित करें';
  @override
  String get editCategory => 'श्रेणी संपादित करें';
  @override
  String get editDesign => 'डिज़ाइन संपादित करें';
  @override
  String get collectionName => 'संग्रह नाम';
  @override
  String get designName => 'डिज़ाइन नाम';
  @override
  String get imageUrl => 'छवि URL';
  @override
  String get descriptionLabel => 'विवरण';
  @override
  String get positionLabel => 'स्थिति';
  @override
  String get isActiveLabel => 'सक्रिय';
  @override
  String get selectCollection => 'संग्रह चुनें';
  @override
  String get selectCategory => 'श्रेणी चुनें';
  @override
  String get code => 'कोड';
  @override
  String get authorName => 'लेखक का नाम';
  @override
  String get price => 'मूल्य';
  @override
  String get discountAmount => 'छूट राशि';
  @override
  String get isFree => 'निःशुल्क डिज़ाइन';
  @override
  String get finalPrice => 'अंतिम मूल्य';
  @override
  String get free => 'निःशुल्क';
  @override
  String get colorOrNeedleCount => 'रंग / सुई गिनती';
  @override
  String get designFormat => 'डिज़ाइन प्रारूप';
  @override
  String get stitchCount => 'टांके की संख्या';
  @override
  String get heightLabel => 'ऊंचाई';
  @override
  String get widthLabel => 'चौड़ाई';
  @override
  String get designImages => 'डिज़ाइन छवियाँ';
  @override
  String get addImageUrl => 'छवि URL जोड़ें';
  @override
  String get noCollections => 'अभी तक कोई संग्रह नहीं';
  @override
  String get noDesigns => 'अभी तक कोई डिज़ाइन नहीं';
  @override
  String get sortBy => 'क्रमबद्ध करें';
  @override
  String get sortPopularity => 'लोकप्रियता';
  @override
  String get sortNewest => 'नवीनतम';
  @override
  String get sortPriceLowHigh => 'मूल्य: कम से अधिक';
  @override
  String get sortPriceHighLow => 'मूल्य: अधिक से कम';
  @override
  String get statusLabel => 'स्थिति';

  // ---- Transactions / Orders ----
  @override
  String get orderId => 'ऑर्डर आईडी';
  @override
  String get buyer => 'खरीदार';
  @override
  String get items => 'आइटम';
  @override
  String get amount => 'राशि';
  @override
  String get allStatuses => 'सभी स्थितियाँ';
  @override
  String get statusCreated => 'बनाया गया';
  @override
  String get statusPaid => 'भुगतान किया';
  @override
  String get statusFailed => 'विफल';
  @override
  String get statusRefundInitiated => 'रिफंड शुरू';
  @override
  String get statusRefunded => 'रिफंड किया गया';
  @override
  String get paymentId => 'भुगतान आईडी';
  @override
  String get invoice => 'चालान';
  @override
  String get timeline => 'समयरेखा';
  @override
  String get orderPlaced => 'ऑर्डर दिया गया';
  @override
  String get paidOn => 'भुगतान';
  @override
  String get refundedOn => 'रिफंड';
  @override
  String get subtotal => 'उप-योग';
  @override
  String get platformFee => 'प्लेटफ़ॉर्म शुल्क';
  @override
  String get gst => 'जीएसटी';
  @override
  String get total => 'कुल';
  @override
  String get refund => 'रिफंड';
  @override
  String get refundOrder => 'ऑर्डर रिफंड करें';
  @override
  String get refundReason => 'रिफंड का कारण';
  @override
  String get refundReasonHint => 'रिफंड का कारण';
  @override
  String get refundConfirmTitle => 'इस ऑर्डर को रिफंड करें?';
  @override
  String get refundConfirmMessage =>
      'यह भुगतान गेटवे के माध्यम से रिफंड शुरू करता है। इसे पूर्ववत नहीं किया जा सकता।';
  @override
  String get refundSuccess => 'रिफंड सफलतापूर्वक शुरू हुआ';
  @override
  String get refundFailed => 'रिफंड विफल';
  @override
  String get noTransactions => 'अभी तक कोई लेन-देन नहीं';
  @override
  String get filterByStatus => 'स्थिति के अनुसार फ़िल्टर करें';
  @override
  String get clearFilters => 'फ़िल्टर साफ़ करें';
  @override
  String get selectDateRange => 'दिनांक सीमा चुनें';

  // ---- Dashboard (live) ----
  @override
  String get totalDesigns => 'कुल डिज़ाइन';
  @override
  String get activeDesigns => 'सक्रिय डिज़ाइन';
  @override
  String get pendingDesigns => 'लंबित डिज़ाइन';
  @override
  String get totalDesigners => 'डिज़ाइनर';
  @override
  String get ordersToday => 'आज के ऑर्डर';
  @override
  String get revenueToday => 'आज की आय';
  @override
  String get revenueLast7Days => 'आय (7 दिन)';
  @override
  String get totalRevenueAllTime => 'कुल आय';
  @override
  String get revenueTrend => 'आय रुझान';
  @override
  String get last7Days => 'पिछले 7 दिन';
  @override
  String get retryLabel => 'पुनः प्रयास करें';

  // ---- Reports ----
  @override
  String get totalSales => 'कुल बिक्री';
  @override
  String get ordersCount => 'ऑर्डर';
  @override
  String get averageOrderValue => 'औसत ऑर्डर मूल्य';
  @override
  String get newUsers => 'नए उपयोगकर्ता';
  @override
  String get topDesigns => 'शीर्ष डिज़ाइन';
  @override
  String get topCategories => 'शीर्ष श्रेणियाँ';
  @override
  String get exportCsv => 'CSV निर्यात करें';
  @override
  String get exportSalesSummary => 'सारांश निर्यात करें';
  @override
  String get exportLineItems => 'लाइन आइटम निर्यात करें';
  @override
  String get unitsSold => 'इकाइयाँ';
  @override
  String get revenue => 'आय';
  @override
  String get exportSuccess => 'सफलतापूर्वक निर्यात किया गया';
  @override
  String get exportCopiedToClipboard => 'CSV क्लिपबोर्ड पर कॉपी किया गया';
  @override
  String get noReportData => 'इस अवधि के लिए कोई डेटा नहीं';

  // ---- Payouts ----
  @override
  String get designer => 'डिज़ाइनर';
  @override
  String get earningsOwed => 'देय आय';
  @override
  String get totalOwed => 'कुल देय';
  @override
  String get owed => 'देय';
  @override
  String get grossSales => 'सकल बिक्री';
  @override
  String get noEarnings => 'अभी तक कोई डिज़ाइनर आय नहीं';
  @override
  String get payoutsInterimNote =>
      'अंतरिम केवल-पढ़ने योग्य दृश्य। वास्तविक भुगतान वॉलेट मॉड्यूल के साथ आएँगे।';

  // ---- Platform Fees / Payments settings ----
  @override
  String get platformFeePercent => 'प्लेटफ़ॉर्म शुल्क (%)';
  @override
  String get gstPercent => 'जीएसटी (%)';
  @override
  String get sellerInfo => 'विक्रेता जानकारी';
  @override
  String get invoicePrefix => 'चालान उपसर्ग';
  @override
  String get sellerName => 'विक्रेता का नाम';
  @override
  String get payments => 'भुगतान';
  @override
  String get paymentMode => 'भुगतान मोड';
  @override
  String get testMode => 'टेस्ट';
  @override
  String get liveMode => 'लाइव';
  @override
  String get liveModeWarning =>
      'लाइव मोड वास्तविक भुगतान संसाधित करता है। सुनिश्चित करें कि आपकी लाइव Razorpay कुंजियाँ सही हैं।';
  @override
  String get razorpayTestKey => 'Razorpay टेस्ट कुंजी आईडी';
  @override
  String get razorpayLiveKey => 'Razorpay लाइव कुंजी आईडी';
  @override
  String get razorpayKeyHint => 'rzp_xxx (केवल Key ID — सीक्रेट की नहीं)';
  @override
  String get razorpayTestKeyHint => 'rzp_test_xxxxxxxx (केवल Key ID — सीक्रेट की नहीं)';
  @override
  String get razorpayLiveKeyHint => 'rzp_live_xxxxxxxx (केवल Key ID — सीक्रेट की नहीं)';
  @override
  String get razorpaySecretNote =>
      'सीक्रेट की एन्क्रिप्ट करके सर्वर पर सुरक्षित रूप से संग्रहीत होती है — सेव करने के बाद यह दोबारा नहीं दिखाई जाती। आप इसे कभी भी अपडेट कर सकते हैं।';
  @override
  String get razorpayTestSecretKey => 'Razorpay टेस्ट सीक्रेट की';
  @override
  String get razorpayLiveSecretKey => 'Razorpay लाइव सीक्रेट की';
  @override
  String get razorpaySecretHint => 'Key Secret पेस्ट करें';
  @override
  String get razorpaySecretSavedHint =>
      'सेव किया गया — मौजूदा रखने के लिए खाली छोड़ें';
  @override
  String get razorpaySecretSaved => 'सीक्रेट की सुरक्षित रूप से सेव हो गई';
  @override
  String get feeValidationError => '0 और 100 के बीच मान दर्ज करें';
  @override
  String get settingsTabGeneral => 'सामान्य';
  @override
  String get settingsTabPayments => 'भुगतान';
  @override
  String get settingsTabNotifications => 'सूचनाएँ';
  @override
  String get settingsTabSeed => 'सीड';
  @override
  String get demoData => 'डेमो डेटा';
  @override
  String get notificationSettingsComingSoon => 'सूचना सेटिंग्स जल्द आ रही हैं';

  // ---- Notification settings (admin) ----
  @override
  String get notifications => 'सूचनाएं';
  @override
  String get enablePushNotifications => 'पुश सूचनाएं सक्षम करें';
  @override
  String get purchaseAlerts => 'खरीद अलर्ट';
  @override
  String get newDesignAlerts => 'उपयोगकर्ताओं को नई डिज़ाइन अलर्ट';
  @override
  String get dailySendTimes => 'दैनिक भेजने का समय (अधिकतम 4)';
  @override
  String get addSendTime => 'समय जोड़ें';
  @override
  String get maxFourSlots => 'आप प्रतिदिन 4 समय तक सेट कर सकते हैं।';

  // ---- Broadcast (admin) ----
  @override
  String get sendBroadcast => 'ब्रॉडकास्ट भेजें';
  @override
  String get broadcastTitle => 'शीर्षक';
  @override
  String get broadcastBody => 'संदेश';
  @override
  String get sendToAllUsers => 'सभी उपयोगकर्ताओं को भेजें';
  @override
  String get broadcastSent => 'सभी उपयोगकर्ताओं को सूचना भेजी गई';

  // ---- Admin notification inbox ----
  @override
  String get markAllRead => 'सभी पढ़ी हुई चिह्नित करें';
  @override
  String get noAdminNotifications => 'अभी कोई सूचना नहीं';
}
