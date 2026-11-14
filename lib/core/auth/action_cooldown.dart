import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// فترة انتظار متصاعدة بين طلبات الإرسال (رسالة التحقق / استعادة كلمة المرور)
/// مع حد أقصى للطلبات في الساعة لمنع إغراق البريد الإلكتروني.
///
/// هذه طبقة حماية على مستوى التطبيق لتحسين التجربة؛ الحماية الفعلية
/// تتم على الخادم (Firebase يرفض الطلبات الزائدة بخطأ too-many-requests).
class ActionCooldown {
  final String action;

  /// فترات الانتظار المتتالية بالثواني.
  final List<int> steps;
  final int maxPerHour;

  const ActionCooldown(
    this.action, {
    this.steps = const [60, 120, 300, 600],
    this.maxPerHour = 5,
  });

  static const verifyEmail = ActionCooldown('verify_email');
  static const passwordReset = ActionCooldown('password_reset');

  String _key(String email) => 'cooldown_${action}_${email.trim().toLowerCase()}';

  Future<List<DateTime>> _history(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(email));
    if (raw == null) return [];
    try {
      final cutoff = DateTime.now().subtract(const Duration(hours: 1));
      return (jsonDecode(raw) as List)
          .map((e) => DateTime.fromMillisecondsSinceEpoch(e as int))
          .where((t) => t.isAfter(cutoff))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// الوقت المتبقي قبل السماح بإرسال جديد (صفر = مسموح).
  Future<Duration> remaining(String email) async {
    final history = await _history(email);
    if (history.isEmpty) return Duration.zero;
    final now = DateTime.now();
    if (history.length >= maxPerHour) {
      final unlock = history.first.add(const Duration(hours: 1));
      return unlock.isAfter(now) ? unlock.difference(now) : Duration.zero;
    }
    final wait = steps[min(history.length - 1, steps.length - 1)];
    final unlock = history.last.add(Duration(seconds: wait));
    return unlock.isAfter(now) ? unlock.difference(now) : Duration.zero;
  }

  Future<void> record(String email) async {
    final history = await _history(email)..add(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(email),
      jsonEncode(history.map((t) => t.millisecondsSinceEpoch).toList()),
    );
  }

  Future<void> reset(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(email));
  }
}
