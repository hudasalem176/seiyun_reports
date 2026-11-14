import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';
import 'package:seiyun_reports_app/screens/auth/view/widgets/auth_button.dart';
import 'package:seiyun_reports_app/screens/auth/view/widgets/auth_text_field.dart';
import 'package:seiyun_reports_app/screens/auth/viewmodel/auth_viewmodel.dart';

/// استعادة كلمة المرور عبر رابط يُرسل إلى البريد الإلكتروني.
///
/// الرابط صالح لمدة محدودة (ساعة واحدة في Firebase)، ويُستخدم مرة واحدة، ويُبطَل
/// تلقائياً عند تعيين كلمة مرور جديدة، كما تُلغى جلسات الأجهزة الأخرى بعد التغيير.
class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail ?? '',
  );
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final vm = context.read<AuthViewModel>();
    final ok = await vm.sendPasswordReset(_emailController.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _sent = true);
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.errorColor,
          content: Text(
            vm.errorMessage!,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      vm.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_reset_rounded,
                size: 64,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 20),
              if (!_sent) ...[
                Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لتعيين كلمة مرور جديدة.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AuthTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'example@mail.com',
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 28),
                AuthButton(
                  text: vm.isLoading ? 'جارٍ الإرسال...' : 'إرسال رابط الاستعادة',
                  onPressed: vm.isLoading ? () {} : _submit,
                ),
              ] else ...[
                Text(
                  'تحقق من بريدك',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // رسالة موحدة لا تكشف إن كان البريد مسجلاً أم لا.
                Text(
                  'إذا كان هذا البريد مرتبطاً بحساب لدينا، فستصلك رسالة تحتوي على '
                  'رابط لتعيين كلمة مرور جديدة خلال دقائق.\n'
                  'الرابط صالح لمدة ساعة ويمكن استخدامه مرة واحدة فقط. '
                  'تفقد مجلد البريد المزعج إن لم تجد الرسالة.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                AuthButton(
                  text: 'العودة لتسجيل الدخول',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() => _sent = false),
                  child: const Text('لم تصلني الرسالة؟ إعادة الطلب'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
