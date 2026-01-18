import 'package:flutter/material.dart';
import 'package:seiyun_reports_app/screens/Home_Screen.dart';
import 'package:seiyun_reports_app/screens/Login_screen.dart';
import 'package:seiyun_reports_app/screens/Welcome_Screen.dart';

void main() {
  runApp(const MyApp());
}

var myColorScheme = ColorScheme.fromSeed(seedColor: Colors.green);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData().copyWith(
        useMaterial3: true,
        colorScheme: myColorScheme,
      ),
      routes: {
        '/': (context) => WelcomePage(),
        '/HomeScreen': (context) => HomeScreen(),
      },
    );
  }
}
