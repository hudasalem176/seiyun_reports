import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/screens/profile/viewmodel/profile_viewmodel.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:seiyun_reports_app/core/database/database_helper.dart';

class LogoutButton extends StatelessWidget {
  final ProfileViewModel viewModel;

  const LogoutButton({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout, color: Colors.red),
        ),
        title: Text(
          "profile.logout".tr(),
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        onTap: () async {
          // تأكيد قبل الخروج، مع التنبيه إلى البلاغات غير المرسلة التي ستُحذف من الجهاز.
          int pending = 0;
          try {
            pending = await DatabaseHelper().pendingReportsCount();
          } catch (_) {}
          if (!context.mounted) return;
          final confirmed = await showDialog<bool>(
            context: context,
            builder:
                (ctx) => AlertDialog(
                  title: Text("profile.logout".tr()),
                  content: Text(
                    pending > 0
                        ? 'لديك $pending بلاغ/بلاغات محفوظة على الجهاز ولم تُرسل بعد بسبب انقطاع الإنترنت، '
                            'وستُحذف عند تسجيل الخروج. هل تريد المتابعة؟'
                        : 'هل تريد تسجيل الخروج؟ سيتم مسح بياناتك من هذا الجهاز.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('إلغاء'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
          );
          if (confirmed != true) return;
          await viewModel.logout();
          if (context.mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false);
          }
        },
      ),
    );
  }
}
