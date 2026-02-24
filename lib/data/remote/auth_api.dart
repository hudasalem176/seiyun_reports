import 'package:dio/dio.dart';
import '../../core/network/api_service.dart';
//هذا الملف هو اللي نكتب فيه الروابط  اللي  في لارفل
class AuthApi {
  final ApiService _apiService;

  AuthApi(this._apiService);

Future<Response> createUser({
  required String firebaseToken,
  required String role,
  required String name,
  
}) async {
  return await _apiService.post(
    '/createUser',
    data: {
      'idToken': firebaseToken,
      'role': role,
      'name': name,
    },
  );
}


}
