import 'package:flutter/material.dart';

// تعريف الألوان خارج الكلاس لتكون متاحة للجميع
const primaryGreen = Color(0xFF2E7D32);
const primaryBrown = Color(0xFF5D4037);
const accentGreen = Color(0xFF81C784);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // المتغيرات داخل الـ State لضمان تحديث الواجهة
  bool _isObscure = true;
  bool isSignupMode = true; // نستخدم اسم أوضح (هل نحن في وضع التسجيل؟)

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 1. الخلفية (Gradient)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // زر العودة (يظهر فقط في وضع التسجيل مثلاً أو حسب رغبتك)
          Positioned(
            top: 50,
            left: 20,
            child: TextButton.icon(
              onPressed: () {
                // منطق العودة
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
              label: const Text("Back", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),

          // 2. الحاوية البيضاء (80%)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.8,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 30.0),
                child: Column(
                  children: [
                    const Icon(Icons.forest_rounded, color: primaryGreen, size: 40),
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

                    // حقل الاسم يظهر فقط في حالة التسجيل (Signup)
                    if (isSignupMode) ...[
                      buildTextField("Full Name", "Enter Full Name", primaryGreen),
                      const SizedBox(height: 20),
                    ],

                    buildTextField("Email", "Enter Email", primaryGreen),
                    const SizedBox(height: 20),
                    buildTextField("Password", "Enter Password", primaryGreen, isPassword: true),

                    const SizedBox(height: 30),

                    // زر الفعل الأساسي
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBrown,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                        child: Text(
                          isSignupMode ? 'Sign up' : 'Sign in',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Divider مع Google
                    Row(
                      children: [
                        const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Image.asset('assets/google.png', width: 20),
                              const SizedBox(width: 5),
                              Text(
                                isSignupMode ? "Sign up with Google" : "Sign in with Google",
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // تبديل الحالة (Switch between Sign in & Sign up)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isSignupMode ? "Already have an account? " : "Don't have an account? ",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isSignupMode = !isSignupMode; // يعكس الحالة الحالية
                            });
                          },
                          child: Text(
                            isSignupMode ? "Sign in" : "Sign up",
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

  Widget buildTextField(String label, String hint, Color activeColor, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, color: primaryBrown),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword ? _isObscure : false,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black26, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: activeColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.black12),
            ),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                _isObscure ? Icons.visibility_off : Icons.visibility,
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