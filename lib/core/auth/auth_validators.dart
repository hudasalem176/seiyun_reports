import 'package:dio/dio.dart';

/// نتيجة فحص البريد الإلكتروني.
class EmailCheckResult {
  final bool isValid;
  final String? error;

  /// اقتراح تصحيح لأخطاء الكتابة الشائعة مثل gmial.com → gmail.com
  final String? suggestion;

  const EmailCheckResult.valid({this.suggestion}) : isValid = true, error = null;
  const EmailCheckResult.invalid(this.error)
    : isValid = false,
      suggestion = null;
}

/// أدوات التحقق من البريد الإلكتروني وكلمة المرور.
///
/// ملاحظة مهمة: صحة الصيغة ووجود سجلات MX لا تثبت وجود صندوق بريد فعلي.
/// إثبات ملكية البريد يتم فقط عبر رابط التحقق المرسل إليه.
class AuthValidators {
  AuthValidators._();

  // صيغة عملية متوافقة مع RFC 5322 للاستخدام الشائع (بدون علامات اقتباس أو عناوين IP).
  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@"
    r'(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+'
    r'[A-Za-z]{2,63}$',
  );

  /// نطاقات البريد المؤقت الشائعة التي تُستخدم لإنشاء حسابات وهمية.
  static const Set<String> _disposableDomains = {
    'mailinator.com', 'guerrillamail.com', 'guerrillamail.net', '10minutemail.com',
    'tempmail.com', 'temp-mail.org', 'yopmail.com', 'trashmail.com',
    'sharklasers.com', 'getnada.com', 'dispostable.com', 'maildrop.cc',
    'throwawaymail.com', 'fakeinbox.com', 'mintemail.com', 'mohmal.com',
    'emailondeck.com', 'tempail.com', 'burnermail.io', 'mailnesia.com',
  };

  /// أخطاء الكتابة الشائعة في نطاقات البريد المعروفة.
  static const Map<String, String> _commonTypos = {
    'gmial.com': 'gmail.com', 'gmai.com': 'gmail.com', 'gmal.com': 'gmail.com',
    'gamil.com': 'gmail.com', 'gmail.co': 'gmail.com', 'gmail.con': 'gmail.com',
    'gmaill.com': 'gmail.com', 'hotmial.com': 'hotmail.com',
    'hotmail.con': 'hotmail.com', 'hotmal.com': 'hotmail.com',
    'yaho.com': 'yahoo.com', 'yahoo.con': 'yahoo.com', 'outlok.com': 'outlook.com',
    'outlook.con': 'outlook.com', 'iclod.com': 'icloud.com',
  };

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  /// فحص الصيغة محلياً (فوري ولا يحتاج إنترنت).
  static EmailCheckResult checkEmailFormat(String rawEmail) {
    final email = normalizeEmail(rawEmail);
    if (email.isEmpty) {
      return const EmailCheckResult.invalid('يرجى إدخال البريد الإلكتروني');
    }
    if (email.length > 254 || !_emailRegex.hasMatch(email)) {
      return const EmailCheckResult.invalid('صيغة البريد الإلكتروني غير صحيحة');
    }
    final parts = email.split('@');
    final local = parts.first;
    final domain = parts.last;
    if (local.length > 64 ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      return const EmailCheckResult.invalid('صيغة البريد الإلكتروني غير صحيحة');
    }
    if (_disposableDomains.contains(domain)) {
      return const EmailCheckResult.invalid(
        'لا يُسمح باستخدام بريد إلكتروني مؤقت، يرجى استخدام بريدك الشخصي',
      );
    }
    final suggestion = _commonTypos[domain];
    return EmailCheckResult.valid(
      suggestion: suggestion != null ? '$local@$suggestion' : null,
    );
  }

  static final Dio _dnsDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'Accept': 'application/dns-json'},
    ),
  );

  /// يتحقق من أن نطاق البريد يستقبل رسائل (سجل MX، أو سجل A كبديل حسب RFC 5321).
  ///
  /// يُرسَل اسم النطاق فقط (وليس البريد كاملاً) إلى خدمة DNS-over-HTTPS.
  /// يعيد `true` إذا لم يمكن التحقق (لا إنترنت/فشل الخدمة) حتى لا نمنع مستخدماً شرعياً؛
  /// ويعيد `false` فقط عندما نتأكد أن النطاق غير موجود أو لا يستقبل بريداً.
  static Future<bool> domainAcceptsMail(String rawEmail) async {
    final domain = normalizeEmail(rawEmail).split('@').last;
    try {
      final mx = await _dnsQuery(domain, 'MX');
      if (mx == null) return true; // تعذر التحقق
      final status = mx['Status'];
      if (status == 3) return false; // NXDOMAIN: النطاق غير موجود
      final answers = (mx['Answer'] as List?) ?? const [];
      final hasMx = answers.any((a) => a is Map && a['type'] == 15);
      if (hasMx) {
        // سجل "Null MX" (RFC 7505) يعني أن النطاق يرفض استقبال البريد صراحة.
        final nullMx = answers.every(
          (a) => a is Map && a['type'] == 15 && '${a['data']}'.trim() == '0 .',
        );
        return !nullMx;
      }
      final a = await _dnsQuery(domain, 'A');
      if (a == null) return true;
      final aAnswers = (a['Answer'] as List?) ?? const [];
      return aAnswers.any((r) => r is Map && r['type'] == 1);
    } catch (_) {
      return true;
    }
  }

  static Future<Map<String, dynamic>?> _dnsQuery(String name, String type) async {
    try {
      final res = await _dnsDio.get(
        'https://cloudflare-dns.com/dns-query',
        queryParameters: {'name': name, 'type': type},
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// سياسة كلمة المرور: 8 أحرف على الأقل، تحتوي حرفاً ورقماً، وليست من الكلمات الشائعة.
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'يرجى إدخال كلمة المرور';
    if (password.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (password.length > 128) return 'كلمة المرور طويلة جداً';
    if (!RegExp(r'[A-Za-z؀-ۿ]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'كلمة المرور يجب أن تحتوي على حروف وأرقام';
    }
    const common = {
      '12345678', 'password', 'password1', 'qwerty123', '11111111',
      'abc12345', 'iloveyou1', 'admin123', 'a1234567', '123456789a',
    };
    if (common.contains(password.toLowerCase())) {
      return 'كلمة المرور سهلة التخمين، اختر كلمة أقوى';
    }
    return null;
  }

  /// مقياس بسيط لقوة كلمة المرور من 0 إلى 4 لعرضه في الواجهة.
  static int passwordStrength(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      score++;
    }
    return score.clamp(0, 4);
  }

  static String? validateName(String name) {
    final n = name.trim();
    if (n.isEmpty) return 'يرجى إدخال الاسم الكامل';
    if (n.length < 3) return 'الاسم قصير جداً';
    if (n.length > 60) return 'الاسم طويل جداً';
    if (RegExp(r'[<>{}\[\]\\/$%^*=|~`]').hasMatch(n)) {
      return 'الاسم يحتوي على رموز غير مسموحة';
    }
    return null;
  }
}
