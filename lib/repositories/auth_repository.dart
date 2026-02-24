import 'package:firebase_auth/firebase_auth.dart';
import '../core/network/dio_client.dart';
import '../core/network/api_service.dart';
import '../data/remote/auth_api.dart';
import '../core/utils/pref_helper.dart';
import '../data/models/user_model.dart';

class AuthRepository {
  late AuthApi _authApi;

  AuthRepository() {
    final dioClient = DioClient();
    final apiService = ApiService(dioClient);
    _authApi = AuthApi(apiService);
  }

  Future<UserModel> registerUser({required String role, required String name}) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    String? firebaseToken = await user.getIdToken(true);
    if (firebaseToken == null) throw Exception('Failed to get Firebase ID Token');

    final response = await _authApi.createUser(
      firebaseToken: firebaseToken,
      role: role,
      name: name,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // تحويل البيانات القادمة من السيرفر (داخل حقل data) إلى الموديل
      final userModel = UserModel.fromJson(response.data['data']);
      
      // حفظ التوكن والدور محلياً
      await PrefHelper.saveToken(firebaseToken);
      await PrefHelper.saveRole(userModel.role);
      
      return userModel;
    } else {
      throw Exception('Server Error: ${response.data['message']}');
    }
  }
}