import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seiyun_reports_app/repositories/auth_repository.dart';
import 'package:seiyun_reports_app/screens/Home.dart';

/// ===============================
/// تعريف ألوان التطبيق
/// ===============================
const primaryGreen = Color(0xFF2E7D32);
const primaryBrown = Color(0xFF5D4037);
const darkRed = Color(0xCD8B0000);

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  /// التحكم في إظهار كلمة المرور
  bool _isObscure = true;

  /// تحديد وضع الشاشة (تسجيل / دخول)
  bool isSignupMode = true;

  /// حالة التحميل
  bool isLoading = false;

  /// Controllers للحقول النصية
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  /// كائن Google Sign In
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// كائن FirebaseAuth لتقليل تكرار الاستدعاء
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ===============================
  /// تهيئة Google Sign In عند تشغيل الصفحة
  /// ===============================
  @override
  void initState() {
    super.initState();
  }

  /// ===============================
  /// التخلص من Controllers لتجنب تسريب الذاكرة
  /// ===============================
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// ===============================
  /// إظهار رسالة خطأ للمستخدم
  /// ===============================
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: darkRed,
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

  /// ===============================
  /// الانتقال إلى الصفحة الرئيسية
  /// ===============================
  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  /// ===============================
  /// التحقق من صحة المدخلات
  /// ===============================
  bool _validateInputs() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showErrorSnackBar("يرجى إدخال البريد الإلكتروني وكلمة المرور");
      return false;
    }

    if (isSignupMode && _nameController.text.trim().isEmpty) {
      _showErrorSnackBar("يرجى إدخال الاسم الكامل");
      return false;
    }

    return true;
  }

  /// ===============================
  /// تسجيل الدخول أو إنشاء حساب بالإيميل
  /// ===============================
  Future<void> _handleEmailAuth() async {
    if (!_validateInputs()) return;

    setState(() => isLoading = true);

    try {

      /// إنشاء حساب جديد
      if (isSignupMode) {

        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (_nameController.text.isNotEmpty) {
          await _auth.currentUser?.updateDisplayName(
            _nameController.text.trim(),
          );
        }

      }
      /// تسجيل دخول
      else {

        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

      }

      /// المستخدم الحالي
      final user = _auth.currentUser;

      if (user != null) {

        /// طباعة التوكن (للاختبار مع Laravel)
        final token = await user.getIdToken();
        debugPrint("FIREBASE_TOKEN: $token");

        /// مزامنة المستخدم مع Laravel
        final authRepo = AuthRepository();

        await authRepo.registerUser(
          role: 'citizens',
          name: _nameController.text.isEmpty
              ? (user.displayName ?? "User")
              : _nameController.text.trim(),
        );

        if (!mounted) return;

        _goToHome();
      }

    } on FirebaseAuthException catch (e) {

      _showErrorSnackBar(e.message ?? "حدث خطأ غير متوقع");

    } catch (e) {

      _showErrorSnackBar("فشل الربط مع الخادم");

    } finally {

      if (mounted) {
        setState(() => isLoading = false);
      }

    }
  }

  /// ===============================
  /// تسجيل الدخول باستخدام Google
  /// ===============================
  Future<void> _handleGoogleSignIn() async {

    setState(() => isLoading = true);

    try {

      /// فتح نافذة اختيار حساب جوجل
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      /// الحصول على بيانات التوثيق
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      /// إنشاء Credential للفirebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      /// تسجيل الدخول في Firebase
      final userCredential =
      await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {

        final authRepo = AuthRepository();

        /// استخراج الاسم
        final finalName = user.displayName ??
            (user.email != null
                ? user.email!.split('@')[0]
                : "User");

        /// إرسال البيانات إلى Laravel
        await authRepo.registerUser(
          role: 'citizens',
          name: finalName,
        );

        if (!mounted) return;

        _goToHome();
      }

    } catch (e) {

      _showErrorSnackBar("فشل تسجيل الدخول بواسطة Google");

    } finally {

      if (mounted) {
        setState(() => isLoading = false);
      }

    }
  }

  /// ===============================
  /// بناء واجهة الشاشة
  /// ===============================
  @override
  Widget build(BuildContext context) {

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [

          /// خلفية الشاشة
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          /// زر الرجوع في حالة تسجيل الدخول
          if (!isSignupMode)
            Positioned(
              top: 50,
              left: 20,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    isSignupMode = true;
                  });
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "Back",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          /// واجهة الإدخال
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.8,
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 30,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
              ),

              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: primaryGreen,
                ),
              )
                  : _buildAuthForm(),
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// بناء نموذج تسجيل الدخول
  /// ===============================
  Widget _buildAuthForm() {

    return SingleChildScrollView(
      child: Column(
        children: [

          const Icon(
            Icons.forest_rounded,
            color: primaryGreen,
            size: 40,
          ),

          const SizedBox(height: 10),

          Text(
            isSignupMode ? 'Get Started' : 'Welcome Back',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),

          const SizedBox(height: 30),

          if (isSignupMode) ...[
            _buildTextField(
              "Full Name",
              "Enter Full Name",
              _nameController,
            ),
            const SizedBox(height: 20),
          ],

          _buildTextField("Email", "Enter Email", _emailController),

          const SizedBox(height: 20),

          _buildTextField(
            "Password",
            "Enter Password",
            _passwordController,
            isPassword: true,
          ),

          const SizedBox(height: 30),

          /// زر تسجيل الدخول
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _handleEmailAuth,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrown,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                isSignupMode ? 'Sign up' : 'Log in',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          /// تسجيل الدخول بجوجل
          InkWell(
            onTap: _handleGoogleSignIn,
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/google.png',
                        width: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSignupMode
                            ? "Sign up with Google"
                            : "Log in with Google",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),

          const SizedBox(height: 25),

          /// تبديل بين تسجيل الدخول والتسجيل
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isSignupMode
                    ? "Already have an account? "
                    : "Don't have an account? ",
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    isSignupMode = !isSignupMode;
                  });
                },
                child: Text(
                  isSignupMode ? "Log in" : "Sign up",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// حقل إدخال نصي
  /// ===============================
  Widget _buildTextField(
      String label,
      String hint,
      TextEditingController controller, {
        bool isPassword = false,
      }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: primaryBrown,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          obscureText: isPassword ? _isObscure : false,
          decoration: InputDecoration(
            hintText: hint,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: primaryGreen,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Colors.black12,
              ),
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _isObscure
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: primaryGreen,
              ),
              onPressed: () {
                setState(() {
                  _isObscure = !_isObscure;
                });
              },
            )
                : null,
          ),
        ),
      ],
    );
  }
}