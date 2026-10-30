
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Background message: ${message.messageId}');
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'siagabanjir_alerts',
    'SiagaBanjir Alerts',
    description: 'Notifikasi informasi dan peringatan banjir',
    importance: Importance.max,
  );

  static Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notifikasi ditekan: ${response.payload}');
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_channel);

    // Meminta izin notifikasi.
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Dengarkan FID sebelum melakukan registrasi.
    FirebaseMessaging.instance.onRegistered.listen(
      (installationId) {
        debugPrint('FIREBASE INSTALLATION ID: $installationId');
      },
      onError: (error) {
        debugPrint('Gagal mendapatkan FID: $error');
      },
    );

    await FirebaseMessaging.instance.register();

    // Notifikasi ketika aplikasi sedang terbuka.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;

      if (notification == null) return;

      await _localNotifications.show(
        id: message.hashCode,
        title: notification.title ?? 'SiagaBanjir',
        body: notification.body ?? 'Ada informasi baru.',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    });

    // Ketika aplikasi dibuka melalui notifikasi.
    final initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('Aplikasi dibuka melalui notifikasi.');
    }

    // Ketika notifikasi ditekan saat aplikasi background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Notifikasi dibuka: ${message.messageId}');
    });
  }
}
