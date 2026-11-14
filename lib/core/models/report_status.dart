import 'package:flutter/material.dart';

/// دورة حياة البلاغ الموحدة:
/// جديد → قيد المراجعة → قيد المعالجة → تم الحل → مغلق، مع إمكانية الرفض.
///
/// الحالة تُعرض فقط في التطبيق؛ تغييرها صلاحية للإدارة/المشرف على الخادم،
/// ولا توجد في تطبيق المواطن أي واجهة أو طلب API لتغييرها.
enum ReportStatus {
  newReport('قيد الانتظار', Icons.fiber_new_rounded, Color(0xFFF39C12)),
  underReview('قيد المراجعة', Icons.manage_search_rounded, Color(0xFF8E44AD)),
  inProgress('قيد المعالجة', Icons.engineering_rounded, Color(0xFF2980B9)),
  resolved('تم الحل', Icons.check_circle_rounded, Color(0xFF27AE60)),
  closed('مغلق', Icons.lock_rounded, Color(0xFF7F8C8D)),
  rejected('مرفوض', Icons.cancel_rounded, Color(0xFFE74C3C)),
  unknown('غير معروف', Icons.help_outline_rounded, Color(0xFF95A5A6));

  final String label;
  final IconData icon;
  final Color color;

  const ReportStatus(this.label, this.icon, this.color);

  /// المراحل الخطية التي تُعرض في شريط التقدم (الرفض مسار منفصل).
  static const List<ReportStatus> pipeline = [
    newReport,
    underReview,
    inProgress,
    resolved,
    closed,
  ];

  /// القيمة الافتراضية للبلاغ الجديد/غير المرفوع بعد (تُحفظ محلياً).
  static const String pendingLabel = 'قيد الانتظار';

  int get step => pipeline.indexOf(this);

  bool get isFinal => this == closed || this == rejected;

  /// تحويل القيمة القادمة من الخادم (عربي أو إنجليزي، بتهجئات مختلفة) إلى حالة موحدة.
  static ReportStatus fromServer(String? raw) {
    final v = (raw ?? '').trim().toLowerCase().replaceAll('إ', 'ا').replaceAll('أ', 'ا');
    if (v.isEmpty) return unknown;
    const map = <String, ReportStatus>{
      'new': newReport, 'pending': newReport, 'جديد': newReport,
      'قيد الانتظار': newReport, 'بانتظار المراجعة': newReport,
      'under_review': underReview, 'under review': underReview,
      'reviewing': underReview, 'قيد المراجعة': underReview,
      'in_progress': inProgress, 'in progress': inProgress,
      'processing': inProgress, 'قيد المعالجة': inProgress,
      'قيد التنفيذ': inProgress,
      'resolved': resolved, 'done': resolved, 'completed': resolved,
      'تم الحل': resolved, 'تم الانجاز': resolved, 'منجز': resolved,
      'closed': closed, 'مغلق': closed, 'تم الاغلاق': closed,
      'rejected': rejected, 'مرفوض': rejected, 'تم الرفض': rejected,
    };
    return map[v] ?? unknown;
  }
}
