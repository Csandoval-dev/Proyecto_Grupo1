import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Inicializar notificaciones
  Future<void> initialize() async {
    // Inicializar zona horaria
    tz.initializeTimeZones();

    // Configuración para Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);

    // Solicitar permisos
    await _requestPermissions();
  }

  /// Solicitar permisos
  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// Notificación cuando se crea un hábito
  Future<void> sendHabitCreatedNotification(String habitName) async {
    const androidDetails = AndroidNotificationDetails(
      'habit_created',
      'Hábitos Creados',
      channelDescription: 'Notificaciones cuando se crea un nuevo hábito',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF7E57C2),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🎉 ¡Nuevo hábito creado!',
      '¡Genial! "$habitName" está listo para comenzar. ¡Dale inicio cuando quieras! 💪',
      notificationDetails,
    );
  }

  /// Notificación cuando se inicia un hábito
  Future<void> sendHabitStartedNotification(String habitName) async {
    const androidDetails = AndroidNotificationDetails(
      'habit_started',
      'Hábitos Iniciados',
      channelDescription: 'Notificaciones cuando se inicia un hábito',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🚀 ¡Hábito iniciado!',
      '¡Excelente! Has iniciado "$habitName". Te acompañaré en este journey hacia el éxito 🌟',
      notificationDetails,
    );
  }

  /// Notificación cuando se completa un hábito
  Future<void> sendHabitCompletedNotification(String habitName, int streak) async {
    const androidDetails = AndroidNotificationDetails(
      'habit_completed',
      'Hábitos Completados',
      channelDescription: 'Notificaciones cuando se completa un hábito',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String message = streak > 1
        ? '¡Increíble! Completaste "$habitName" por $streak días seguidos 🔥'
        : '¡Excelente! Completaste "$habitName" hoy 🎉';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '✅ ¡Hábito completado!',
      message,
      notificationDetails,
    );
  }

  /// Notificación de recordatorio diario
  Future<void> sendDailyReminder(String habitName, int pendingHabits) async {
    final androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Recordatorios Diarios',
      channelDescription: 'Recordatorios para completar hábitos',
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFF9800),
      playSound: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    String message = pendingHabits == 1
        ? '¡No olvides completar "$habitName" hoy! 💪'
        : '¡Tienes $pendingHabits hábitos pendientes hoy, incluyendo "$habitName"! ⏰';

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🔔 Recordatorio de hábitos',
      message,
      notificationDetails,
    );
  }

  /// Notificación programada para una fecha y hora específica
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'scheduled_habits',
      'Hábitos Programados',
      channelDescription: 'Recordatorios programados para hábitos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF7E57C2),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      matchDateTimeComponents: null, 
    );
  }

  /// Cancelar una notificación específica
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancelar todas las notificaciones pendientes
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
