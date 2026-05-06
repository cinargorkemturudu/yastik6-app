import 'package:flutter/material.dart';

/// Tasarım sistemindeki tüm saydamlık (Alpha/Opacity) standartları.
/// Renklerin [withValues(alpha: ...)] metoduyla birlikte kullanılır.
class AppAlphas {
  // Çok hafif arka planlar (Çizgiler, gölgeler, çok silik yüzeyler)
  static const double faint = 0.05;
  static const double hover = 0.10;
  static const double bgLight = 0.12;

  // Orta seviye arka planlar (LinearProgress arkaplanı, vurgular)
  static const double bgMedium = 0.20;
  static const double borderLight = 0.30;
  static const double overlay = 0.40;

  // Belirgin vurgular (Buton kenarlıkları)
  static const double borderActive = 0.50;

  // Metin saydamlıkları (Kapsayıcı metinler, ikincil bilgiler)
  static const double textMuted = 0.70;
  static const double textSecondary = 0.80;
}

class AppColors {
  AppColors._();

  // --- Zemin Renkleri ---
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFF2C2C2C);
  static const Color inputFill = Color(0xFF252525);
  static const Color sellSlipBg = Color(0xFF2C1B1B);

  // --- Metin Renkleri ---
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white54;
  static const Color textFaint = Colors.white38;

  // --- Anlamsal Renkler ---
  static const Color profit = Color(0xFF4CAF50);
  static const Color loss = Color(0xFFE53935);
  static const Color neutral = Colors.white54;

  static const Color profitAccent = Colors.greenAccent;
  static const Color lossAccent = Colors.redAccent;
  static const Color brandBlue = Colors.blueAccent;

  // --- Kategori Renkleri ---
  static const Color metal = Color(0xFFFFD700);
  static const Color silver = Color(0xFFB0BEC5);
  static const Color currency = Color(0xFF2ECC71);
  static const Color stock = Color(0xFF3498DB); // Hisse için Mavi tonu
  static const Color crypto = Color(0xFFF7931A); // Kripto için Turuncu/Altın tonu
  static const Color indicator = Color(0xFF9B59B6); // Göstergeler için Mor tonu

  // --- VIP Varlık Renkleri ---
  // Uygulama içinde özel renge sahip olmasını istediğimiz ana varlıklar.
  static const Map<String, Color> _vipAssetColors = {
    // Madenler
    'XAU': metal,
    'GA': metal,
    'GRAM_ALTIN': metal,

    // Döviz
    'USD': currency,
    'EUR': currency,
    'GBP': currency,

    // Kripto
    'BTC': crypto,
    'BTC-USD': crypto,
    'ETH': crypto,
    'ETH-USD': crypto,

    // Göstergeler
    'ONS': indicator,
    'GÜMÜŞ_ONS': indicator,
  };

  /// Varlığın koduna göre tüm uygulamada (Donut Chart, Asset Chart vb.)
  /// tutarlı bir renk döndüren merkezi fonksiyon.
  static Color getAssetColor(String assetCode) {
    final cleanCode = assetCode.trim().toUpperCase();

    // Eğer VIP listemizde tanımlıysa o rengi dön
    if (_vipAssetColors.containsKey(cleanCode)) {
      return _vipAssetColors[cleanCode]!;
    }

    // Yüzlerce hisse/kripto için deterministik (kalıcı) bir renk üret
    // hashCode sayesinde "THYAO" her zaman aynı rengi alır.
    final index = cleanCode.hashCode.abs() % Colors.primaries.length;
    return Colors.primaries[index];
  }
}
