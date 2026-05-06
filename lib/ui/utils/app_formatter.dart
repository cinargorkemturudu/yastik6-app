import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AppFormatter {
  static final _dateFormat = DateFormat('dd.MM.yy');

  // Bellek yönetimi için dinamik formatlayıcı deposu
  static final Map<int, NumberFormat> _dynamicFormatters = {};

  // Belirtilen hassasiyete göre formatlayıcı üreten yardımcı metod
  static NumberFormat _getFormatter(int precision) {
    return _dynamicFormatters.putIfAbsent(
      precision,
          () => NumberFormat.decimalPatternDigits(
        locale: 'tr_TR',
        decimalDigits: precision,
      ),
    );
  }

  // --- HIGH PERFORMANCE BYPASS METHODS ---
  // Grafik kütüphanesi gibi saniyede 60 kare (60fps) çalışan ve
  // doğrudan double üreten yapılar için String -> Decimal -> Double 
  // dönüşüm yükünü ortadan kaldıran direkt formatlayıcılar.
  static String moneyFromDouble(double value) {
    return "${_getFormatter(2).format(value)} TL";
  }

  static String amountFromDouble(double value, {int precision = 2}) {
    return _getFormatter(precision).format(value);
  }

  // Kullanıcı girişini güvenli bir şekilde Decimal'e çevirir
  static Decimal parseInput(String input) {
    if (input.trim().isEmpty) return Decimal.zero;
    String cleaned = input.replaceAll('.', '').replaceAll(',', '.');
    return Decimal.tryParse(cleaned) ?? Decimal.zero;
  }

  // Standart para birimi gösterimi (Daima 2 hane kuruş)
  static String money(Decimal value) {
    return "${_getFormatter(2).format(value.toDouble())} TL";
  }

  // Varlık miktarı gösterimi (Kripto için yüksek hassasiyet destekli)
  static String amount(Decimal value, String symbol, {int precision = 2}) {
    return _getFormatter(precision).format(value.toDouble());
  }

  // İşlem listeleri için işaretli miktar gösterimi
  static String signedAmount(Decimal value, {int precision = 2}) {
    final prefix = value > Decimal.zero ? '+' : '';
    return "$prefix${amount(value, "", precision: precision)}";
  }

  // Yüzdelik oran gösterimi (Hassasiyet kaybı engellendi)
  static String percent(double value, {int precision = 2}) {
    final formattedNumber = _getFormatter(precision).format(value * 100);
    return "%$formattedNumber";
  }

  // Kar/Zarar tutarı gösterimi (Kuruşları yutan eski format kaldırıldı)
  static String pnlValue(Decimal value) {
    final prefix = value > Decimal.zero ? '+' : '';
    return "$prefix${_getFormatter(2).format(value.toDouble())} TL";
  }

  // İşaretli yüzdelik oran gösterimi
  static String signedPercent(double value, {int precision = 2}) {
    final prefix = value > 0 ? '+' : '';
    return "$prefix${percent(value, precision: precision)}";
  }

  // Tarih formatlayıcı (Bugün/Dün desteğiyle)
  static String date(DateTime date) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final targetMidnight = DateTime(date.year, date.month, date.day);
    final difference = todayMidnight.difference(targetMidnight).inDays;

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

  // Varlık kodlarını temizler (Yahu, Harem vb. API kalıntıları)
  static String cleanAssetCode(String code) {
    return code
        .replaceAll('.IS', '')
        .replaceAll('=X', '')
        .replaceAll('TRY', '')
        .replaceAll('-USD', '');
  }
}

// Decimal değerler için merkezi renk extension'ı
extension DecimalPnlColor on Decimal {
  Color toPnlColor() {
    if (this == Decimal.zero) return const Color(0xFF9E9E9E);
    return this > Decimal.zero ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
  }
}

// Yüzdelik oranlar (double) için merkezi renk extension'ı
extension DoublePnlColor on double {
  Color toPnlColor() {
    if (this == 0.0) return const Color(0xFF9E9E9E);
    return this > 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
  }
}