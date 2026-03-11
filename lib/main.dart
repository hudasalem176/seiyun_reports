import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seiyun_reports_app/screens/auth/view/auth_screen.dart';
import 'package:seiyun_reports_app/screens/home/view/home_screen.dart';
import 'package:seiyun_reports_app/screens/auth/viewmodel/auth_viewmodel.dart';
import 'package:seiyun_reports_app/screens/home/viewmodel/home_viewmodel.dart';
import 'package:seiyun_reports_app/screens/report/viewmodel/report_viewmodel.dart';
import 'package:seiyun_reports_app/viewmodels/notification_viewmodel.dart';
import 'package:seiyun_reports_app/screens/my_reports/viewmodel/my_reports_viewmodel.dart';
import 'package:seiyun_reports_app/screens/news_tips/viewmodel/news_tips_viewmodel.dart';
import 'package:seiyun_reports_app/screens/profile/viewmodel/profile_viewmodel.dart';
import 'package:seiyun_reports_app/screens/citizen_reports/viewmodel/citizen_reports_viewmodel.dart';
import 'package:seiyun_reports_app/screens/pickup_schedules/viewmodel/pickup_schedules_viewmodel.dart';
import 'package:seiyun_reports_app/screens/map/viewmodel/map_viewmodel.dart';
import 'package:seiyun_reports_app/core/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HomeViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
        ChangeNotifierProvider(create: (_) => MyReportsViewModel()),
        ChangeNotifierProvider(create: (_) => NewsTipsViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => CitizenReportsViewModel()),
        ChangeNotifierProvider(create: (_) => PickupSchedulesViewModel()),
        ChangeNotifierProvider(create: (_) => MapViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, profileViewModel, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ar', 'YE'),
          title: 'Seiyun Reports App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: profileViewModel.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                return HomeScreen();
              }
              return const AuthScreen();
            },
          ),
        );
      },
    );
  }
}
