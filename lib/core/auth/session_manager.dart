import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seiyun_reports_app/core/auth/secure_token_storage.dart';
import 'package:seiyun_reports_app/core/database/database_helper.dart';
import 'package:seiyun_reports_app/core/services/notification_service.dart';
import 'package:seiyun_reports_app/core/network/dio_client.dart';
import 'package:seiyun_reports_app/core/utils/pref_helper.dart';

/// إدارة جلسة المستخدم: التحقق من صلاحيتها، تجديد رمز الخادم، وتسجيل الخروج الآمن.
///
/// - رمز Firebase (ID Token) صالح لساعة ويُجدَّد تلقائياً عبر Refresh Token.
/// - رمز الخادم (Laravel) يُجدَّد عند انتهائه (استجابة 401) بتبادله مع رمز Firebase جديد.
/// - عند فشل التجديد تُنهى الجلسة ويُعاد المستخدم لشاشة الدخول.
class SessionManager {
  SessionManager._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<String?>? _refreshInFlight;
  static bool _expiring = false;

  /// المستخدم مسجل ومفعل البريد (أو دخل بمزود موثوق مثل Google).
  static bool get isFullyAuthenticated {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && isVerified(user);
  }

  static bool isVerified(User user) {
    if (user.emailVerified) return true;
    // حسابات Google يتحقق منها Google نفسه.
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  /// يتحقق من أن جلسة Firebase ما زالت صالحة على الخادم (لم يُحذف/يُعطّل الحساب
  /// ولم تُلغَ الجلسة بعد تغيير كلمة المرور).
  static Future<bool> validateRemoteSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      await user.getIdToken(true);
      return true;
    } on FirebaseAuthException catch (e) {
      const fatal = {
        'user-disabled',
        'user-not-found',
        'user-token-expired',
        'invalid-user-token',
      };
      return !fatal.contains(e.code);
    } catch (_) {
      // خطأ شبكة: نسمح بالعمل دون اتصال بالجلسة المخزنة.
      return true;
    }
  }

  /// يتبادل رمز Firebase الحالي برمز جديد من خادم Laravel (طلب واحد في نفس الوقت).
  static Future<String?> refreshBackendToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(
      () => _refreshInFlight = null,
    );
  }

  static Future<String?> _doRefresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !isVerified(user)) return null;
    try {
      final idToken = await user.getIdToken(true);
      if (idToken == null) return null;
      final dio = Dio(
        BaseOptions(
          baseUrl: DioClient.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
        ),
      );
      // نفس قيمة الدور التي يرسلها التطبيق عند الدخول؛ الخادم هو من يحدد الدور الفعلي.
      const role = 'citizens';
      final res = await dio.post(
        '/login',
        data: {'role': role, 'email': user.email, 'idToken': idToken},
      );
      final token = res.data?['data']?['token']?.toString();
      if (token == null || token.isEmpty) return null;
      await SecureTokenStorage.saveToken(token);
      final serverRole = res.data?['data']?['role']?.toString();
      if (serverRole != null) await PrefHelper.saveRole(serverRole);
      return token;
    } catch (_) {
      return null;
    }
  }

  /// تسجيل خروج آمن: إبطال الرمز على الخادم (إن أمكن) ثم مسح كل البيانات المحلية.
  static Future<void> logout() async {
    final token = await SecureTokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await Dio(
          BaseOptions(
            baseUrl: DioClient.baseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
        ).post('/logout');
      } catch (_) {
        // نكمل تسجيل الخروج محلياً حتى لو فشل الاتصال بالخادم.
      }
    }
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
    await SecureTokenStorage.clear();
    await PrefHelper.clear();
    // عدم الاحتفاظ ببيانات المستخدم بعد الخروج.
    try {
      await DatabaseHelper().clearUserData();
    } catch (_) {}
    try {
      await NotificationService.cancelAllNotifications();
    } catch (_) {}
    try {
      PaintingBinding.instance.imageCache.clear();
    } catch (_) {}
    sessionGeneration.value++;
  }

  /// يتغير مع كل تسجيل خروج؛ يُستخدم لإعادة إنشاء الـ ViewModels وتفريغ الحالة في الذاكرة.
  static final ValueNotifier<int> sessionGeneration = ValueNotifier<int>(0);

  /// يُستدعى عند انتهاء الجلسة نهائياً (فشل تجديد الرمز).
  static Future<void> expireSession() async {
    if (_expiring) return;
    _expiring = true;
    try {
      await logout();
      final nav = navigatorKey.currentState;
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
          const SnackBar(
            content: Text('انتهت صلاحية الجلسة، يرجى تسجيل الدخول مجدداً'),
          ),
        );
      }
      nav?.pushNamedAndRemoveUntil('/', (route) => false);
    } finally {
      _expiring = false;
    }
  }
}
