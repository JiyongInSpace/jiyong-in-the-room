import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/constants/app_colors.dart';
import 'package:jiyong_in_the_room/screens/main/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '탈출일지',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.secondary,
          secondary: AppColors.tertiary,
          surface: AppColors.surface,
          background: AppColors.backgroundLight,
        ),
        useMaterial3: true,
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: AppColors.backgroundLight,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.appBarText,
          elevation: 2,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
