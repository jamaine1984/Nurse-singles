import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

/// Provides the singleton [PushNotificationService] instance.
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(
    messaging: FirebaseMessaging.instance,
    firestore: FirebaseFirestore.instance,
  );
});

/// Firebase Cloud Messaging (FCM) service for push notifications.
///
/// Handles permission requests, token management, and foreground / background
/// message streams.
class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  bool _initialized = false;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  // ─── Initialization ──────────────────────────────────────────────────

  /// Initializes notifications: requests permission, fetches the FCM token,
  /// and sets up foreground / background listeners.
  ///
  /// Call once after Firebase has been initialized.
  Future<void> initNotifications() async {
    try {
      // Request permission (iOS / web; Android auto-grants by default)
      await requestPermission();

      // Configure foreground notification presentation (iOS)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen to token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[PushNotifications] Token refreshed: $newToken');
      });

      _initialized = true;
      debugPrint('[PushNotifications] Initialized');
    } catch (e) {
      debugPrint('[PushNotifications] Init error: $e');
    }
  }

  // ─── Permission ──────────────────────────────────────────────────────

  /// Requests notification permission from the user.
  ///
  /// Returns `true` if authorized or provisional.
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final authorized =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint(
          '[PushNotifications] Permission: ${settings.authorizationStatus}');
      return authorized;
    } catch (e) {
      debugPrint('[PushNotifications] Permission error: $e');
      return false;
    }
  }

  // ─── Token ───────────────────────────────────────────────────────────

  /// Returns the current FCM registration token, or `null` if unavailable.
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[PushNotifications] Token: $token');
      return token;
    } catch (e) {
      debugPrint('[PushNotifications] getToken error: $e');
      return null;
    }
  }

  /// Persists the FCM token to the user's Firestore document so the backend
  /// can send targeted push notifications.
  Future<void> saveTokenToFirestore(String userId) async {
    try {
      final token = await getToken();
      if (token == null) return;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'fcmToken': token});

      debugPrint('[PushNotifications] Token saved for user $userId');
    } catch (e) {
      debugPrint('[PushNotifications] saveToken error: $e');
    }
  }

  // ─── Message Streams ─────────────────────────────────────────────────

  /// Stream of [RemoteMessage] received while the app is in the **foreground**.
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  /// Stream of [RemoteMessage] that the user tapped to open the app from a
  /// **background** state (not terminated).
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  /// Returns the [RemoteMessage] that launched the app from a **terminated**
  /// state, if any.
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  // ─── Topic Subscriptions ─────────────────────────────────────────────

  /// Subscribes the device to a named topic for broadcast notifications.
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('[PushNotifications] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[PushNotifications] subscribeToTopic error: $e');
    }
  }

  /// Unsubscribes the device from a topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('[PushNotifications] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[PushNotifications] unsubscribeFromTopic error: $e');
    }
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────

  /// Removes the FCM token from Firestore (call on sign-out).
  Future<void> removeTokenFromFirestore(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'fcmToken': FieldValue.delete()});

      debugPrint('[PushNotifications] Token removed for user $userId');
    } catch (e) {
      debugPrint('[PushNotifications] removeToken error: $e');
    }
  }

  /// Deletes the local FCM token.
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('[PushNotifications] Token deleted');
    } catch (e) {
      debugPrint('[PushNotifications] deleteToken error: $e');
    }
  }
}
