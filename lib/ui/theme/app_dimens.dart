/// Tasarım sistemindeki tüm boşluk, boyut ve yuvarlama standartları.
/// Arayüzdeki "Sihirli Sayıları (Magic Numbers)" engeller.
class AppDimens {
  // --- STANDART BOŞLUKLAR (Padding & Margins) ---
  static const double p2 = 2.0;
  static const double p4 = 4.0;
  static const double p6 = 6.0;
  static const double p8 = 8.0;
  static const double p10 = 10.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p24 = 24.0;
  static const double p40 = 40.0; // Ekran sonu büyük alt boşluklar

  // Scaffold & Ana Sayfa Kenar Boşluğu
  static const double pagePadding = 15.0;

  // --- KÖŞE YUVARLAMALARI (Border Radius) ---
  static const double radiusXs = 2.0;  // Progress bar vb.
  static const double radiusSm = 8.0;  // İç kartlar ve ufak detaylar
  static const double radiusMd = 12.0; // Ana kartlar (LotCard, Overview vb.)
  static const double radiusLg = 24.0; // Bottom Sheet'ler

  // --- İKON BOYUTLARI ---
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;

  // --- ÖZEL BİLEŞEN ÖLÇÜLERİ (Custom Components) ---
  static const double donutSectionHeight = 210.0;
  static const double donutSize = 170.0;
  static const double donutStroke = 16.0;
  static const double legendCircle = 8.0;

  static const double fabSize = 48.0; // Aksiyon Butonları (Al/Sat)
  static const double borderWidth = 1.5;
  static const double dividerHeight = 1.0;
}