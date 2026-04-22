import 'package:intl/intl.dart';

class AppFormatter {
  // Statik değişkenler (Performans için)
  static final _dateFormat = DateFormat('dd.MM.yy');
  
  /// Para formatı: 1250.5 -> "1,250.50 TL"
  static String money(double value) {
    return "${value.toStringAsFixed(2)} TL";
  }

  static String amount(double value, String symbol) {
    return value.toStringAsFixed(2);
  }

  /// Yüzde formatı: 0.15 -> "%15.20"
  static String percent(double value) {
    return "%${(value * 100).toStringAsFixed(2)}";
  }

  /// [YENİ] Kar/Zarar Metni: 500 -> "+500 TL"
  /// Artık Mapper'da "+" işaretiyle uğraşmaya gerek yok.
  static String pnlValue(double value) {
    final prefix = value >= 0 ? '+' : '';
    // Kar zarar genelde kuruşsuz daha net okunur, istersen .toStringAsFixed(2) yapabilirsin.
    return "$prefix${value.toStringAsFixed(0)} TL";
  }

  /// Akıllı Tarih: "Salı" veya "24.01.24"
  static String date(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference < 7 && difference >= 0) {
      switch (date.weekday) {
        case 1: return 'Pazartesi';
        case 2: return 'Salı';
        case 3: return 'Çarşamba';
        case 4: return 'Perşembe';
        case 5: return 'Cuma';
        case 6: return 'Cumartesi';
        case 7: return 'Pazar';
      }
    }
    return _dateFormat.format(date);
  }

  static String signedPercent(double value) {
    final prefix = value > 0 ? '+' : '';
    return "$prefix%${(value * 100).toStringAsFixed(2)}";
  }
}