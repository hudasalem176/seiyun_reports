import 'dart:io';
import 'dart:math';

import 'package:seiyun_reports_app/core/models/report_status.dart';
import 'package:seiyun_reports_app/screens/report/models/report_model.dart';

/// فحوصات قبل إرسال البلاغ (في التطبيق). الخادم يجب أن يعيد نفس الفحوصات
/// لأن من يرسل طلب API مباشر يتجاوز التطبيق.
class ReportGuards {
  ReportGuards._();

  static const int maxImageBytes = 8 * 1024 * 1024;
  static const Set<String> allowedImageExtensions = {
    'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif',
  };

  /// يتحقق من نوع الصورة وحجمها، ومن توقيع الملف (magic bytes) وليس الامتداد فقط.
  static Future<String?> validateImage(File file) async {
    final name = file.path.toLowerCase();
    final ext = name.contains('.') ? name.split('.').last : '';
    if (!allowedImageExtensions.contains(ext)) {
      return 'نوع الملف غير مدعوم، يرجى اختيار صورة (JPG أو PNG)';
    }
    final length = await file.length();
    if (length == 0) return 'الصورة تالفة، اختر صورة أخرى';
    if (length > maxImageBytes) {
      return 'حجم الصورة كبير جداً (الحد الأقصى 8 ميجابايت)';
    }
    final raf = await file.open();
    try {
      final head = await raf.read(12);
      if (!looksLikeImage(head)) return 'الملف المختار ليس صورة صالحة';
    } finally {
      await raf.close();
    }
    return null;
  }

  static bool looksLikeImage(List<int> h) {
    if (h.length < 4) return false;
    final jpeg = h[0] == 0xFF && h[1] == 0xD8 && h[2] == 0xFF;
    final png = h[0] == 0x89 && h[1] == 0x50 && h[2] == 0x4E && h[3] == 0x47;
    final riff = h.length >= 12 && h[0] == 0x52 && h[1] == 0x49 && h[8] == 0x57 && h[9] == 0x45;
    // HEIC/HEIF: "ftyp" في البايتات 4-7
    final ftyp = h.length >= 8 && h[4] == 0x66 && h[5] == 0x74 && h[6] == 0x79 && h[7] == 0x70;
    return jpeg || png || riff || ftyp;
  }

  /// المسافة بالمتر بين نقطتين (Haversine).
  static double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    double rad(double d) => d * pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(rad(lat1)) * cos(rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * r * asin(sqrt(a));
  }

  /// يبحث عن بلاغ سابق للمستخدم بنفس النوع وقريب جداً من الموقع خلال 24 ساعة
  /// ولم يُحل بعد، لتنبيهه قبل إرسال بلاغ مكرر.
  static ReportModel? findLikelyDuplicate({
    required List<ReportModel> previous,
    required String type,
    required double lat,
    required double lng,
    DateTime? now,
    double radiusMeters = 40,
    Duration window = const Duration(hours: 24),
  }) {
    final t = now ?? DateTime.now();
    for (final r in previous) {
      if (r.reportType != type) continue;
      final stage = r.statusStage;
      if (stage == ReportStatus.resolved ||
          stage == ReportStatus.closed ||
          stage == ReportStatus.rejected) {
        continue;
      }
      final created = DateTime.tryParse(r.createdAt);
      if (created == null || t.difference(created) > window) continue;
      final rl = double.tryParse(r.lat);
      final rg = double.tryParse(r.lng);
      if (rl == null || rg == null || (rl == 0 && rg == 0)) continue;
      if (distanceMeters(lat, lng, rl, rg) <= radiusMeters) return r;
    }
    return null;
  }
}
