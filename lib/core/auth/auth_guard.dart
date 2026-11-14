import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/core/auth/session_manager.dart';

/// يمنع الوصول إلى الصفحات المحمية دون جلسة كاملة (مسجل + بريد مفعّل)،
/// ويعيد المستخدم إلى شاشة البداية التي توجهه للدخول أو التفعيل.
class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (SessionManager.isFullyAuthenticated) return child;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = SessionManager.navigatorKey.currentState;
      nav?.pushNamedAndRemoveUntil('/', (route) => false);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
