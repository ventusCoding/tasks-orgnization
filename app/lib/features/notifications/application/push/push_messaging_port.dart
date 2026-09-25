import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// A push message (data + optional visible notification).
@immutable
class PushMessage {
  const PushMessage({this.data = const {}, this.title, this.body, this.messageId});

  factory PushMessage.fromRemote(RemoteMessage m) => PushMessage(
    data: {for (final e in m.data.entries) e.key: e.value?.toString() ?? ''},
    title: m.notification?.title,
    body: m.notification?.body,
    messageId: m.messageId,
  );

  final Map<String, String> data;
  final String? title;
  final String? body;
  final String? messageId;

  /// `sync | reminder | nag | digest | milestone | streak | system | cancel` (T7.4.09).
  String get type => data['type'] ?? 'reminder';
  String? get dedupeKey => data['dk'];
}

/// The only code touching `firebase_messaging` (T7.4.01). Tests use [FakePushMessagingPort].
abstract interface class PushMessagingPort {
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Future<void> deleteToken();
  Stream<PushMessage> get onMessage;
  Stream<PushMessage> get onMessageOpenedApp;
  Future<PushMessage?> getInitialMessage();

  /// iOS foreground presentation (alert/sound off when in-app banners are on).
  Future<void> setForegroundPresentation({required bool alert, required bool badge, required bool sound});
}

/// `firebase_messaging` 16.x implementation. Only created when Firebase is configured and
/// initialized (see `pushAvailableProvider`).
class FirebasePushMessagingPort implements PushMessagingPort {
  FirebasePushMessagingPort([FirebaseMessaging? messaging]) : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<String?> getToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // The APNs token must exist before an FCM token can be minted (T7.4.01).
      final apns = await _messaging.getAPNSToken();
      if (apns == null) return null;
    }
    return _messaging.getToken();
  }

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<void> deleteToken() => _messaging.deleteToken();

  @override
  Stream<PushMessage> get onMessage => FirebaseMessaging.onMessage.map(PushMessage.fromRemote);

  @override
  Stream<PushMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp.map(PushMessage.fromRemote);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final m = await _messaging.getInitialMessage();
    return m == null ? null : PushMessage.fromRemote(m);
  }

  @override
  Future<void> setForegroundPresentation({required bool alert, required bool badge, required bool sound}) =>
      _messaging.setForegroundNotificationPresentationOptions(alert: alert, badge: badge, sound: sound);
}

/// In-memory port for tests.
class FakePushMessagingPort implements PushMessagingPort {
  FakePushMessagingPort({this.token = 'fake-token'});

  String? token;
  bool deleted = false;
  PushMessage? initial;
  ({bool alert, bool badge, bool sound})? presentation;
  final refresh = StreamController<String>.broadcast();
  final messages = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => refresh.stream;

  @override
  Future<void> deleteToken() async {
    deleted = true;
    token = null;
  }

  @override
  Stream<PushMessage> get onMessage => messages.stream;

  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;

  @override
  Future<PushMessage?> getInitialMessage() async => initial;

  @override
  Future<void> setForegroundPresentation({required bool alert, required bool badge, required bool sound}) async =>
      presentation = (alert: alert, badge: badge, sound: sound);
}
