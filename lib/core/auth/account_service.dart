import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seiyun_reports_app/core/auth/auth_error_mapper.dart';
import 'package:seiyun_reports_app/core/auth/auth_validators.dart';
import 'package:seiyun_reports_app/core/auth/session_manager.dart';
import 'package:seiyun_reports_app/core/network/api_service.dart';

class AccountActionResult {
  final bool ok;
  final String message;

  const AccountActionResult(this.ok, this.message);
}

/// عمليات إدارة الحساب الحساسة. كل عملية تتطلب إعادة المصادقة (كلمة المرور الحالية
/// أو Google) حتى لا يستطيع من يحمل الجهاز مفتوحاً تغيير بيانات الدخول أو حذف الحساب.
///
/// كلمات المرور لا تُخزَّن ولا تُرسل إلى خادم Laravel إطلاقاً؛ يتعامل معها Firebase
/// Authentication الذي يخزّنها مجزّأة بخوارزمية scrypt.
class AccountService {
  /// نقطة حذف الحساب على الخادم (موثقة في docs/BACKEND_REQUIREMENTS.md).
  static const String deleteEndpoint = 'account';

  final ApiService _api;
  final FirebaseAuth _auth;

  AccountService(this._api, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  bool get usesPassword =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  Future<void> _reauthenticate(String? currentPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(code: 'requires-recent-login');
    }
    if (usesPassword) {
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword ?? '',
      );
      await user.reauthenticateWithCredential(cred);
    } else {
      final google = GoogleSignIn();
      final account = await google.signIn();
      if (account == null) {
        throw FirebaseAuthException(code: 'cancelled');
      }
      final auth = await account.authentication;
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(
          idToken: auth.idToken,
          accessToken: auth.accessToken,
        ),
      );
    }
  }

  Future<AccountActionResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final policy = AuthValidators.validatePassword(newPassword);
    if (policy != null) return AccountActionResult(false, policy);
    if (newPassword == currentPassword) {
      return const AccountActionResult(
        false,
        'كلمة المرور الجديدة يجب أن تختلف عن الحالية',
      );
    }
    try {
      await _reauthenticate(currentPassword);
      // يُلغي Firebase جلسات الأجهزة الأخرى تلقائياً بعد تغيير كلمة المرور.
      await _auth.currentUser!.updatePassword(newPassword);
      return const AccountActionResult(true, 'تم تغيير كلمة المرور بنجاح');
    } catch (e) {
      return AccountActionResult(false, _map(e));
    }
  }

  /// تغيير البريد الإلكتروني: لا يتغير فعلياً إلا بعد فتح رابط التحقق المرسل
  /// إلى البريد الجديد، ويُرسل Firebase تنبيهاً إلى البريد القديم مع إمكانية التراجع.
  Future<AccountActionResult> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    final email = AuthValidators.normalizeEmail(newEmail);
    final format = AuthValidators.checkEmailFormat(email);
    if (!format.isValid) return AccountActionResult(false, format.error!);
    if (email == _auth.currentUser?.email?.toLowerCase()) {
      return const AccountActionResult(false, 'هذا هو بريدك الحالي');
    }
    if (!await AuthValidators.domainAcceptsMail(email)) {
      return const AccountActionResult(
        false,
        'نطاق البريد غير موجود أو لا يستقبل رسائل',
      );
    }
    try {
      await _reauthenticate(currentPassword);
      await _auth.currentUser!.verifyBeforeUpdateEmail(email);
      return const AccountActionResult(
        true,
        'أرسلنا رابط تأكيد إلى البريد الجديد. لن يتغير بريدك حتى تفتح الرابط، '
        'وبعدها ستحتاج لتسجيل الدخول مجدداً.',
      );
    } catch (e) {
      return AccountActionResult(false, _map(e));
    }
  }

  /// حذف الحساب نهائياً: يُحذف من الخادم أولاً (البيانات الشخصية)، ثم من Firebase،
  /// ثم تُمسح كل البيانات المحلية. إذا رفض الخادم الحذف لا نحذف حساب Firebase
  /// حتى لا تبقى بيانات شخصية يتيمة على الخادم دون وسيلة للوصول إليها.
  Future<AccountActionResult> deleteAccount({String? currentPassword}) async {
    try {
      await _reauthenticate(currentPassword);
    } catch (e) {
      return AccountActionResult(false, _map(e));
    }
    try {
      await _api.delete(deleteEndpoint);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405 || code == 501) {
        return const AccountActionResult(
          false,
          'حذف الحساب إلكترونياً غير مفعّل على خادم الصندوق بعد. '
          'تواصل مع الدعم الفني لطلب حذف حسابك وبياناتك.',
        );
      }
      return AccountActionResult(false, AuthErrorMapper.map(e));
    }
    try {
      await _auth.currentUser?.delete();
    } catch (_) {
      // حُذفت البيانات من الخادم؛ نكمل الخروج محلياً في كل الأحوال.
    }
    await SessionManager.logout();
    return const AccountActionResult(true, 'تم حذف حسابك وجميع بياناتك');
  }

  String _map(Object e) {
    if (e is FirebaseAuthException) {
      if (e.code == 'cancelled') return 'تم إلغاء العملية';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'كلمة المرور الحالية غير صحيحة';
      }
      if (e.code == 'email-already-in-use') {
        return 'تعذر استخدام هذا البريد، جرّب بريداً آخر';
      }
    }
    return AuthErrorMapper.map(e);
  }
}
