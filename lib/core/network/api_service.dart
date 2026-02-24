import 'package:dio/dio.dart';
import 'dio_client.dart';

class ApiService {
  final Dio _dio;

  ApiService(DioClient dioClient) : _dio = dioClient.dio;

  Future<Response> get(String path,
      {Map<String, dynamic>? query}) async {
    return await _dio.get(path, queryParameters: query);
  }

  Future<Response> post(String path,
      {Map<String, dynamic>? data}) async {
    return await _dio.post(path, data: data);
  }
}
