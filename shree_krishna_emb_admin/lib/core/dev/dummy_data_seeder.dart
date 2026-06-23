import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';

/// One-shot seeder that populates Firebase with demo data so the user app's
/// home screen has content. Idempotent: accounts are skipped if the email
/// already exists, and catalog/home docs use fixed ids (re-running overwrites,
/// never duplicates). Admin must be signed in (writes rely on the admin role).
class DummyDataSeeder {
  final FirebaseFirestore firestore;
  DummyDataSeeder({required this.firestore});

  String _img(String seed) => 'https://picsum.photos/seed/$seed/600/600';

  Future<void> seed({required void Function(String) onProgress}) async {
    onProgress('Creating demo accounts…');
    await _seedAccounts();
    onProgress('Creating collections, categories & designs…');
    await _seedCatalog();
    onProgress('Configuring home layout…');
    await _seedHomeConfig();
    onProgress('Done');
  }

  static const List<String> _dummyEmails = [
    'dummy.user@shreekrishna.test',
    'dummy.designer@shreekrishna.test',
  ];

  /// Removes all seeded data: catalog (collections/categories/designs), the
  /// home layout config, and the demo profile docs. NOTE: the two demo Firebase
  /// **Auth** accounts cannot be deleted from the client SDK — remove them from
  /// the Firebase console if needed (their emails are listed in [_dummyEmails]).
  Future<void> clear({required void Function(String) onProgress}) async {
    onProgress('Removing collections, categories & designs…');
    await _clearCatalog();
    onProgress('Removing home layout…');
    await _clearHomeConfig();
    onProgress('Removing demo profiles…');
    await _clearAccountDocs();
    onProgress('Done');
  }

  Future<void> _clearCatalog() async {
    final batch = firestore.batch();
    _catalogData.forEach((collectionId, info) {
      batch.delete(firestore.collection('collections').doc(collectionId));
      for (final catName in info.categories) {
        final categoryId = _categoryId(collectionId, catName);
        batch.delete(firestore.collection('categories').doc(categoryId));
        for (var i = 1; i <= 3; i++) {
          batch.delete(
              firestore.collection('designs').doc(_designId(categoryId, i)));
        }
      }
    });
    await batch.commit();
  }

  Future<void> _clearHomeConfig() async {
    await firestore.collection('config').doc('homeFeed').delete();
  }

