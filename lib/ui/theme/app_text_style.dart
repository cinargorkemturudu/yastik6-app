import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // --- FONT AİLELERİ (Merkezi Kontrol) ---
  static final TextStyle _heading = GoogleFonts.inter(color: AppColors.textPrimary);
  static final TextStyle _body = GoogleFonts.ibmPlexSans(color: AppColors.textPrimary);

  // --- BAŞLIKLAR (Inter) ---
  static final TextStyle h1 = _heading.copyWith(fontSize: 24, fontWeight: FontWeight.bold);
  static final TextStyle h2 = _heading.copyWith(fontSize: 20, fontWeight: FontWeight.bold);
  static final TextStyle h3 = _heading.copyWith(fontSize: 16, fontWeight: FontWeight.bold);

  // --- GÖVDE METİNLERİ (IBM Plex Sans) ---
  static final TextStyle bodyLarge = _body.copyWith(fontSize: 16, fontWeight: FontWeight.w500);
  static final TextStyle bodyMedium = _body.copyWith(fontSize: 14, fontWeight: FontWeight.normal);

  // --- ALT BİLGİ & ETİKETLER (IBM Plex Sans) ---
  // Hierarchy achieved strictly via font thickness. 
  // Minimum w400 enforced to prevent OLED anti-aliasing washout.
  // All colors point directly to textPrimary to eliminate semantic ghosts.
  static final TextStyle caption = _body.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static final TextStyle captionBold = _body.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600, // Adjusted to w600 to maintain contrast against the w400 caption
    color: AppColors.textPrimary,
  );

  // --- FİYAT / RAKAM STİLLERİ (Inter - Rakamlar için daha okunaklı) ---
  static final TextStyle priceLarge = _heading.copyWith(fontSize: 15, fontWeight: FontWeight.w700);

  static final TextStyle heroAmount = _heading.copyWith(fontSize: 32, fontWeight: FontWeight.w800);
}