import 'package:flutter/material.dart';
import 'package:akilli_yoklama/core/constants/colors/colors.dart';
import 'package:akilli_yoklama/features/auth/welcome_screen.dart';

void main() {
  runApp(const AkilliYoklamaApp());
}

class AkilliYoklamaApp extends StatelessWidget {
  const AkilliYoklamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Akıllı Yoklama Sistemi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        fontFamily: 'Roboto',
      ),
      home: const WelcomeScreen(),
    );
  }
}