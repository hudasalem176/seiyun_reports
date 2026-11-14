import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:seiyun_reports_app/core/auth/secure_token_storage.dart';
import 'package:seiyun_reports_app/core/auth/session_manager.dart';

class DioClient {
  static const String baseUrl = 'https://medicalhouse-ye.net/api/';

  /// مفتاح يمنع إعادة المحاولة اللانهائية بعد تجديد الرمز.
  static const String _retriedKey = 'auth_retried';

  late Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            // طلب حدد رمزه بنفسه (مثل تبادل رمز Firebase عند الدخول) لا نستبدله.
            if (options.headers.containsKey('Authorization')) {
              return handler.next(options);
            }

            final laravelToken = await SecureTokenStorage.getToken();

            if (laravelToken != null && laravelToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $laravelToken';
            } else {
              User? user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                String? firebaseToken = await user.getIdToken();
                if (firebaseToken != null) {
                  options.headers['Authorization'] = 'Bearer $firebaseToken';

                  if (options.method == 'POST') {
                    if (options.data is FormData) {
                      (options.data as FormData).fields.add(
                        MapEntry("idToken", firebaseToken),
                      );
                    } else if (options.data is Map) {
                      options.data['idToken'] = firebaseToken;
                    } else {
                      options.data = {"idToken": firebaseToken};
                    }
                  }
                }
              }
            }
          } catch (e) {
            // Ignore errors during token retrieval
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final response = error.response;
          final options = error.requestOptions;
          final isAuthEndpoint =
              options.path.endsWith('/login') ||
              options.path.endsWith('/logout');

          if (response?.statusCode != 401 ||
              isAuthEndpoint ||
              options.extra[_retriedKey] == true ||
              FirebaseAuth.instance.currentUser == null) {
            return handler.next(error);
          }

          // انتهت صلاحية رمز الخادم: نجدده مرة واحدة ثم نعيد الطلب الأصلي.
          final newToken = await SessionManager.refreshBackendToken();
          if (newToken == null) {
            await SessionManager.expireSession();
            return handler.next(error);
          }

          // FormData لا يمكن إعادة إرسالها بعد استهلاكها، ننسخها.
          final retryOptions = options.copyWith(
            data: options.data is FormData
                ? (options.data as FormData).clone()
                : options.data,
            headers: {
              ...options.headers,
              'Authorization': 'Bearer $newToken',
            },
            extra: {...options.extra, _retriedKey: true},
          );
          try {
            final retried = await dio.fetch(retryOptions);
            return handler.resolve(retried);
          } on DioException catch (e) {
            if (e.response?.statusCode == 401) {
              await SessionManager.expireSession();
            }
            return handler.next(e);
          }
        },
      ),
    );
  }
}
