import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';
import 'package:seiyun_reports_app/screens/auth/view/auth_screen.dart';
import 'package:seiyun_reports_app/screens/auth/view/widgets/auth_button.dart';
import 'package:seiyun_reports_app/screens/auth/viewmodel/auth_viewmodel.dart';
import 'package:seiyun_reports_app/screens/root/view/root_screen.dart';

/// شاشة انتظار تأكيد البريد الإلكتروني. لا يُفعَّل الحساب ولا يُسجَّل لدى الخادم
/// قبل أن يفتح المستخدم رابط التحقق المرسل إلى بريده.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  Timer? _countdownTimer;
  Duration _cooldown = Duration.zero;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshCooldown();
    // فحص دوري خفيف لحالة التفعيل.
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) => _check(true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // عند عودة المستخدم من تطبيق البريد نفحص مباشرة.
    if (state == AppLifecycleState.resumed) _check(true);
  }

  Future<void> _refreshCooldown() async {
    final vm = context.read<AuthViewModel>();
    final d = await vm.verificationCooldown();
    if (!mounted) return;
    setState(() => _cooldown = d);
    _countdownTimer?.cancel();
    if (d > Duration.zero) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() {
          _cooldown -= const Duration(seconds: 1);
          if (_cooldown <= Duration.zero) {
            _cooldown = Duration.zero;
            t.cancel();
          }
        });
      });
    }
  }

  Future<void> _check(bool silent) async {
    if (_navigated) return;
    final vm = context.read<AuthViewModel>();
    if (silent && vm.isLoading) return;
    final outcome = await vm.checkEmailVerified(silent: silent);
    if (!mounted) return;
    if (outcome == AuthOutcome.success) {
      _navigated = true;
      _pollTimer?.cancel();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootScreen()),
        (route) => false,
      );
    } else if (!silent && vm.errorMessage != null) {
      _snack(vm.errorMessage!, error: true);
      vm.clearError();
    }
  }

  Future<void> _resend() async {
    final vm = context.read<AuthViewModel>();
    final ok = await vm.resendVerificationEmail();
    if (!mounted) return;
    if (ok) {
      _snack('تم إرسال رسالة تحقق جديدة، تفقد صندوق الوارد والبريد المزعج');
    } else if (vm.errorMessage != null) {
      _snack(vm.errorMessage!, error: true);
      vm.clearError();
    }
    _refreshCooldown();
  }

  Future<void> _useAnotherAccount() async {
    _pollTimer?.cancel();
    await context.read<AuthViewModel>().signOutPending();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? AppTheme.errorColor : AppTheme.primaryGreen,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  String get _cooldownText {
    final m = _cooldown.inMinutes;
    final s = (_cooldown.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final email = vm.currentUser?.email ?? '';
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 56,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'تأكيد البريد الإلكتروني',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'أرسلنا رابط تفعيل إلى',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      email,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'افتح الرسالة واضغط على رابط التفعيل، ثم عد إلى التطبيق. '
                    'صلاحية الرابط محدودة ويُستخدم مرة واحدة فقط. '
                    'إن لم تجد الرسالة فتفقد مجلد البريد المزعج (Spam).',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.6),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AuthButton(
                    text: vm.isLoading ? 'جارٍ التحقق...' : 'لقد فعّلت حسابي',
                    onPressed: vm.isLoading ? () {} : () => _check(false),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed:
                          (_cooldown > Duration.zero || vm.isLoading)
                              ? null
                              : _resend,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        _cooldown > Duration.zero
                            ? 'إعادة الإرسال بعد $_cooldownText'
                            : 'إعادة إرسال رسالة التحقق',
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: vm.isLoading ? null : _useAnotherAccount,
                    child: const Text('استخدام بريد آخر / تسجيل الخروج'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
