import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Request permission from the user (iOS and Android 13+)
    await _firebaseMessaging.requestPermission();

    // Get the FCM token for this device
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Save the token to the user's profile in Supabase
    if (fcmToken != null) {
      _saveTokenToSupabase(fcmToken);
    }
    
    // Listen for token changes and save the new token
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToSupabase);
    
    // Initialize local notifications for foreground messages
    _initLocalNotifications();

    // Handle incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _showLocalNotification(notification);
      }
    });
  }
  
  void _initLocalNotifications() {
    const androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitializationSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );
    _localNotificationsPlugin.initialize(initializationSettings);
  }

  void _showLocalNotification(RemoteNotification notification) {
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'grocermate_channel', // A unique channel ID
      'GrocerMate Notifications', // A channel name
      channelDescription: 'Notifications for GrocerMate app',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosPlatformChannelSpecifics = DarwinNotificationDetails();
    final platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
    _localNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformChannelSpecifics,
    );
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': token})
            .eq('id', userId);
        print('FCM token saved to Supabase.');
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    }
  }
} 