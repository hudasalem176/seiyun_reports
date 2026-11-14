import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seiyun_reports_app/core/auth/action_cooldown.dart';
import 'package:seiyun_reports_app/core/auth/auth_error_mapper.dart';
import 'package:seiyun_reports_app/core/auth/auth_validators.dart';
import 'package:seiyun_reports_app/core/auth/session_manager.dart';
import 'package:seiyun_reports_app/core/utils/pref_helper.dart';
import 'package:seiyun_reports_app/screens/auth/data/auth_repository.dart';

/// نتيجة عملية المصادقة.
enum AuthOutcome {
  /// تم الدخول بالكامل (بريد مفعل + رمز من الخادم).
  success,

  /// الحساب موجود لكن البريد لم يُفعَّل بعد.
  needsVerification,

  failure,
}

/// كلاس إدارة حالة المصادقة (تسجيل الدخول، إنشاء حساب، التحقق من البريد،
/// استعادة كلمة المرور، تسجيل جوجل).
class AuthViewModel extends ChangeNotifier {
  static const String _pendingNameKey = 'pending_signup_name';
  static const int _maxFailedLogins = 5;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSignupMode = true;
  bool get isSignupMode => _isSignupMode;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthRepository _authRepo = AuthRepository();

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// حماية إضافية في التطبيق ضد تخمين كلمة المرور (الخادم لديه حمايته الخاصة).
  int _failedLogins = 0;
  bool _checkingVerification = false;
  DateTime? _loginLockedUntil;

  AuthViewModel() {
    // رسائل التحقق واستعادة كلمة المرور تصل باللغة العربية.
    _auth.setLanguageCode('ar').catchError((_) {});
  }

  /// التبديل بين واجهة تسجيل الدخول وإنشاء الحساب
  void toggleSignupMode() {
    _isSignupMode = !_isSignupMode;
    notifyListeners();
  }

  /// فرض وضع تسجيل الدخول
  void forceSignInMode() {
    _isSignupMode = false;
    notifyListeners();
  }

