import 'package:dio/dio.dart';
import 'package:seiyun_reports_app/core/network/api_service.dart';

class AuthService {
  final ApiService _apiService;

  AuthService(this._apiService);

  /// تبادل رمز Firebase (بعد التحقق من البريد) برمز وصول من الخادم.
  ///
  /// يجب على الخادم التحقق من [idToken] عبر Firebase Admin SDK والتأكد من
  /// أن `email_verified == true` قبل إصدار الرمز، وعدم الوثوق بالبريد/الدور المرسل.
  Future<Response> login({
    required String role,
    String? name,
    String? email,
    String? idToken,
  }) async {
    return await _apiService.post(
      '/login',
      data: {
        'role': role,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (idToken != null) 'idToken': idToken,
      },
      headers: idToken != null ? {'Authorization': 'Bearer $idToken'} : null,
    );
  }
}
