import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';
import 'package:shree_krishna_emb_admin/data/models/home_feed_config_model.dart';

abstract class HomeConfigDataSource {
  Future<HomeFeedConfig> read();
  Future<void> save(HomeFeedConfig config);
}

class FirebaseHomeConfigDataSource implements HomeConfigDataSource {
  final FirebaseFirestore _firestore;

  FirebaseHomeConfigDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  DocumentReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('config').doc('homeFeed');

  @override
  Future<HomeFeedConfig> read() async {
    try {
      final doc = await _ref.get();
      if (!doc.exists || doc.data() == null) {
        // Not persisted yet — present the default layout for editing.
        return HomeFeedConfig.defaultConfig();
      }
      return HomeFeedConfig.fromFirebaseJson(doc.data()!);
    } on FirebaseException catch (e, s) {
      AppLogger.logError('readHomeConfig', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to load home layout');
    } catch (e, s) {
      AppLogger.logError('readHomeConfig', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> save(HomeFeedConfig config) async {
    try {
      // Bump version so the user app can detect a layout change.
      final next = config.copyWith(version: config.version + 1);
      await _ref.set(next.toFirebaseJson());
    } on FirebaseException catch (e, s) {
      AppLogger.logError('saveHomeConfig', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to save home layout');
    } catch (e, s) {
      AppLogger.logError('saveHomeConfig', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
