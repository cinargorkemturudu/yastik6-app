import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class AppFormatter {
  static final _dateFormat = DateFormat('dd.MM.yy');
  static final Map<int, NumberFormat> _dynamicFormatters = {};

  static NumberFormat _getFormatter(int precision) {
    return _dynamicFormatters.putIfAbsent(
      precision,
          () => NumberFormat.decimalPatternDigits(
        locale: 'tr_TR',
        decimalDigits: precision,
      ),
    );
  }

  static String moneyFromDouble(double value) => "${_getFormatter(2).format(value)} TL";
  static String amountFromDouble(double value, {int precision = 2}) => _getFormatter(precision).format(value);

  static Decimal parseInput(String input) {
    if (input.trim().isEmpty) return Decimal.zero;
    String cleaned = input.replaceAll('.', '').replaceAll(',', '.');
    return Decimal.tryParse(cleaned) ?? Decimal.zero;
  }

  static String money(Decimal value) => "${_getFormatter(2).format(value.toDouble())} TL";
  static String amount(Decimal value, String symbol, {int precision = 2}) => _getFormatter(precision).format(value.toDouble());
  static String signedAmount(Decimal value, {int precision = 2}) {
    final prefix = value > Decimal.zero ? '+' : '';
    return "$prefix${amount(value, "", precision: precision)}";
  }

  static String percent(double value, {int precision = 2}) => "%${_getFormatter(precision).format(value * 100)}";
  static String pnlValue(Decimal value) {
    final prefix = value > Decimal.zero ? '+' : '';
    return "$prefix${_getFormatter(2).format(value.toDouble())} TL";
  }
  static String signedPercent(double value, {int precision = 2}) => "${value > 0 ? '+' : ''}${percent(value, precision: precision)}";

  static String date(DateTime date) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final targetMidnight = DateTime(date.year, date.month, date.day);
    final difference = todayMidnight.difference(targetMidnight).inDays;
    if (difference < 7 && difference >= 0) {
      switch (date.weekday) {
        case 1: return 'Pazartesi'; case 2: return 'Salı'; case 3: return 'Çarşamba';
        case 4: return 'Perşembe'; case 5: return 'Cuma'; case 6: return 'Cumartesi';
        case 7: return 'Pazar';
      }
    }
    return _dateFormat.format(date);
  }

  // --- REFINED SANITIZATION METHODS ---

  /// Cleans up raw asset codes (e.g., AAPL.IS -> AAPL).
  /// [IMPORTANT]: Standalone 'TRY' is preserved to avoid empty titles.
  static String cleanAssetCode(String code) {
    if (code == 'TRY' || code == 'TRY=X') return 'TRY';
    return code
        .replaceAll('.IS', '')
        .replaceAll('=X', '')
        .replaceAll('/TRY', '') // Örn: USD/TRY -> USD kalır
        .replaceAll('TRY', '')  // Örn: USDTRY -> USD kalır
        .replaceAll('/', '')
        .replaceAll('-USD', '');
  }

  /// Sanitizes asset names by removing redundant currency suffixes.
  static String cleanAssetName(String name) {
    return name.replaceAll(' USD', '').replaceAll('(USD)', '').trim();
  }
}

extension DecimalPnlColor on Decimal {
  Color toPnlColor() {
    if (this == Decimal.zero) return const Color(0xFF9E9E9E);
    return this > Decimal.zero ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
  }
}

extension DoublePnlColor on double {
  Color toPnlColor() {
    if (this == 0.0) return const Color(0xFF9E9E9E);
    return this > 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
  }
}