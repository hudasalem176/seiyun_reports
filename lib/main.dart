import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/screens/Auth.dart';
import 'package:seiyun_reports_app/screens/Home_Screen.dart';
import 'package:seiyun_reports_app/not.dart';
import 'package:seiyun_reports_app/screens/Welcome_Screen.dart';
import 'package:seiyun_reports_app/screens/Home.dart';
import 'package:seiyun_reports_app/screens/Report.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

// تعريف الثيم والألوان بشكل منظم
var myColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF2E7D32), // اللون الأخضر الأساسي لتطبيقك
  primary: const Color(0xFF2E7D32),
  secondary: const Color(0xFF5D4037), // اللون البني
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale('ar', 'YE'),
      title: 'Seiyun Reports App',

      // 1. إعدادات الثيم (Theme)
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: myColorScheme,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5D4037),
            foregroundColor: Colors.white,
          ),
        ),
      ),

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // إذا كان التطبيق لا يزال يتصل بـ Firebase
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // إذا وجد بيانات مستخدم (مسجل دخول)
          if (snapshot.hasData) {
            return  AuthScreen();
          }
          // إذا لم يجد مستخدم (غير مسجل)
          return const AuthScreen();
        },
      ),
    );
  }
}