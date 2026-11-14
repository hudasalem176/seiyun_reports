import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seiyun_reports_app/core/auth/account_service.dart';
import 'package:seiyun_reports_app/core/network/api_service.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';
import 'package:seiyun_reports_app/screens/auth/view/widgets/auth_text_field.dart';

/// إدارة أمان الحساب: تغيير كلمة المرور، تغيير البريد مع إعادة التحقق، حذف الحساب.
class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  late final AccountService _service = AccountService(
    context.read<ApiService>(),
  );
  bool _busy = false;

  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _email = TextEditingController();

  @override
  void dispose() {
    for (final c in [_current, _next, _confirm, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  /// مسح الحقول الحساسة من الذاكرة بعد كل عملية.
  void _clearFields() {
    for (final c in [_current, _next, _confirm, _email]) {
      c.clear();
    }
  }

  void _snack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppTheme.primaryGreen : AppTheme.errorColor,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _run(Future<AccountActionResult> Function() action) async {
    if (_busy) return; // منع النقر المتكرر
    setState(() => _busy = true);
    final r = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(r.message, r.ok);
  }

  Future<void> _changePassword() async {
    _clearFields();
    final current = _current;
    final next = _next;
    final confirm = _confirm;
    final ok = await _formDialog(
      title: 'تغيير كلمة المرور',
      fields: [
        AuthTextField(
          label: 'كلمة المرور الحالية',
          hint: '********',
          controller: current,
          isPassword: true,
          autofillHints: const [AutofillHints.password],
        ),
        const SizedBox(height: 12),
        AuthTextField(
          label: 'كلمة المرور الجديدة',
          hint: '********',
          controller: next,
          isPassword: true,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: 12),
        AuthTextField(
          label: 'تأكيد كلمة المرور الجديدة',
          hint: '********',
          controller: confirm,
          isPassword: true,
        ),
      ],
    );
    final values = (current.text, next.text, confirm.text);
    _clearFields();
    if (ok != true) return;
    if (values.$2 != values.$3) {
      _snack('كلمتا المرور غير متطابقتين', false);
      return;
    }
    await _run(
      () => _service.changePassword(
        currentPassword: values.$1,
        newPassword: values.$2,
      ),
    );
  }

  Future<void> _changeEmail() async {
    _clearFields();
    final email = _email;
    final password = _current;
    final ok = await _formDialog(
      title: 'تغيير البريد الإلكتروني',
      fields: [
        AuthTextField(
          label: 'البريد الجديد',
          hint: 'example@mail.com',
          controller: email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_service.usesPassword) ...[
          const SizedBox(height: 12),
          AuthTextField(
            label: 'كلمة المرور الحالية',
            hint: '********',
            controller: password,
            isPassword: true,
          ),
        ],
      ],
    );
    final values = (email.text, password.text);
    _clearFields();
    if (ok != true) return;
    await _run(
      () => _service.changeEmail(
        newEmail: values.$1,
        currentPassword: values.$2,
      ),
    );
  }

  Future<void> _deleteAccount() async {
    _clearFields();
    final password = _current;
    final ok = await _formDialog(
      title: 'حذف الحساب نهائياً',
      danger: true,
      fields: [
        const Text(
          'سيتم حذف حسابك وبياناتك الشخصية نهائياً ولا يمكن التراجع عن ذلك. '
          'البلاغات التي أرسلتها قد تبقى لدى الصندوق دون ربطها بهويتك وفق سياسة الصندوق.',
          style: TextStyle(height: 1.6),
        ),
        if (_service.usesPassword) ...[
          const SizedBox(height: 12),
          AuthTextField(
            label: 'أدخل كلمة المرور للتأكيد',
            hint: '********',
            controller: password,
            isPassword: true,
          ),
        ],
      ],
    );
    final pass = password.text;
    _clearFields();
    if (ok != true) return;
    if (_busy) return;
    setState(() => _busy = true);
    final r = await _service.deleteAccount(currentPassword: pass);
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(r.message, r.ok);
    if (r.ok) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  Future<bool?> _formDialog({
    required String title,
    required List<Widget> fields,
    bool danger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: fields),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      danger ? AppTheme.errorColor : AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(danger ? 'حذف نهائي' : 'تأكيد'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('أمان الحساب')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_service.usesPassword)
                _tile(
                  icon: Icons.password_rounded,
                  title: 'تغيير كلمة المرور',
                  subtitle: 'سيتم تسجيل خروج الأجهزة الأخرى تلقائياً',
                  onTap: _changePassword,
                ),
              _tile(
                icon: Icons.alternate_email_rounded,
                title: 'تغيير البريد الإلكتروني',
                subtitle: 'يتطلب تأكيد البريد الجديد عبر رابط',
                onTap: _changeEmail,
              ),
              const SizedBox(height: 24),
              _tile(
                icon: Icons.delete_forever_rounded,
                title: 'حذف الحساب',
                subtitle: 'حذف الحساب والبيانات الشخصية نهائياً',
                color: AppTheme.errorColor,
                onTap: _deleteAccount,
              ),
            ],
          ),
          if (_busy)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: color ?? AppTheme.primaryGreen),
        title: Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: _busy ? null : onTap,
      ),
    );
  }
}
