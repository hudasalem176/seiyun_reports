import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/core/models/report_status.dart';

/// شارة حالة البلاغ.
class ReportStatusChip extends StatelessWidget {
  final ReportStatus status;
  final String? fallbackLabel;

  const ReportStatusChip({super.key, required this.status, this.fallbackLabel});

  @override
  Widget build(BuildContext context) {
    final label =
        status == ReportStatus.unknown && (fallbackLabel?.isNotEmpty ?? false)
            ? fallbackLabel!
            : status.label;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// شريط تقدم مراحل البلاغ، مع عرض سبب الرفض إن وُجد.
class ReportStatusTracker extends StatelessWidget {
  final ReportStatus status;
  final String? rejectionReason;

  const ReportStatusTracker({
    super.key,
    required this.status,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ReportStatus.unknown) return const SizedBox.shrink();

    if (status == ReportStatus.rejected) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: status.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: status.color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                (rejectionReason?.trim().isNotEmpty ?? false)
                    ? 'سبب الرفض: ${rejectionReason!.trim()}'
                    : 'تم رفض البلاغ من قبل الإدارة',
                style: TextStyle(color: status.color, fontSize: 12, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    final current = status.step;
    final grey = Theme.of(context).dividerColor;
    return Semantics(
      label: 'حالة البلاغ: ${status.label}',
      child: Row(
        children: [
          for (var i = 0; i < ReportStatus.pipeline.length; i++) ...[
            Tooltip(
              message: ReportStatus.pipeline[i].label,
              child: CircleAvatar(
                radius: 9,
                backgroundColor:
                    i <= current ? ReportStatus.pipeline[i].color : grey,
                child:
                    i < current
                        ? const Icon(Icons.check, size: 11, color: Colors.white)
                        : null,
              ),
            ),
            if (i < ReportStatus.pipeline.length - 1)
              Expanded(
                child: Container(
                  height: 3,
                  color: i < current ? ReportStatus.pipeline[i].color : grey,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
