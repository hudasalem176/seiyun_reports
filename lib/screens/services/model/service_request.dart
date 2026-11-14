/// طلب خدمة نظافة خاصة (مدفوعة) يُرسل إلى الخادم.
///
/// لا نرسل السعر من التطبيق: السعر النهائي يحدده الخادم/الإدارة دائماً
/// حتى لا يمكن التلاعب به بإرسال طلب API مباشر.
class ServiceRequest {
  final String serviceId;
  final String serviceTitle;
  final DateTime preferredDate;
  final String timeSlot;
  final String phone;
  final String notes;
  final double? latitude;
  final double? longitude;
  final PaymentMethod paymentMethod;

  /// مفتاح فريد يمنع إنشاء طلب مكرر عند إعادة الإرسال (Idempotency-Key).
  final String clientRequestId;

  const ServiceRequest({
    required this.serviceId,
    required this.serviceTitle,
    required this.preferredDate,
    required this.timeSlot,
    required this.phone,
    required this.notes,
    required this.clientRequestId,
    this.latitude,
    this.longitude,
    this.paymentMethod = PaymentMethod.cashOnService,
  });

  Map<String, dynamic> toJson() => {
    'service_id': serviceId,
    'preferred_date':
        '${preferredDate.year.toString().padLeft(4, '0')}-'
        '${preferredDate.month.toString().padLeft(2, '0')}-'
        '${preferredDate.day.toString().padLeft(2, '0')}',
    'time_slot': timeSlot,
    'phone': phone,
    'notes': notes,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'payment_method': paymentMethod.apiValue,
    'client_request_id': clientRequestId,
  };

  /// نص الطلب لإرساله عبر البريد كقناة بديلة عند عدم تفعيل الخدمة على الخادم.
  String toPlainText() {
    final d =
        '${preferredDate.day}/${preferredDate.month}/${preferredDate.year}';
    return 'طلب خدمة: $serviceTitle\n'
        'التاريخ المفضل: $d - $timeSlot\n'
        'رقم التواصل: $phone\n'
        '${latitude != null ? 'الموقع: https://maps.google.com/?q=$latitude,$longitude\n' : ''}'
        '${notes.isNotEmpty ? 'ملاحظات: $notes\n' : ''}';
  }

  /// يتحقق من رقم الجوال اليمني: 9 أرقام تبدأ بـ 7 (مع أو بدون 967+ / 00967).
  static String? normalizeYemeniPhone(String raw) {
    var p = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    // تحويل الأرقام العربية/الفارسية إلى لاتينية.
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    for (var i = 0; i < 10; i++) {
      p = p.replaceAll(arabic[i], '$i').replaceAll(persian[i], '$i');
    }
    if (p.startsWith('+967')) p = p.substring(4);
    if (p.startsWith('00967')) p = p.substring(5);
    if (p.startsWith('967') && p.length == 12) p = p.substring(3);
    return RegExp(r'^7[0-9]{8}$').hasMatch(p) ? p : null;
  }
}

/// طرق الدفع. لا يوجد حالياً دفع إلكتروني حقيقي، لذلك الطريقة الوحيدة المفعّلة
/// هي الدفع عند تنفيذ الخدمة. عند ربط بوابة دفع تُضاف قيمة جديدة وتنفيذ لـ [PaymentGateway].
enum PaymentMethod {
  cashOnService('cash_on_service', 'الدفع عند تنفيذ الخدمة');

  final String apiValue;
  final String label;

  const PaymentMethod(this.apiValue, this.label);
}

/// نقطة الربط المستقبلية مع بوابة دفع.
///
/// قواعد إلزامية عند التنفيذ:
/// - لا تُدخَل بيانات البطاقة في واجهات التطبيق نفسه؛ استخدم صفحة/SDK البوابة (PCI DSS).
/// - المبلغ يُنشأ على الخادم (payment intent) ولا يُرسل من التطبيق.
/// - تأكيد الدفع يتم عبر Webhook موقّع من البوابة إلى الخادم، وليس عبر استجابة التطبيق.
abstract class PaymentGateway {
  /// يبدأ عملية الدفع لطلب أنشأه الخادم ويعيد true عند نجاح البوابة.
  Future<bool> pay({required String serverOrderId});
}
