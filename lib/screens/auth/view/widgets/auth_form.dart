import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seiyun_reports_app/core/auth/auth_validators.dart';
import 'package:seiyun_reports_app/screens/auth/view/email_verification_screen.dart';
import 'package:seiyun_reports_app/screens/auth/view/forgot_password_screen.dart';
import 'package:seiyun_reports_app/screens/root/view/root_screen.dart';
import 'package:seiyun_reports_app/screens/auth/viewmodel/auth_viewmodel.dart';
import 'auth_text_field.dart';
import 'auth_button.dart';
import 'google_signin_button.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  int _strength = 0;

  @override
  void dispose() {
    _confirmController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// عرض رسالة خطأ للمستخدم باستخدام SnackBar.
  void _showErrorSnackBar(String message, [ScaffoldMessengerState? messenger]) {
    (messenger ?? ScaffoldMessenger.of(context)).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.errorColor,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// التحقق من صحة البيانات المدخلة قبل الإرسال (التحقق النهائي يتم على الخادم).
  bool _validateInputs(AuthViewModel authVM) {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (authVM.isSignupMode) {
      final nameError = AuthValidators.validateName(_nameController.text);
      if (nameError != null) {
        _showErrorSnackBar(nameError);
        return false;
      }
    }

    final format = AuthValidators.checkEmailFormat(email);
    if (!format.isValid) {
      _showErrorSnackBar(format.error!);
      return false;
    }
    if (format.suggestion != null) {
      _showErrorSnackBar('هل تقصد ${format.suggestion}؟ تم تصحيح البريد، تأكد منه ثم أعد المحاولة');
      _emailController.text = format.suggestion!;
      return false;
    }

    if (authVM.isSignupMode) {
      final passwordError = AuthValidators.validatePassword(password);
      if (passwordError != null) {
        _showErrorSnackBar(passwordError);
        return false;
      }
      if (password != _confirmController.text) {
        _showErrorSnackBar('كلمتا المرور غير متطابقتين');
        return false;
      }
    } else if (password.isEmpty) {
      _showErrorSnackBar('يرجى إدخال كلمة المرور');
      return false;
    }

    return true;
  }

  /// معالجة عملية المصادقة بالبريد الإلكتروني (إنشاء حساب أو تسجيل دخول).
  Future<void> _handleEmailAuth() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!_validateInputs(authVM)) return;

    FocusScope.of(context).unfocus();
    final outcome = await authVM.handleEmailAuth(
      email: _emailController.text,
      password: _passwordController.text,
      name: authVM.isSignupMode ? _nameController.text : null,
    );

    if (!mounted) return;

    if (outcome == AuthOutcome.success) {
      _passwordController.clear();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootScreen()),
        (route) => false,
      );
    } else if (outcome == AuthOutcome.needsVerification) {
      _passwordController.clear();
      _confirmController.clear();
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        (route) => false,
      );
    } else {
      if (authVM.errorMessage != null) {
        _showErrorSnackBar(authVM.errorMessage!, scaffoldMessenger);
        authVM.clearError();
      }
    }
  }

  /// معالجة عملية تسجيل الدخول باستخدام حساب Google.
  Future<void> _handleGoogleSignIn() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await authVM.handleGoogleSignIn();

    if (!mounted) return;

    if (success) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootScreen()),
        (route) => false,
      );
    } else {
      if (authVM.errorMessage != null) {
        _showErrorSnackBar(authVM.errorMessage!, scaffoldMessenger);
        authVM.clearError();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          const Icon(
            Icons.forest_rounded,
            color: AppTheme.accentGreen,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            authVM.isSignupMode ? 'إنشاء حساب جديد' : 'مرحباً بك مجدداً',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 30),
          if (authVM.isSignupMode) ...[
            AuthTextField(
              label: "الاسم الكامل",
              hint: "أدخل اسمك بالكامل",
              controller: _nameController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),
          ],
          AuthTextField(
            label: "البريد الإلكتروني",
            hint: "example@mail.com",
            controller: _emailController,
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          AuthTextField(
            label: "كلمة المرور",
            hint: "********",
            controller: _passwordController,
            isPassword: true,
            icon: Icons.lock_outline,
            autofillHints: [
              authVM.isSignupMode
                  ? AutofillHints.newPassword
                  : AutofillHints.password,
            ],
            textInputAction:
                authVM.isSignupMode
                    ? TextInputAction.next
                    : TextInputAction.done,
            onSubmitted: authVM.isSignupMode ? null : (_) => _handleEmailAuth(),
            onChanged:
                authVM.isSignupMode
                    ? (v) => setState(
                      () => _strength = AuthValidators.passwordStrength(v),
                    )
                    : null,
          ),
          if (authVM.isSignupMode) ...[
            const SizedBox(height: 8),
            _PasswordStrengthBar(strength: _strength),
            const SizedBox(height: 16),
            AuthTextField(
              label: "تأكيد كلمة المرور",
              hint: "********",
              controller: _confirmController,
              isPassword: true,
              icon: Icons.lock_outline,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleEmailAuth(),
            ),
          ],
          if (!authVM.isSignupMode)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (_) => ForgotPasswordScreen(
                            initialEmail: _emailController.text.trim(),
                          ),
                    ),
                  );
                },
                child: const Text('نسيت كلمة المرور؟'),
              ),
            ),
          SizedBox(height: authVM.isSignupMode ? 30 : 10),
          AuthButton(
            text: authVM.isSignupMode ? 'إنشاء حساب' : 'تسجيل الدخول',
            onPressed: _handleEmailAuth,
          ),
          const SizedBox(height: 25),
          GoogleSignInButton(
            text:
                authVM.isSignupMode
                    ? "تسجيل بواسطة Google"
                    : "الدخول بواسطة Google",
            onTap: _handleGoogleSignIn,
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                authVM.isSignupMode
                    ? "لديك حساب بالفعل؟ "
                    : "ليس لديك حساب؟ ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: () {
                  authVM.toggleSignupMode();
                },
                child: Text(
                  authVM.isSignupMode ? "تسجيل الدخول" : "إنشاء حساب",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10)
        ],
      ),
    );
  }
}

/// مؤشر بسيط لقوة كلمة المرور أثناء إنشاء الحساب.
class _PasswordStrengthBar extends StatelessWidget {
  final int strength;

  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    const labels = ['ضعيفة جداً', 'ضعيفة', 'متوسطة', 'جيدة', 'قوية'];
    final colors = [
      Colors.red,
      Colors.deepOrange,
      Colors.amber,
      Colors.lightGreen,
      AppTheme.primaryGreen,
    ];
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (strength + 1) / 5,
              minHeight: 6,
              color: colors[strength],
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          labels[strength],
          style: TextStyle(fontSize: 12, color: colors[strength]),
        ),
      ],
    );
  }
}
