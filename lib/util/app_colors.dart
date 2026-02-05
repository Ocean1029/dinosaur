import 'package:flutter/material.dart';

/// 應用程式顏色系統
abstract final class AppColors {
  // Primary Colors
  static const Color primary50 = Color(0xFFEDF8FA);
  static const Color primary100 = Color(0xFFDBF1F5);
  static const Color primary200 = Color(0xFFB4E2EA);
  static const Color primary300 = Color(0xFF93D4DF);
  static const Color primary400 = Color(0xFF71C5D5);
  static const Color primary500 = Color(0xFF5AB4C5);
  static const Color primary600 = Color(0xFF468D9B);
  static const Color primary700 = Color(0xFF356C77);
  static const Color primary800 = Color(0xFF22474E);
  static const Color primary900 = Color(0xFF112629);
  static const Color primary950 = Color(0xFF081315);

  // Grayscale
  static const Color grayscale50 = Color(0xFFF1F3F4);
  static const Color grayscale100 = Color(0xFFE3E7E9);
  static const Color grayscale200 = Color(0xFFCAD1D5);
  static const Color grayscale300 = Color(0xFFADB8BE);
  static const Color grayscale400 = Color(0xFF91A0A8);
  static const Color grayscale500 = Color(0xFF738995);
  static const Color grayscale600 = Color(0xFF5E6D76);
  static const Color grayscale700 = Color(0xFF475259);
  static const Color grayscale800 = Color(0xFF30383D);
  static const Color grayscale900 = Color(0xFF171B1D);
  static const Color grayscale950 = Color(0xFF0B0D0E);

  // Red
  static const Color red50 = Color(0xFFFAEEEE);
  static const Color red100 = Color(0xFFF5DCDD);
  static const Color red200 = Color(0xFFEBB6B6);
  static const Color red300 = Color(0xFFE29494);
  static const Color red400 = Color(0xFFD45251);
  static const Color red500 = Color(0xFFD45251);
  static const Color red600 = Color(0xFFC2332F);
  static const Color red700 = Color(0xFF912522);
  static const Color red800 = Color(0xFF5F1715);
  static const Color red900 = Color(0xFF310B0B);
  static const Color red950 = Color(0xFF180505);

  // Orange
  static const Color orange50 = Color(0xFFFDF3EC);
  static const Color orange100 = Color(0xFFFBE7D9);
  static const Color orange200 = Color(0xFFF7CFB2);
  static const Color orange300 = Color(0xFFF4B992);
  static const Color orange400 = Color(0xFFF1A26D);
  static const Color orange500 = Color(0xFFFD853A);
  static const Color orange600 = Color(0xFFE6692C);
  static const Color orange700 = Color(0xFFAE501F);
  static const Color orange800 = Color(0xFF713311);
  static const Color orange900 = Color(0xFF391A06);
  static const Color orange950 = Color(0xFF1C0C02);

  // App Specific Colors
  static const Color background = Color(0xFFE6F8F9);
  static const Color primaryBlue = Color(0xFF00B9CA);
  static const Color gray = Color(0xFF91A0A8);
  static const Color tableHeader = Color(0xFFF5F5F5);
  
  // 向後兼容的舊顏色
  static const Color runCityBackground = Color(0xFFE6F8F9);
  static const Color runCityBlue = Color(0xFF00B9CA);
  static const Color runCityGray = Color(0xFF91A0A8);
  static const Color runCityTableHeader = Color(0xFFF5F5F5);

  // Basic
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;
}