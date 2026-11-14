import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seiyun_reports_app/core/models/report_status.dart';
import 'package:seiyun_reports_app/core/network/api_service.dart';
import 'package:seiyun_reports_app/core/network/dio_client.dart';
import 'package:seiyun_reports_app/core/utils/pref_helper.dart';
import 'package:seiyun_reports_app/core/widgets/report_status_tracker.dart';
import 'package:seiyun_reports_app/screens/report/models/report_model.dart';
import 'package:seiyun_reports_app/screens/report/utils/report_guards.dart';
import 'package:seiyun_reports_app/screens/services/data/service_request_repository.dart';
import 'package:seiyun_reports_app/screens/services/model/service_request.dart';
import 'package:seiyun_reports_app/screens/services/viewmodel/services_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ApiService وهمي للاختبار يعيد استجابة/خطأ محدداً دون أي اتصال حقيقي.
class _FakeApi extends ApiService {
  final Future<Response> Function(String path, dynamic data) onPost;
  int calls = 0;

  _FakeApi(this.onPost) : super(DioClient());

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) {
    calls++;
    return onPost(path, data);
  }
}

DioException _http(int code) {
  final ro = RequestOptions(path: 'x');
  return DioException(
    requestOptions: ro,
    response: Response(requestOptions: ro, statusCode: code),
    type: DioExceptionType.badResponse,
  );
}

ReportModel _report({
  String status = 'قيد الانتظار',
  String type = 'رفع',
  String lat = '15.9430',
  String lng = '48.7840',
  String? createdAt,
}) => ReportModel(
  id: 1,
  citizenId: 1,
  title: 't',
  description: 'd',
  image: '',
  status: status,
  reportType: type,
  lat: lat,
  lng: lng,
  createdAt: createdAt ?? DateTime.now().toIso8601String(),
);

