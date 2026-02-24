import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String? token;
  RemoteMessage? _lastMessage; // لتخزين آخر رسالة
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _initFCM();
    _listenToMessages();
  }

  void _initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. طلب إذن الإشعارات
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint("إذن الإشعارات: ${settings.authorizationStatus}");

    // 2. الحصول على التوكن
    try {
      String? fcmToken = await messaging.getToken();
      if (fcmToken != null && mounted) {
        setState(() {
          token = fcmToken;
        });
        debugPrint("FCM Token: $token");

        // 3. إرسال التوكن للـ Laravel
        await _sendTokenToServer(fcmToken);
      }
    } catch (e) {
      debugPrint("خطأ في جلب التوكن: $e");
    }
  }

  // دالة الاستماع للرسائل
  void _listenToMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;

      debugPrint("رسالة جديدة: ${message.notification?.title}");
      setState(() {
        _lastMessage = message;
      });
    });
  }

  Future<void> _sendTokenToServer(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse("https://60e573cbec47e8.lhr.life/api/update-fcm-token"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "fcm_token": fcmToken,
          "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjFjMzIxOTgzNGRhNTBlMjBmYWVhZWE3Yzg2Y2U3YjU1MzhmMTdiZTEiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vcmVwb3J0cy1hcHAtZGMwNDYiLCJhdWQiOiJyZXBvcnRzLWFwcC1kYzA0NiIsImF1dGhfdGltZSI6MTc2OTQ1ODE5NSwidXNlcl9pZCI6IlJ3cG1Qb3ZQdHpSU1Jhc25CQ2ZMcU5WOTFxdjIiLCJzdWIiOiJSd3BtUG92UHR6UlNSYXNuQkNmTHFOVjkxcXYyIiwiaWF0IjoxNzY5NDU4MTk1LCJleHAiOjE3Njk0NjE3OTUsImVtYWlsIjoiYXNvam9icmFuM0BnbWFpbC5jb20iLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsImZpcmViYXNlIjp7ImlkZW50aXRpZXMiOnsiZW1haWwiOlsiYXNvam9icmFuM0BnbWFpbC5jb20iXX0sInNpZ25faW5fcHJvdmlkZXIiOiJwYXNzd29yZCJ9fQ.Biiqzul_GPgu4xc8JKyY7LrmFCfhMmcaKX2zmlrGblMc9qsxaHucKw54J8DaBLViROfgwsIGENW26A9HJAldWZ27UDYEUJudN4nkUif7PC59_-NZ-SMdZWiCwUq5Jd6YaC8Ej5PqS_HERXluUkqSxn7M5hUtXxaYRw6QaQeNm6EmdK4HrYhntjHvN8PpMllmZmf2HjqI8ALiaj1aXTYfiX5EcvNeNimlzEgE_qDLGbvKOKilye9aKRbUinnXyjEZyJ3v_Z4OL_QqTboRRoah5s0wDOqIMynb3eNUClra9hWaYA5JbmMcX-ItzxeKUWaKWCgc9StfLz3b3C1gcIDSMg", 
        }),
      );

      debugPrint("رد السيرفر: ${response.body}");
    } catch (e) {
      debugPrint("خطأ في الاتصال بالسيرفر: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إشعارات النظام"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                token == null ? "جاري جلب التوكن من Firebase..." : "تم جلب التوكن بنجاح",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              if (token != null)
                SelectableText(
                  token!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              if (_lastMessage != null)
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _lastMessage!.notification?.title ?? "بدون عنوان",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastMessage!.notification?.body ?? "بدون محتوى",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}