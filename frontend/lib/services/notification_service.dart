import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../main.dart';
import 'browser_notification.dart';
import '../utils/notification_sound.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  IO.Socket? _socket;
  bool _isInitialized = false;

  final ValueNotifier<int> unreadMessagesCount = ValueNotifier<int>(0);
  final ValueNotifier<int> unreadRequestsCount = ValueNotifier<int>(0);
  final ValueNotifier<List<dynamic>> systemNotifications = ValueNotifier([]);

  Future<void> fetchNotifications() async {
    try {
      final notifications = await ApiService().getMyNotifications();
      
      final currentLocalList = List<dynamic>.from(notifications);

      // Inject "Due Today" medications natively into the bell list for Patients
      final user = AuthService().currentUser;
      if (user != null && user.role.name == 'patient') {
        try {
          final meds = await ApiService().getMyMedications(active: true);
          for (var med in meds) {
            currentLocalList.insert(0, {
              'id': 'med_local_${med['id']}',
              'type': 'medication_local',
              'title': 'Rappel Médicament',
              'message': 'Il est temps de prendre votre ${med['medicine_name']} (${med['reminder_times']?.join(", ") ?? ''})',
              'is_read': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
        }
      }

      systemNotifications.value = currentLocalList;
      unreadRequestsCount.value = currentLocalList.where((n) => n['is_read'] == false).length;
    } catch (e) {
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request Web Browser Permissions explicitly first
    requestBrowserNotificationPermission();

    // Initialize Timezone
    tz.initializeTimeZones();

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotification,
    );

    // Create Notification Channels for Android
    await _createNotificationChannels();

    _isInitialized = true;
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel medicationChannel = AndroidNotificationChannel(
      'medication_reminders',
      'Rappels de médicaments',
      description: 'Notifications pour vos prises de médicaments',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
      'alerts',
      'Alertes et Messages',
      description: 'Notifications pour nouveaux messages et demandes',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(medicationChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertsChannel);
  }

  void _onDidReceiveNotification(NotificationResponse response) {
    // Logic to navigate based on payload could be added here
  }

  // --- SOCKET.IO REAL-TIME NOTIFICATIONS ---

  void connectSocket(String userId) {
    if (_socket != null && _socket!.connected) return;

    
    _socket = IO.io(ApiConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'query': {'userId': userId},
    });

    _socket!.onConnect((_) {
    });

    _socket!.onConnectError((err) {
    });

    _socket!.onDisconnect((_) {
    });

    // Listen for NEW unified persistent notifications
    _socket!.on('new_system_notification', (data) {
      
      // Play Ding
      playNotificationSound();
      
      // Update persistent list
      final currentList = List<dynamic>.from(systemNotifications.value);
      currentList.insert(0, data);
      systemNotifications.value = currentList;
      
      // Update global badge
      unreadRequestsCount.value++;
      
      // UI feedback
      showBrowserNotification(data['title'], data['message']);
      _showGlobalSnackBar(data['message']);
      
      // Local App Push
      _showInstantNotification(
        id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: data['title'] ?? 'Nouvelle alerte',
        body: data['message'] ?? '',
        payload: jsonEncode(data),
      );
    });

    // Listen for new messages (strictly for updating chat-specific UI/badge now)
    _socket!.on('new_message', (data) {
      unreadMessagesCount.value++;
    });

    // Listen for medication orders (Pharmacist)
    _socket!.on('new_medication_order', (data) {
      // handled by system notification
    });

    // Listen for lab requests (Laboratory)
    _socket!.on('new_lab_request', (data) {
      // handled by system notification
    });
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket = null;
    unreadMessagesCount.value = 0;
    unreadRequestsCount.value = 0;
  }

  void _showGlobalSnackBar(String message) {
    if (scaffoldMessengerKey.currentState != null) {
      scaffoldMessengerKey.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
          dismissDirection: DismissDirection.up,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: const Color(0xFF1565C0),
        ),
      );
    }
  }

  Future<void> _showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alerts',
      'Alertes et Messages',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  // --- MEDICATION REMINDERS (LOCAL) ---

  Future<void> syncMedicationReminders() async {
    try {
      final user = AuthService().currentUser;
      if (user == null || user.role.name != 'patient') return;

      
      // Cancel all existing scheduled notifications to avoid duplicates/stale data
      await _localNotifications.cancelAll();

      final api = ApiService();
      final medications = await api.getMyMedications(active: true);

      for (var med in medications) {
        final String name = med['medicine_name'] ?? 'Médicament';
        final List<dynamic> times = med['reminder_times'] ?? [];
        
        for (int i = 0; i < times.length; i++) {
          final timeStr = times[i] as String; // e.g., "08:30"
          final parts = timeStr.split(':');
          final int hour = int.parse(parts[0]);
          final int minute = int.parse(parts[1]);

          await _scheduleDailyNotification(
            id: med['id'].hashCode + i,
            title: 'Rappel Médicament',
            body: 'Il est l\'heure de prendre votre $name',
            hour: hour,
            minute: minute,
          );
        }
      }
    } catch (e) {
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Rappels de médicaments',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': 'medication_reminder', 'time': '$hour:$minute'}),
    );
  }
}


