import 'package:flutter/material.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // --- BAŞLIKLAR (Headings) ---
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  // --- GÖVDE METİNLERİ (Body) ---
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  // --- ALT BİLGİ & ETİKETLER (Caption / Labels) ---
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textMuted,
  );

  static const TextStyle captionBold = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: AppColors.textMuted,
  );

  // --- FİYAT / RAKAM STİLLERİ (Numbers) ---
  static const TextStyle priceLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  //  BÜYÜK RAKAMLAR (Hero Amounts)
  static const TextStyle heroAmount = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
}