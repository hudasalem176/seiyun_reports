import 'package:dio/dio.dart';
import 'package:seiyun_reports_app/core/network/api_service.dart';
import '../model/service_request.dart';

enum ServiceSubmitStatus {
  /// استلم الخادم الطلب.
  accepted,

  /// نقطة الطلب غير مفعّلة على الخادم بعد (404/405/501).
  notAvailable,

  /// فشل لأي سبب آخر (شبكة، تحقق، خطأ خادم).
  failed,
}

class ServiceSubmitResult {
  final ServiceSubmitStatus status;
  final String? referenceNumber;
  final String? message;

  const ServiceSubmitResult(this.status, {this.referenceNumber, this.message});
}

/// إرسال طلبات الخدمات الخاصة إلى الخادم.
///
/// العقد المطلوب على الخادم موثق في docs/BACKEND_REQUIREMENTS.md:
/// `POST service-requests` → `{ data: { id, reference_number, status } }`
class ServiceRequestRepository {
  static const String endpoint = 'service-requests';

  final ApiService _api;

  ServiceRequestRepository(this._api);

  Future<ServiceSubmitResult> submit(ServiceRequest request) async {
    try {
      final res = await _api.post(
        endpoint,
        data: request.toJson(),
        headers: {'Idempotency-Key': request.clientRequestId},
      );
      final code = res.statusCode ?? 0;
      if (code == 200 || code == 201) {
        final data = res.data is Map ? res.data['data'] : null;
        return ServiceSubmitResult(
          ServiceSubmitStatus.accepted,
          referenceNumber:
              data is Map
                  ? (data['reference_number'] ?? data['id'])?.toString()
                  : null,
        );
      }
      return const ServiceSubmitResult(ServiceSubmitStatus.failed);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405 || code == 501) {
        return const ServiceSubmitResult(ServiceSubmitStatus.notAvailable);
      }
      if (code == 422) {
        final msg = e.response?.data is Map ? e.response?.data['message'] : null;
        return ServiceSubmitResult(
          ServiceSubmitStatus.failed,
          message: msg is String ? msg : 'بيانات الطلب غير مكتملة',
        );
      }
      if (code == 429) {
        return const ServiceSubmitResult(
          ServiceSubmitStatus.failed,
          message: 'طلبات كثيرة، يرجى المحاولة لاحقاً',
        );
      }
      return const ServiceSubmitResult(
        ServiceSubmitStatus.failed,
        message: 'تعذر إرسال الطلب، تأكد من الاتصال بالإنترنت',
      );
    }
  }
}
