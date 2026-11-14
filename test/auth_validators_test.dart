import 'package:flutter_test/flutter_test.dart';
import 'package:seiyun_reports_app/core/auth/action_cooldown.dart';
import 'package:seiyun_reports_app/core/auth/auth_validators.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('صيغة البريد الإلكتروني', () {
    test('يقبل بريداً صحيحاً ويوحّد الأحرف', () {
      final r = AuthValidators.checkEmailFormat('  Ali.Ahmed+1@Gmail.com ');
      expect(r.isValid, isTrue);
      expect(AuthValidators.normalizeEmail(' A@B.com '), 'a@b.com');
    });

    test('يرفض الصيغ غير الصحيحة', () {
      for (final e in [
        '',
        'ali',
        'ali@',
        '@gmail.com',
        'ali@gmail',
        'ali..x@gmail.com',
        '.ali@gmail.com',
        'ali@-gmail.com',
        'ali @gmail.com',
      ]) {
        expect(AuthValidators.checkEmailFormat(e).isValid, isFalse, reason: e);
      }
    });

    test('يرفض البريد المؤقت', () {
      expect(
        AuthValidators.checkEmailFormat('x@mailinator.com').isValid,
        isFalse,
      );
    });

    test('يقترح تصحيح الأخطاء الشائعة', () {
      final r = AuthValidators.checkEmailFormat('ali@gmial.com');
      expect(r.isValid, isTrue);
      expect(r.suggestion, 'ali@gmail.com');
    });
  });

  group('كلمة المرور', () {
    test('سياسة القبول والرفض', () {
      expect(AuthValidators.validatePassword('short1'), isNotNull);
      expect(AuthValidators.validatePassword('onlyletters'), isNotNull);
      expect(AuthValidators.validatePassword('12345678'), isNotNull);
      expect(AuthValidators.validatePassword('password1'), isNotNull);
      expect(AuthValidators.validatePassword('Seiyun2026'), isNull);
    });

    test('مقياس القوة ضمن المدى', () {
      expect(AuthValidators.passwordStrength(''), 0);
      expect(AuthValidators.passwordStrength('Seiyun#2026Clean'), 4);
    });
  });

  group('فترة الانتظار بين طلبات الإرسال', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('يسمح بالطلب الأول ثم يفرض الانتظار', () async {
      const c = ActionCooldown('test');
      expect(await c.remaining('a@b.com'), Duration.zero);
      await c.record('a@b.com');
      final wait = await c.remaining('a@b.com');
      expect(wait.inSeconds, greaterThan(50));
      await c.reset('a@b.com');
      expect(await c.remaining('a@b.com'), Duration.zero);
    });

    test('يطبق الحد الأقصى في الساعة', () async {
      const c = ActionCooldown('test2', steps: [0], maxPerHour: 2);
      await c.record('a@b.com');
      expect(await c.remaining('a@b.com'), Duration.zero);
      await c.record('a@b.com');
      expect((await c.remaining('a@b.com')).inMinutes, greaterThan(55));
    });
  });
}
