class FontScaleUtil {
  /// Finansal tutarların karakter sayısına göre
  /// ekrana sığması için gereken dinamik font boyutunu hesaplar.
  static double getScaledFontSize({
    required int textLength,
    required double baseFontSize,
    int threshold = 7, // Kaç karakterden sonra küçülmeye başlayacak
    double minFontSize = 12.0, // Düşebileceği en küçük font boyutu
  }) {
    if (textLength <= threshold) return baseFontSize;

    double currentFontSize = baseFontSize * (threshold / textLength);
    return currentFontSize < minFontSize ? minFontSize : currentFontSize;
  }
}