  /// مسح رسائل الخطأ الحالية
  void clearError() {
    _errorMessage = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  User? get currentUser => _auth.currentUser;

  /// معالجة المصادقة عبر البريد الإلكتروني وكلمة المرور
  Future<AuthOutcome> handleEmailAuth({
    required String email,
    required String password,
    String? name,
  }) async {
    _errorMessage = null;
    final normalizedEmail = AuthValidators.normalizeEmail(email);

    final format = AuthValidators.checkEmailFormat(normalizedEmail);
    if (!format.isValid) {
      _errorMessage = format.error;
      notifyListeners();
      return AuthOutcome.failure;
    }

    if (!_isSignupMode) {
      final lock = _loginLockedUntil;
      if (lock != null && DateTime.now().isBefore(lock)) {
        final secs = lock.difference(DateTime.now()).inSeconds + 1;
        _errorMessage = 'محاولات كثيرة، يرجى الانتظار $secs ثانية';
        notifyListeners();
        return AuthOutcome.failure;
      }
    }

    _setLoading(true);
    try {
      if (_isSignupMode) {
        return await _signUp(normalizedEmail, password, name);
      }
      return await _signIn(normalizedEmail, password);
    } on FirebaseAuthException catch (e) {
      if (!_isSignupMode && _isCredentialError(e.code)) _registerFailedLogin();
      _errorMessage = AuthErrorMapper.map(e);
    } catch (e) {
      _errorMessage = _messageFor(e);
    } finally {
      _setLoading(false);
    }
    return AuthOutcome.failure;
  }

  Future<AuthOutcome> _signUp(
    String email,
    String password,
    String? name,
  ) async {
    final nameError = AuthValidators.validateName(name ?? '');
    if (nameError != null) {
      _errorMessage = nameError;
      return AuthOutcome.failure;
    }
    final passwordError = AuthValidators.validatePassword(password);
    if (passwordError != null) {
      _errorMessage = passwordError;
      return AuthOutcome.failure;
    }
    if (!await AuthValidators.domainAcceptsMail(email)) {
      _errorMessage =
          'نطاق البريد الإلكتروني غير موجود أو لا يستقبل رسائل، تأكد من كتابته بشكل صحيح';
      return AuthOutcome.failure;
    }

    // لا نقص المسافات من كلمة المرور: هي جزء منها.
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final cleanName = name!.trim();
    await cred.user?.updateDisplayName(cleanName);
    await PrefHelper.setString(_pendingNameKey, cleanName);

    await cred.user?.sendEmailVerification();
    await ActionCooldown.verifyEmail.record(email);
    return AuthOutcome.needsVerification;
  }

  Future<AuthOutcome> _signIn(String email, String password) async {
    if (password.isEmpty) {
      _errorMessage = 'يرجى إدخال كلمة المرور';
      return AuthOutcome.failure;
    }
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _failedLogins = 0;
    _loginLockedUntil = null;

    final user = cred.user!;
    await user.reload();
    final fresh = _auth.currentUser ?? user;
    if (!SessionManager.isVerified(fresh)) {
      // نُبقي جلسة Firebase لإعادة إرسال رسالة التحقق، لكن لا نسجل لدى الخادم.
      return AuthOutcome.needsVerification;
    }
    try {
      await _syncWithBackend(fresh);
    } catch (_) {
      // لا نترك جلسة Firebase دون رمز من الخادم.
      await _auth.signOut().catchError((_) {});
      rethrow;
    }
    return AuthOutcome.success;
  }

  bool _isCredentialError(String code) => const {
    'user-not-found',
    'wrong-password',
    'invalid-credential',
    'INVALID_LOGIN_CREDENTIALS',
  }.contains(code);

  void _registerFailedLogin() {
    _failedLogins++;
    if (_failedLogins >= _maxFailedLogins) {
      // مدة إيقاف متصاعدة: 30 ثانية، ثم 60، ثم 120...
      final factor = 1 << (_failedLogins - _maxFailedLogins).clamp(0, 5);
      _loginLockedUntil = DateTime.now().add(Duration(seconds: 30 * factor));
    }
  }

  /// تسجيل المستخدم لدى خادم التطبيق (بعد التحقق من البريد فقط).
  Future<void> _syncWithBackend(User user) async {
    // تحديث الرمز ليحمل email_verified = true بعد التفعيل.
    final token = await user.getIdToken(true);
    final pendingName = await PrefHelper.getString(_pendingNameKey);
    await _authRepo.registerUser(
      role: 'citizens',
      name:
          (pendingName != null && pendingName.isNotEmpty)
              ? pendingName
              : user.displayName,
      token: token,
      email: user.email,
    );
    if (pendingName != null) await PrefHelper.setString(_pendingNameKey, '');
  }

  /// يتحقق من حالة تفعيل البريد لدى Firebase، ويكمل الدخول إن تم التفعيل.
  /// [silent] لعدم إظهار مؤشر التحميل أثناء الفحص الدوري.
  Future<AuthOutcome> checkEmailVerified({bool silent = false}) async {
    final user = _auth.currentUser;
    if (user == null) return AuthOutcome.failure;
    if (_checkingVerification) return AuthOutcome.needsVerification;
    _checkingVerification = true;
    if (!silent) _setLoading(true);
    _errorMessage = null;
    try {
      await user.reload();
      final fresh = _auth.currentUser!;
      if (!SessionManager.isVerified(fresh)) {
        if (!silent) {
          _errorMessage =
              'لم يتم تأكيد البريد بعد. افتح الرابط المرسل إلى بريدك ثم أعد المحاولة';
        }
        return AuthOutcome.needsVerification;
      }
      await _syncWithBackend(fresh);
      if (fresh.email != null) {
        await ActionCooldown.verifyEmail.reset(fresh.email!);
      }
      return AuthOutcome.success;
    } catch (e) {
      if (!silent) _errorMessage = _messageFor(e);
      return AuthOutcome.failure;
    } finally {
      _checkingVerification = false;
      if (!silent) {
        _setLoading(false);
      } else {
        notifyListeners();
      }
    }
  }

  /// الوقت المتبقي قبل السماح بإعادة إرسال رسالة التحقق.
  Future<Duration> verificationCooldown() async {
    final email = _auth.currentUser?.email;
    if (email == null) return Duration.zero;
    return ActionCooldown.verifyEmail.remaining(email);
  }

  /// إعادة إرسال رسالة التحقق مع احترام فترة الانتظار.
  Future<bool> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    _errorMessage = null;
    final wait = await ActionCooldown.verifyEmail.remaining(user.email!);
    if (wait > Duration.zero) {
      _errorMessage = 'يمكنك إعادة الإرسال بعد ${_formatDuration(wait)}';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      await user.sendEmailVerification();
      await ActionCooldown.verifyEmail.record(user.email!);
      return true;
    } catch (e) {
      _errorMessage = _messageFor(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// إرسال رابط استعادة كلمة المرور.
  ///
  /// يعيد `true` في كل الحالات التي لا تكشف وجود الحساب (حتى لو لم يكن البريد مسجلاً)،
  /// ويعيد `false` فقط لأخطاء الإدخال أو الشبكة أو تجاوز حد الطلبات.
  Future<bool> sendPasswordReset(String rawEmail) async {
    _errorMessage = null;
    final email = AuthValidators.normalizeEmail(rawEmail);
    final format = AuthValidators.checkEmailFormat(email);
    if (!format.isValid) {
      _errorMessage = format.error;
      notifyListeners();
      return false;
    }
    final wait = await ActionCooldown.passwordReset.remaining(email);
    if (wait > Duration.zero) {
      _errorMessage = 'يمكنك طلب رابط جديد بعد ${_formatDuration(wait)}';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      await ActionCooldown.passwordReset.record(email);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'user-disabled') {
        // نفس الاستجابة لعدم كشف الحسابات المسجلة.
        await ActionCooldown.passwordReset.record(email);
        return true;
      }
      _errorMessage = AuthErrorMapper.map(e);
      return false;
    } catch (e) {
      _errorMessage = _messageFor(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<Duration> passwordResetCooldown(String email) =>
      ActionCooldown.passwordReset.remaining(email);

  /// إلغاء عملية التحقق والعودة لشاشة الدخول بحساب آخر.
  Future<void> signOutPending() async {
    await SessionManager.logout();
    _isSignupMode = false;
    notifyListeners();
  }

  /// معالجة تسجيل الدخول عبر حساب Google
  Future<bool> handleGoogleSignIn() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return false; // ألغى المستخدم العملية
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _syncWithBackend(user);
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _messageFor(e);
      // لا نترك جلسة Firebase معلقة دون رمز من الخادم.
      await _auth.signOut().catchError((_) {});
      return false;
    } finally {
      _setLoading(false);
    }
  }

  String _messageFor(Object e) {
    if (e is FirebaseAuthException || e is DioException) {
      return AuthErrorMapper.map(e);
    }
    final text = e.toString();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '');
    }
    return AuthErrorMapper.map(e);
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    if (m > 0) return '$m:${s.toString().padLeft(2, '0')} دقيقة';
    return '$s ثانية';
  }
}
