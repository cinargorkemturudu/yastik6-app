import 'package:intl/intl.dart';

class AppFormatter {
  static final _dateFormat = DateFormat('dd.MM.yy');
  static final _trFormat = NumberFormat('#,##0.00', 'tr_TR');
  static final _trFormatNoDecimal = NumberFormat('#,##0', 'tr_TR');

  static String money(double value) {
    return "${_trFormat.format(value)} TL";
  }

  // [DÜZELTİLDİ]: Orijinal 2 parametreli imza (signature) korundu.
  // DÜZELTİLMİŞ HALİ (Sembol eklemesini kaldırdık, sadece sayıyı TR formatında dönüyor)
  static String amount(double value, String symbol) {
    return _trFormat.format(value);
  }

  static String percent(double value) {
    return "%${_trFormat.format(value * 100)}";
  }

  static String pnlValue(double value) {
    final prefix = value > 0 ? '+' : '';
    return "$prefix${_trFormatNoDecimal.format(value)} TL";
  }

  static String signedPercent(double value) {
    final prefix = value > 0 ? '+' : '';
    return "$prefix%${_trFormat.format(value * 100)}";
  }

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
  static String cleanAssetCode(String code) {
    return code
        .replaceAll('.IS', '')
        .replaceAll('=X', '')
        .replaceAll('TRY', '')
        .replaceAll('-USD', '');
  }
}