void main() {
  group('دورة حالة البلاغ', () {
    test('توحيد التهجئات العربية والإنجليزية', () {
      expect(ReportStatus.fromServer('قيد الإنتظار'), ReportStatus.newReport);
      expect(ReportStatus.fromServer('قيد الانتظار'), ReportStatus.newReport);
      expect(ReportStatus.fromServer('under_review'), ReportStatus.underReview);
      expect(ReportStatus.fromServer('قيد المعالجة'), ReportStatus.inProgress);
      expect(ReportStatus.fromServer('تم الإنجاز'), ReportStatus.resolved);
      expect(ReportStatus.fromServer('Closed'), ReportStatus.closed);
      expect(ReportStatus.fromServer('مرفوض'), ReportStatus.rejected);
      expect(ReportStatus.fromServer(''), ReportStatus.unknown);
      expect(ReportStatus.fromServer('شيء آخر'), ReportStatus.unknown);
    });

    test('ترتيب المراحل', () {
      expect(ReportStatus.pipeline.first, ReportStatus.newReport);
      expect(ReportStatus.pipeline.last, ReportStatus.closed);
      expect(ReportStatus.rejected.step, -1);
      expect(ReportStatus.rejected.isFinal, isTrue);
    });

    test('النموذج يقرأ سبب الرفض ولا يسرّب JSON عند الخطأ', () {
      final r = ReportModel.fromJson({
        'id': 5,
        'status': 'مرفوض',
        'rejection_reason': 'خارج اختصاص الصندوق',
      });
      expect(r.statusStage, ReportStatus.rejected);
      expect(r.rejectionReason, 'خارج اختصاص الصندوق');

      final broken = ReportModel.fromJson({'id': 'not-a-number', 'secret': 'x'});
      expect(broken.description, isEmpty);
    });

    testWidgets('عرض سبب الرفض في شريط الحالة', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReportStatusTracker(
              status: ReportStatus.rejected,
              rejectionReason: 'بلاغ مكرر',
            ),
          ),
        ),
      );
      expect(find.text('سبب الرفض: بلاغ مكرر'), findsOneWidget);
    });

    testWidgets('شريط التقدم يعرض كل المراحل', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReportStatusTracker(status: ReportStatus.inProgress),
          ),
        ),
      );
      expect(find.byType(CircleAvatar), findsNWidgets(5));
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });
  });

  group('حماية البلاغات', () {
    test('توقيع الصور', () {
      expect(ReportGuards.looksLikeImage([0xFF, 0xD8, 0xFF, 0xE0]), isTrue);
      expect(ReportGuards.looksLikeImage([0x89, 0x50, 0x4E, 0x47]), isTrue);
      expect(ReportGuards.looksLikeImage('MZ\u0090\u0000'.codeUnits), isFalse);
      expect(ReportGuards.looksLikeImage('<?php'.codeUnits), isFalse);
      expect(ReportGuards.looksLikeImage([]), isFalse);
    });

    test('حساب المسافة', () {
      final d = ReportGuards.distanceMeters(15.9430, 48.7840, 15.9431, 48.7840);
      expect(d, closeTo(11.1, 0.5));
    });

    test('اكتشاف البلاغ المكرر', () {
      final now = DateTime(2026, 11, 14, 12);
      final prev = [
        _report(createdAt: now.subtract(const Duration(hours: 2)).toIso8601String()),
      ];
      expect(
        ReportGuards.findLikelyDuplicate(
          previous: prev, type: 'رفع', lat: 15.94301, lng: 48.78401, now: now,
        ),
        isNotNull,
      );
      // نوع مختلف
      expect(
        ReportGuards.findLikelyDuplicate(
          previous: prev, type: 'كنس', lat: 15.9430, lng: 48.7840, now: now,
        ),
        isNull,
      );
      // بعيد
      expect(
        ReportGuards.findLikelyDuplicate(
          previous: prev, type: 'رفع', lat: 15.9500, lng: 48.7840, now: now,
        ),
        isNull,
      );
      // قديم
      expect(
        ReportGuards.findLikelyDuplicate(
          previous: prev, type: 'رفع', lat: 15.9430, lng: 48.7840,
          now: now.add(const Duration(days: 2)),
        ),
        isNull,
      );
      // تم حله
      expect(
        ReportGuards.findLikelyDuplicate(
          previous: [_report(status: 'تم الحل', createdAt: now.toIso8601String())],
          type: 'رفع', lat: 15.9430, lng: 48.7840, now: now,
        ),
        isNull,
      );
    });
  });

  group('طلبات الخدمات', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PrefHelper.init();
    });

    test('رقم الجوال اليمني', () {
      expect(ServiceRequest.normalizeYemeniPhone('771234567'), '771234567');
      expect(ServiceRequest.normalizeYemeniPhone('+967 77 123 4567'), '771234567');
      expect(ServiceRequest.normalizeYemeniPhone('00967771234567'), '771234567');
      expect(ServiceRequest.normalizeYemeniPhone('٧٧١٢٣٤٥٦٧'), '771234567');
      expect(ServiceRequest.normalizeYemeniPhone('12345'), isNull);
      expect(ServiceRequest.normalizeYemeniPhone('571234567'), isNull);
    });

    test('الطلب لا يرسل السعر من التطبيق', () {
      final json = ServiceRequest(
        serviceId: '1',
        serviceTitle: 'x',
        preferredDate: DateTime(2026, 12, 1),
        timeSlot: 'مساءً',
        phone: '771234567',
        notes: '',
        clientRequestId: 'abc',
      ).toJson();
      expect(json.containsKey('price'), isFalse);
      expect(json['preferred_date'], '2026-12-01');
      expect(json['payment_method'], 'cash_on_service');
    });

    test('رقم غير صالح يمنع الإرسال دون أي طلب شبكة', () async {
      final api = _FakeApi((_, __) async => throw StateError('should not call'));
      final vm = ServicesViewModel(repository: ServiceRequestRepository(api));
      vm.phoneController.text = '123';
      final r = await vm.submitOrder();
      expect(r.status, ServiceSubmitStatus.failed);
      expect(api.calls, 0);
      vm.dispose();
    });

    test('النجاح فقط عند تأكيد الخادم ويعيد الرقم المرجعي', () async {
      final api = _FakeApi(
        (path, data) async => Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 201,
          data: {
            'data': {'reference_number': 'SRV-0001'},
          },
        ),
      );
      final vm = ServicesViewModel(repository: ServiceRequestRepository(api));
      vm.phoneController.text = '771234567';
      final r = await vm.submitOrder();
      expect(r.status, ServiceSubmitStatus.accepted);
      expect(r.referenceNumber, 'SRV-0001');
      expect(vm.phoneController.text, isEmpty);
      vm.dispose();
    });

    test('نقطة غير مفعلة على الخادم لا تُعرض كنجاح', () async {
      final api = _FakeApi((_, __) async => throw _http(404));
      final vm = ServicesViewModel(repository: ServiceRequestRepository(api));
      vm.phoneController.text = '771234567';
      final r = await vm.submitOrder();
      expect(r.status, ServiceSubmitStatus.notAvailable);
      // الحقول تبقى كما هي حتى لا يفقد المستخدم ما كتبه
      expect(vm.phoneController.text, '771234567');
      vm.dispose();
    });

    test('أخطاء الخادم والحد من الطلبات', () async {
      for (final code in [422, 429, 500]) {
        final api = _FakeApi((_, __) async => throw _http(code));
        final vm = ServicesViewModel(repository: ServiceRequestRepository(api));
        vm.phoneController.text = '771234567';
        final r = await vm.submitOrder();
        expect(r.status, ServiceSubmitStatus.failed, reason: '$code');
        expect(r.message, isNotNull);
        vm.dispose();
      }
    });
  });
}
