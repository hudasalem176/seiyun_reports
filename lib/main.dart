import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:seiyun_reports_app/core/auth/auth_guard.dart';
import 'package:seiyun_reports_app/core/auth/secure_token_storage.dart';
import 'package:seiyun_reports_app/core/auth/session_manager.dart';
import 'package:seiyun_reports_app/core/di/app_providers.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';
import 'package:seiyun_reports_app/screens/profile/viewmodel/profile_viewmodel.dart';
import 'package:seiyun_reports_app/screens/splash/view/splash_screen.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:seiyun_reports_app/core/utils/pref_helper.dart';
import 'package:seiyun_reports_app/screens/notifications/view/notifications_screen.dart';

/// نقطة البدء الرئيسية للتطبيق، تهيئ الإعدادات والخدمات الأساسية ثم تشغله.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await PrefHelper.init();
  // نقل رمز الوصول القديم من التخزين النصي إلى التخزين الآمن.
  await SecureTokenStorage.migrateFromSharedPreferences();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      // يُعاد إنشاء كل الـ ViewModels بعد تسجيل الخروج حتى لا تبقى بيانات
      // المستخدم السابق في الذاكرة، وتُلغى مؤقتاتها واشتراكاتها عبر dispose.
      child: ValueListenableBuilder<int>(
        valueListenable: SessionManager.sessionGeneration,
        builder:
            (context, generation, _) => MultiProvider(
              key: ValueKey('session_$generation'),
              providers: AppProviders.providers,
              child: const MyApp(),
            ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      SessionManager.navigatorKey;

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          title: 'Seiyun Reports App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              profileViewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            // الصفحات المحمية تمر عبر AuthGuard (مثلاً عند فتحها من إشعار).
            '/notifications':
                (context) => const AuthGuard(child: NotificationsScreen()),
          },
        );
      },
    );
  }
}