  Future<void> _clearAccountDocs() async {
    for (final email in _dummyEmails) {
      final snap = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
  }

  // ---------------- Accounts ----------------
  Future<void> _seedAccounts() async {
    await _createAccount(
      email: 'dummy.user@shreekrishna.test',
      name: 'Demo User',
      role: 'user',
      userId: 9001,
    );
    await _createAccount(
      email: 'dummy.designer@shreekrishna.test',
      name: 'Krishna Studio',
      role: 'designer',
      userId: 9002,
      isAuthorisedSeller: true,
      storeName: 'Krishna Embroidery Studio',
      storeImageUrl: _img('store-krishna'),
      storeDescription: 'Premium hand & machine embroidery designs.',
    );
  }

  Future<void> _createAccount({
    required String email,
    required String name,
    required String role,
    required int userId,
    bool isAuthorisedSeller = false,
    String? storeName,
    String? storeImageUrl,
    String? storeDescription,
  }) async {
    FirebaseApp? app;
    try {
      app = await _secondaryApp();
      final auth = FirebaseAuth.instanceFor(app: app);
      String uid;
      try {
        final cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: 'test123456',
        );
        uid = cred.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Account already exists — sign in with the known demo password to
          // resolve its uid so we can (re)create the profile doc. This keeps
          // re-seeding (e.g. after a Clear) working without duplicate accounts.
          final cred = await auth.signInWithEmailAndPassword(
            email: email,
            password: 'test123456',
          );
          uid = cred.user!.uid;
        } else {
          rethrow;
        }
      }
      // Write the profile via the PRIMARY (admin) session — passes isAdmin().
      await firestore.collection('users').doc(uid).set({
        'id': uid,
        'userId': userId,
        'name': name,
        'email': email,
        'phoneNumber': '+910000000000',
        'role': role,
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'loginMethod': 'email',
        'photoUrl': null,
        'loginAt': null,
        'logoutAt': null,
        'storeName': storeName,
        'storeImageUrl': storeImageUrl,
        'storeDescription': storeDescription,
        'isAuthorisedSeller': isAuthorisedSeller,
      });
      await auth.signOut();
    } catch (e, s) {
      AppLogger.logError('seed account $email', error: e, stackTrace: s);
      rethrow;
    } finally {
      await app?.delete();
    }
  }

  Future<FirebaseApp> _secondaryApp() async {
    const name = 'dummySeeder';
    try {
      return await Firebase.initializeApp(
          name: name, options: Firebase.app().options);
    } on FirebaseException catch (_) {
      return Firebase.app(name);
    }
  }

  // collectionId -> (collection name, [category names]). Shared by seed + clear.
  static const Map<String, ({String name, List<String> categories})>
      _catalogData = {
    'seed_bridal': (name: 'Bridal Collection', categories: ['Saree', 'Lehenga', 'Blouse']),
    'seed_festive': (name: 'Festive Collection', categories: ['Kurti', 'Dupatta', 'Sherwani']),
    'seed_casual': (name: 'Casual Collection', categories: ['T-Shirt', 'Cap', 'Tote Bag']),
  };

  String _categoryId(String collectionId, String catName) =>
      '${collectionId}_${catName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';

  String _designId(String categoryId, int i) => '${categoryId}_d$i';

  // ---------------- Catalog ----------------
  Future<void> _seedCatalog() async {
    final batch = firestore.batch();
    var collPos = 0;
    var popularity = 100;

    _catalogData.forEach((collectionId, info) {
      batch.set(firestore.collection('collections').doc(collectionId), {
        'id': collectionId,
        'name': info.name,
        'description': '${info.name} — handcrafted embroidery designs.',
        'imageUrl': _img(collectionId),
        'ownerId': 'platform',
        'ownerType': 'platform',
        'isActive': true,
        'position': collPos++,
        'designCount': info.categories.length * 3,
        'createdAt': DateTime.now().toIso8601String(),
      });

      var catPos = 0;
      for (final catName in info.categories) {
        final categoryId = _categoryId(collectionId, catName);
        batch.set(firestore.collection('categories').doc(categoryId), {
          'id': categoryId,
          'collectionId': collectionId,
          'name': catName,
          'imageUrl': _img(categoryId),
          'isActive': true,
          'position': catPos++,
          'createdAt': DateTime.now().toIso8601String(),
        });

        for (var i = 1; i <= 3; i++) {
          final designId = _designId(categoryId, i);
          final isFree = i == 1;
          final price = isFree ? 0 : 499 * i;
          final discount = isFree ? 0 : (i == 3 ? 100 : 0);
          final finalPrice = isFree ? 0 : price - discount;
          batch.set(firestore.collection('designs').doc(designId), {
            'id': designId,
            'name': '${info.name.split(' ').first} $catName Design $i',
            'code':
                '${collectionId.substring(5, 8).toUpperCase()}-${catName.substring(0, 2).toUpperCase()}$i',
            'images': [_img('$designId-1'), _img('$designId-2')],
            'authorId': 'platform',
            'authorName': 'Krishna Embroidery Studio',
            'description':
                'A beautiful $catName embroidery design from the ${info.name}.',
            'price': price,
            'discountAmount': discount,
            'isFree': isFree,
            'finalPrice': finalPrice,
            'colorOrNeedleCount': '${5 + i} needle',
            'designFormat': i.isEven ? 'DST' : 'PES',
            'stitchCount': 5000 + i * 2500,
            'height': 100 + i * 10,
            'width': 80 + i * 10,
            'collectionId': collectionId,
            'categoryId': categoryId,
            'status': 'active',
            'popularity': popularity--,
            'createdAt': DateTime.now().toIso8601String(),
          });
        }
      }
    });

    await batch.commit();
  }

  // ---------------- Home layout ----------------
  Future<void> _seedHomeConfig() async {
    final sections = [
      {
        'id': 'seed-banner',
        'type': 'banner',
        'title': null,
        'enabled': true,
        'position': 0,
        'viewAll': {'enabled': false, 'target': null},
        'source': {
          'kind': 'manual',
          'items': [
            {
              'imageUrl': _img('banner-bridal'),
              'label': 'Limited Edition',
              'title': 'Exclusive Bridal Collection',
              'ctaTarget': 'collection:seed_bridal',
            },
            {
              'imageUrl': _img('banner-festive'),
              'label': 'Festive Season',
              'title': 'Festive Embroidery',
              'ctaTarget': 'collection:seed_festive',
            },
            {
              'imageUrl': _img('banner-casual'),
              'label': 'Everyday Style',
              'title': 'Casual Designs',
              'ctaTarget': 'collection:seed_casual',
            },
          ],
        },
      },
      {
        'id': 'seed-sellers',
        'type': 'authorisedSellersHorizontal',
        'title': 'Authorised Sellers',
        'enabled': true,
        'position': 1,
        'viewAll': {'enabled': true, 'target': 'sellers'},
        'source': {'kind': 'authorisedSellers', 'limit': 12},
      },
      {
        'id': 'seed-trending',
        'type': 'designsHorizontal',
        'title': 'Trending Designs',
        'enabled': true,
        'position': 2,
        'viewAll': {'enabled': true, 'target': 'designs?sort=popularity'},
        'source': {
          'kind': 'query',
          'collectionId': null,
          'categoryId': null,
          'sort': 'popularity',
          'onlyActive': true,
          'limit': 10,
        },
      },
      {
        'id': 'seed-collections',
        'type': 'collectionsGrid',
        'title': 'New Collections',
        'enabled': true,
        'position': 3,
        'viewAll': {'enabled': true, 'target': 'collections'},
        'source': {'kind': 'query', 'limit': 8},
      },
    ];

    await firestore.collection('config').doc('homeFeed').set({
      'version': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'updatedAt': DateTime.now().toIso8601String(),
      'sections': sections,
    });
  }
}
