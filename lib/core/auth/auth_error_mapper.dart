import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// تحويل أخطاء المصادقة إلى رسائل عربية واضحة وآمنة.
///
/// القاعدة: لا نكشف أبداً ما إذا كان البريد مسجلاً أم لا في تسجيل الدخول أو
/// استعادة كلمة المرور، ولا نعرض تفاصيل تقنية من الخادم للمستخدم.
class AuthErrorMapper {
  AuthErrorMapper._();

  static const String invalidCredentials =
      'البريد الإلكتروني أو كلمة المرور غير صحيحة';

  static String map(Object error) {
    if (error is FirebaseAuthException) return _firebase(error.code);
    if (error is DioException) return _dio(error);
    return 'حدث خطأ غير متوقع، يرجى المحاولة مرة أخرى';
  }

  static String _firebase(String code) {
    switch (code) {
      // نفس الرسالة لكل حالات فشل الدخول لمنع كشف الحسابات المسجلة.
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return invalidCredentials;
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة';
      case 'email-already-in-use':
        return 'تعذر إنشاء الحساب بهذا البريد. إن كان لديك حساب بالفعل فسجّل الدخول أو استعد كلمة المرور';
      case 'weak-password':
      case 'password-does-not-meet-requirements':
        return 'كلمة المرور ضعيفة، استخدم 8 أحرف على الأقل تتضمن حروفاً وأرقاماً';
      case 'user-disabled':
        return 'تم إيقاف هذا الحساب، يرجى التواصل مع إدارة الصندوق';
      case 'too-many-requests':
        return 'محاولات كثيرة جداً. تم إيقاف المحاولة مؤقتاً لحماية حسابك، حاول لاحقاً';
      case 'network-request-failed':
        return 'لا يوجد اتصال بالإنترنت، تأكد من الشبكة وحاول مجدداً';
      case 'expired-action-code':
        return 'انتهت صلاحية الرابط، اطلب رابطاً جديداً';
      case 'invalid-action-code':
        return 'الرابط غير صالح أو تم استخدامه من قبل';
      case 'requires-recent-login':
        return 'لأسباب أمنية، يرجى تسجيل الدخول مجدداً ثم إعادة المحاولة';
      case 'account-exists-with-different-credential':
        return 'هذا البريد مرتبط بطريقة دخول أخرى، جرّب الدخول بالبريد وكلمة المرور';
      case 'operation-not-allowed':
        return 'طريقة الدخول هذه غير مفعلة حالياً';
      default:
        return 'تعذر إتمام العملية، يرجى المحاولة مرة أخرى';
    }
  }

  static String _dio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'تعذر الاتصال بالخادم، تأكد من الإنترنت وحاول مجدداً';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        if (status == 401 || status == 403) {
          return 'تعذر التحقق من حسابك لدى الخادم، يرجى تسجيل الدخول مجدداً';
        }
        if (status == 429) {
          return 'طلبات كثيرة جداً، يرجى الانتظار قليلاً';
        }
        if (status >= 500) return 'الخادم غير متاح حالياً، حاول لاحقاً';
        return 'تعذر إتمام الطلب، يرجى المحاولة مرة أخرى';
      default:
        return 'حدث خطأ في الاتصال، يرجى المحاولة مرة أخرى';
    }
  }
}
