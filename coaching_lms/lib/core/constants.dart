import 'package:flutter/material.dart';

class ApiConfig {
  // ⚠️ CHANGE THIS to your real domain before building the release APK.
  // Local testing (Android emulator talking to your PC's XAMPP/Laragon):
  //   static const String baseUrl = 'http://10.0.2.2/lms/api';
  // Real device on same WiFi as your dev machine:
  //   static const String baseUrl = 'http://192.168.1.X/lms/api';
  // Live cPanel deployment:
  static const String baseUrl = 'https://trader.unitopper.in/api';
}

class AppColors {
  static const Color indigo900 = Color(0xFF241653);
  static const Color indigo700 = Color(0xFF3D2B8C);
  static const Color indigo600 = Color(0xFF4F3AB8);
  static const Color violet500 = Color(0xFF7C5CFC);
  static const Color violet100 = Color(0xFFEFE9FF);

  static const Color amber500 = Color(0xFFF5A623);
  static const Color amber100 = Color(0xFFFFF4E0);

  static const Color emerald500 = Color(0xFF16A87C);
  static const Color emerald100 = Color(0xFFE1F7EE);

  static const Color rose500 = Color(0xFFE24C6E);
  static const Color rose100 = Color(0xFFFDEAF0);

  static const Color sky500 = Color(0xFF2B9CE0);
  static const Color sky100 = Color(0xFFE7F5FE);

  static const Color bg = Color(0xFFF6F5FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7E4F3);

  static const Color ink900 = Color(0xFF1E1B2E);
  static const Color ink600 = Color(0xFF524C6B);
  static const Color ink400 = Color(0xFF8B85A3);
}
