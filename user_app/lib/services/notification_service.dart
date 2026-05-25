import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/shared/requests_screen.dart';

class NotificationService {
  NotificationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _requestsChannel =
      AndroidNotificationChannel(
    'blood_connect_requests',
    'Blood Requests',
    description: 'Notifications for blood requests and request status updates.',
    importance: Importance.high,
  );

  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  static StreamSubscription<RemoteMessage>? _messageOpenedSub;
  static String? _initializedUid;

  static Future<void> initializeApp() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationPayload(response.payload);
      },
    );

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidNotifications?.createNotificationChannel(_requestsChannel);
    await androidNotifications?.requestNotificationsPermission();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _foregroundMessageSub ??=
        FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _messageOpenedSub ??=
        FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessageTap);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleRemoteMessageTap(initialMessage);
      });
    }
  }

  static Future<void> initializeForUser(String uid) async {
    if (_initializedUid == uid) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    _initializedUid = uid;

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(uid, token);
    }

    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(
      (token) => _saveToken(uid, token),
    );
  }

  static Future<void> setNotificationsEnabled(
    String uid,
    bool enabled,
  ) async {
    await _db.collection('users').doc(uid).set({
      'notificationsEnabled': enabled,
    }, SetOptions(merge: true));

    if (enabled) {
      await initializeForUser(uid);
    } else {
      await removeCurrentToken(uid);
    }
  }

  static Future<void> removeCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await _db.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayRemove([token]),
    }, SetOptions(merge: true));

    if (_initializedUid == uid) {
      _initializedUid = null;
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;
    }
  }

  static Future<void> _saveToken(String uid, String token) async {
    await _db.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'notificationTokenUpdatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? _fallbackTitle(message);
    final body = notification?.body ?? _fallbackBody(message);

    await _localNotifications.show(
      message.messageId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _requestsChannel.id,
          _requestsChannel.name,
          channelDescription: _requestsChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: _payloadFromData(message.data),
    );
  }

  static String _fallbackTitle(RemoteMessage message) {
    switch (message.data['type']) {
      case 'request_created':
        return 'New blood request';
      case 'request_status_changed':
        return 'Blood request updated';
      default:
        return 'Blood Connect';
    }
  }

  static String _fallbackBody(RemoteMessage message) {
    final status = message.data['status'];
    if (status != null && status.toString().isNotEmpty) {
      return 'Request status is now $status.';
    }
    return 'Open Blood Connect to view the latest update.';
  }

  static void _handleRemoteMessageTap(RemoteMessage message) {
    _routeFromNotificationData(message.data);
  }

  static String _payloadFromData(Map<String, dynamic> data) {
    return [
      data['type'] ?? '',
      data['requestId'] ?? '',
      data['status'] ?? '',
    ].join('|');
  }

  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;

    final parts = payload.split('|');
    _routeFromNotificationData({
      'type': parts.isNotEmpty ? parts[0] : '',
      'requestId': parts.length > 1 ? parts[1] : '',
      'status': parts.length > 2 ? parts[2] : '',
    });
  }

  static void _routeFromNotificationData(Map<String, dynamic> data) {
    final type = data['type'];
    final isForDonor = type == 'request_created';
    final isForRecipient = type == 'request_status_changed';
    if (!isForDonor && !isForRecipient) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => RequestsScreen(isForDonor: isForDonor),
      ),
    );
  }
}
