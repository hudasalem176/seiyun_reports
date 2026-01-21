import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:seiyun_reports_app/screens/Home_Screen.dart';

// تعريف الألوان
const primaryGreen = Color(0xFF2E7D32);
const primaryBrown = Color(0xFF5D4037);
const darkRed = Color(0xCD8B0000); // أحمر داكن جداً للخطأ

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isObscure = true;
  bool isSignupMode = true;
  bool isLoading = false;

  // المتحكمات
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // دالة إظهار رسالة الخطأ (SnackBar)
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: darkRed,
      ),
    );
  }

  // دالة الانتقال للرئيسية
  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  // 1. التعامل مع الإيميل (تسجيل ودخول)
  Future<void> _handleEmailAuth() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showErrorSnackBar("Please enter your email and password");
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar("Please enter your full name");
      return;
    }

    setState(() => isLoading = true);
    try {
      if (isSignupMode) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (_nameController.text.isNotEmpty) {
          await FirebaseAuth.instance.currentUser?.updateDisplayName(
            _nameController.text,
          );
        }
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      _goToHome();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? "An unexpected error occurred");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // 2. التعامل مع جوجل
  Future<void> _handleGoogleSignIn() async {
    setState(() => isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      _goToHome();
    } catch (e) {
      _showErrorSnackBar("Google Sign-In failed");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // الخلفية
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // زر العودة (يظهر فقط في وضع التسجيل )
          isSignupMode
              ? Container()
              : Positioned(
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
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.8,
              padding: const EdgeInsets.symmetric(
                horizontal: 25.0,
                vertical: 30.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: primaryGreen),
                      )
                      : SingleChildScrollView(
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
                              buildTextField(
                                "Full Name",
                                "Enter Full Name",
                                _nameController,
                              ),
                              const SizedBox(height: 20),
                            ],

                            buildTextField(
                              "Email",
                              "Enter Email",
                              _emailController,
                            ),
                            const SizedBox(height: 20),
                            buildTextField(
                              "Password",
                              "Enter Password",
                              _passwordController,
                              isPassword: true,
                            ),

                            const SizedBox(height: 30),

                            // زر الدخول/التسجيل
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
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // جوجل
                            InkWell(
                              onTap: _handleGoogleSignIn,
                              child: Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
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
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),

                            // التبديل بين الحالتين
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isSignupMode
                                      ? "Already have an account? "
                                      : "Don't have an account? ",
                                ),
                                GestureDetector(
                                  onTap:
                                      () => setState(
                                        () => isSignupMode = !isSignupMode,
                                      ),
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
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(
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
              borderSide: const BorderSide(color: primaryGreen, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            suffixIcon:
                isPassword
                    ? IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                        color: primaryGreen,
                      ),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    )
                    : null,
          ),
        ),
      ],
    );
  }
}
