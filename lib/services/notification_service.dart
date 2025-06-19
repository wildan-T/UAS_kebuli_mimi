import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kebuli_mimi/services/user_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await _fcm.requestPermission();
  }

  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }
}
