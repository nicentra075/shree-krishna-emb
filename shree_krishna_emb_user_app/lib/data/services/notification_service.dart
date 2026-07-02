import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/utils/global_navigator.dart';
import '../../domain/repositories/fcm_token_repository.dart';
import '../../routes/app_routes.dart';

/// Background/terminated FCM handler. Must be a top-level function so it can
/// be used as a Dart isolate entry point.
///
/// Data-only messages arriving while the app is backgrounded/terminated are
/// handled here; nothing to do beyond letting the OS display the
/// notification. Tap-through routing is handled by `onMessageOpenedApp`
/// (app was backgrounded) and `getInitialMessage` (app was terminated), both
/// wired up by [NotificationService].
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty: no work needed for background data messages.
}

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'ske_default_channel',
  'General',
  description: 'General notifications',
  importance: Importance.high,
);

/// Owns the FCM lifecycle (permissions, token registration/refresh, topic
/// subscription) and routes notification taps to the right screen via
/// [GlobalNavigator] + [AppRoutes].
class NotificationService {
  NotificationService({required this.tokenRepository});

  final FcmTokenRepository tokenRepository;

  static const String topicAllUsers = 'all_users';

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Pure: which design (if any) a notification payload should open.
  /// No Firebase/platform dependency so it is unit-testable in isolation.
  static String? routeTargetFromData(Map<String, dynamic> data) {
    final id = data['designId'];
    return (id is String && id.isNotEmpty) ? id : null;
  }

  /// Sets up local-notification display + foreground/background tap
  /// listeners. Call once during app startup.
  Future<void> init() async {
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _routeFromPayload(response.payload),
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _route(message.data);
    });
  }

  /// Call once auth + navigator are ready, to cover the terminated-tap case
  /// (app launched by tapping a notification while fully closed).
  Future<void> consumeInitialMessage() async {
    final initial = await _fm.getInitialMessage();
    if (initial != null) _route(initial.data);
  }

  /// Registers this device for push after a successful login.
  ///
  /// Deliberately does NOT call [consumeInitialMessage] here: on a
  /// terminated-app launch, onLogin runs while the splash screen still owns
  /// the navigator, so a route pushed here would be wiped out when splash
  /// completes and clears the stack via `pushNamedAndRemoveUntil`. The home
  /// screen (`MainScreen`) calls [consumeInitialMessage] itself once it is
  /// mounted, so the deep-linked route survives.
  Future<void> onLogin(String uid) async {
    try {
      await _fm.requestPermission();

      final token = await _fm.getToken();
      if (token != null) {
        await tokenRepository.register(uid, token, _platform());
      }

      _fm.onTokenRefresh.listen((refreshedToken) {
        tokenRepository.register(uid, refreshedToken, _platform());
      });

      await _fm.subscribeToTopic(topicAllUsers);
    } catch (_) {
      // Non-fatal: push setup should never block login. getToken() in
      // particular can throw on web without a configured VAPID key.
    }
  }

  /// Cleans up push registration on logout.
  Future<void> onLogout(String uid) async {
    try {
      final token = await _fm.getToken();
      if (token != null) await tokenRepository.remove(uid, token);
      await _fm.unsubscribeFromTopic(topicAllUsers);
      await _fm.deleteToken();
    } catch (_) {
      // Non-fatal: logout should proceed regardless of push cleanup outcome.
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String?;
    final body = notification?.body ?? message.data['body'] as String?;

    await _local.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: routeTargetFromData(message.data),
    );
  }

  void _routeFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    final context = GlobalNavigator.context;
    if (context != null) {
      AppRoutes.navigateToDesignDetail(context, payload);
    }
  }

  void _route(Map<String, dynamic> data) {
    final designId = routeTargetFromData(data);
    if (designId == null) return;
    final context = GlobalNavigator.context;
    if (context != null) {
      AppRoutes.navigateToDesignDetail(context, designId);
    }
  }

  String _platform() => kIsWeb ? 'web' : defaultTargetPlatform.name;
}
