import 'package:flutter/material.dart';
import 'package:jiyong_in_the_room/constants/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('탈출일지'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock,
                size: 80,
                color: AppColors.secondary,
              ),
              SizedBox(height: 24),
              Text(
                '탈출일지 v2',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '새로운 시작',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}