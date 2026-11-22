import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:recipemate/core/config/app_config.dart';
import 'package:recipemate/core/models/reminder.dart';
import 'package:recipemate/core/services/firestore_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service central des notifications locales (points 4 et 7).
///
/// La planification est locale : elle fonctionne même hors connexion et quand
/// l'application est fermée. Firestore sert de source de vérité pour
/// l'historique et l'affichage dans « Mes rappels ».
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  static const String _channelId = 'recipemate_reminders';
  static const String _channelName = 'Rappels RecipeMate';
  static const String _channelDescription =
      'Rappels de repas et alertes de péremption des produits';

  /// Initialise le plugin, le fuseau horaire et les canaux Android/iOS.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } on Object {
      debugPrint('Fuseau horaire local indisponible, utilisation de UTC.');
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification ouverte : ${response.payload}');
      },
    );
    _initialized = true;
  }

  /// Point 4 : demande la permission au bon moment, avec un message
  /// explicatif affiché par l'écran avant l'appel.
  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) {
      return false;
    }
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission() ?? false;
      // Android 12+ : autorisation spéciale pour les alarmes exactes.
      await android?.requestExactAlarmsPermission();
      return granted;
    }
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// Planifie une notification à une date précise (même app fermée).
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required bool useExactAlarm,
  }) async {
    await initialize();
    final scheduled = tz.TZDateTime.from(scheduledAt, tz.local);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    var exactAllowed = useExactAlarm;
    if (exactAllowed && !kIsWeb && Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      exactAllowed = await android?.canScheduleExactNotifications() ?? false;
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: id.toString(),
    );
  }

  /// Annule une notification planifiée (point 7).
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }

  /// Identifiant numérique stable dérivé de l'ID Firestore du rappel.
  int notificationId(String reminderId) => reminderId.hashCode & 0x7fffffff;

  /// Crée le rappel dans Firestore ET planifie la notification locale.
  Future<String> createAndSchedule({
    required String uid,
    required ReminderType type,
    required String title,
    required DateTime scheduledAt,
    required String relatedId,
    required FirestoreService firestore,
    bool useExactAlarm = true,
    String? body,
  }) async {
    final reminder = Reminder(
      id: '',
      type: type,
      title: title,
      scheduledAt: scheduledAt,
      relatedId: relatedId,
      status: ReminderStatus.pending,
      createdAt: DateTime.now(),
    );
    final id = await firestore.createReminder(uid, reminder);
    await schedule(
      id: notificationId(id),
      title: title,
      body: body ?? 'Votre rappel RecipeMate est arrivé.',
      scheduledAt: scheduledAt,
      useExactAlarm: useExactAlarm,
    );
    return id;
  }

  /// Point 4a : planifie un rappel de péremption pour un produit du frigo.
  ///
  /// Cette méthode est réutilisable depuis l'écran « Mes rappels » ou depuis
  /// tout produit de `users/{uid}/pantry/{itemId}` disposant d'une
  /// `expiryDate`. Le délai reste centralisé dans [AppConfig].
  Future<String> scheduleExpiryReminder({
    required String uid,
    required String pantryItemId,
    required String productName,
    required DateTime expiryDate,
    required FirestoreService firestore,
  }) {
    final scheduledAt = expiryDate.subtract(
      const Duration(days: AppConfig.expiryReminderLeadDays),
    );
    if (scheduledAt.isBefore(DateTime.now())) {
      throw Exception('La date de péremption est trop proche.');
    }
    return createAndSchedule(
      uid: uid,
      type: ReminderType.expiry,
      title: '$productName va périmer bientôt',
      scheduledAt: scheduledAt,
      relatedId: pantryItemId,
      firestore: firestore,
      useExactAlarm: true,
      body: 'Rappel RecipeMate : $productName va périmer bientôt.',
    );
  }

  /// Annule le rappel côté Firestore et côté planificateur local.
  Future<void> cancelReminder({
    required String uid,
    required String reminderId,
    required FirestoreService firestore,
  }) async {
    await cancel(notificationId(reminderId));
    await firestore.cancelReminder(uid, reminderId);
  }

  /// Marque le rappel comme envoyé (historique, point 4).
  Future<void> markAsSent({
    required String uid,
    required Reminder reminder,
    required FirestoreService firestore,
  }) async {
    await firestore.markReminderSent(uid, reminder.id);
    await initialize();
    await _plugin.show(
      id: notificationId(reminder.id),
      title: reminder.title,
      body: 'Rappel RecipeMate : ${reminder.title}',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
