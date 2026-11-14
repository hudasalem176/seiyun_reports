import 'dart:math';

import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/core/utils/pref_helper.dart';
import '../data/service_request_repository.dart';
import '../model/service_model.dart';
import '../model/service_request.dart';

class ServicesViewModel extends ChangeNotifier {
  final List<AppService> availableServices = [
    AppService(
      id: '1',
      title: 'رفع نفايات كبيرة',
      subtitle: 'رفع الأثاث والنفايات الكبيرة',
      price: 3000,
      icon: Icons.local_shipping,
      iconBgColor: const Color(0xFF4285F4),
    ),
    AppService(
      id: '2',
      title: 'حاوية خاصة',
      subtitle: 'طلب حاوية إضافية مؤقتة',
      price: 5000,
      icon: Icons.delete_outline,
      iconBgColor: const Color(0xFF34A853),
    ),
    AppService(
      id: '3',
      title: 'خدمة فعالية',
      subtitle: 'إدارة النفايات للفعاليات',
      priceLabel: 'حسب الحجم',
      icon: Icons.group_outlined,
      iconBgColor: const Color(0xFFD94B1B),
    ),
    AppService(
      id: '4',
      title: 'تنظيف شامل',
      subtitle: 'تنظيف عميق للمنطقة',
      price: 6000,
      icon: Icons.cleaning_services_outlined,
      iconBgColor: const Color(0xFFC539DB),
    ),
    AppService(
      id: '5',
      title: 'صيانة حاوية',
      subtitle: 'صيانة أو استبدال حاوية',
      price: 5000,
      icon: Icons.handyman_outlined,
      iconBgColor: const Color(0xFFFBBC05),
    ),
  ];

  AppService? _selectedService;
  AppService? get selectedService => _selectedService;

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  String? _selectedTime;
  String? get selectedTime => _selectedTime;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final ServiceRequestRepository? _repository;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  /// يبقى ثابتاً لنفس الطلب حتى ينجح، فلا يُنشئ الخادم طلباً مكرراً عند إعادة المحاولة.
  String _clientRequestId = _newRequestId();

  static String _newRequestId() {
    final r = Random.secure();
    return List.generate(
      16,
      (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// الأسعار المعروضة تقديرية؛ السعر النهائي يؤكده الصندوق.
  static const String priceDisclaimer =
      'الأسعار تقديرية، ويؤكد الصندوق التكلفة النهائية قبل التنفيذ. الدفع عند تنفيذ الخدمة.';

  ServicesViewModel({ServiceRequestRepository? repository})
    : _repository = repository {
    _selectedService = availableServices[3];
    _selectedTime = "مساءً";
    _selectedDate = DateTime.now();
  }

  /// يحدد الخدمة المختارة ويخطر المستمعين بالتغيير.
  void selectService(AppService service) {
    _selectedService = service;
    notifyListeners();
  }

  /// يحدد التاريخ المختار ويخطر المستمعين بالتغيير.
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// يحدد الوقت المختار ويخطر المستمعين بالتغيير.
  void selectTime(String time) {
    _selectedTime = time;
    notifyListeners();
  }

  /// التحقق من الطلب؛ يعيد رسالة خطأ أو null إذا كان صالحاً.
  String? validate() {
    if (_selectedService == null) return 'يرجى اختيار نوع الخدمة';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (_selectedDate == null || _selectedDate!.isBefore(today)) {
      return 'يرجى اختيار تاريخ صحيح';
    }
    if (_selectedTime == null) return 'يرجى اختيار الوقت المفضل';
    if (ServiceRequest.normalizeYemeniPhone(phoneController.text) == null) {
      return 'رقم الجوال غير صحيح، أدخل 9 أرقام تبدأ بـ 7';
    }
    if (notesController.text.length > 500) {
      return 'الملاحظات طويلة جداً (500 حرف كحد أقصى)';
    }
    return null;
  }

  Future<ServiceRequest> buildRequest() async {
    final lat = await PrefHelper.getUserLat();
    final lng = await PrefHelper.getUserLng();
    return ServiceRequest(
      serviceId: _selectedService!.id,
      serviceTitle: _selectedService!.title,
      preferredDate: _selectedDate!,
      timeSlot: _selectedTime!,
      phone: ServiceRequest.normalizeYemeniPhone(phoneController.text)!,
      notes: notesController.text.trim(),
      latitude: lat,
      longitude: lng,
      clientRequestId: _clientRequestId,
    );
  }

  /// إرسال الطلب إلى الخادم فعلياً. لا يُعرض نجاح إلا إذا أكد الخادم الاستلام.
  Future<ServiceSubmitResult> submitOrder() async {
    if (_isSubmitting) {
      return const ServiceSubmitResult(ServiceSubmitStatus.failed);
    }
    final error = validate();
    if (error != null) {
      return ServiceSubmitResult(ServiceSubmitStatus.failed, message: error);
    }
    final repo = _repository;
    if (repo == null) {
      return const ServiceSubmitResult(ServiceSubmitStatus.notAvailable);
    }
    _isSubmitting = true;
    notifyListeners();
    try {
      final result = await repo.submit(await buildRequest());
      if (result.status == ServiceSubmitStatus.accepted) _reset();
      return result;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _reset() {
    _selectedService = availableServices[3];
    _selectedTime = "مساءً";
    _selectedDate = DateTime.now();
    phoneController.clear();
    notesController.clear();
    _clientRequestId = _newRequestId();
  }

  @override
  void dispose() {
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
