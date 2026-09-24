import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// A central utility class responsible for formatting and parsing all numerical,
/// monetary, and date-related data across the application.
class AppFormatter {
  static final _dateFormat = DateFormat('dd.MM.yy');

  /// Cache for NumberFormats to avoid expensive instantiations on every build.
  static final Map<int, NumberFormat> _dynamicFormatters = {};

  /// Retrieves or creates a NumberFormat instance with the specified precision.
  static NumberFormat _getFormatter(int precision) {
    return _dynamicFormatters.putIfAbsent(
      precision,
          () => NumberFormat.decimalPatternDigits(
        locale: 'tr_TR',
        decimalDigits: precision,
      ),
    );
  }

  // --- PARSING (INPUT SANITIZATION) ---

  /// Safely parses user input into a Decimal object.
  /// Handles both dot (.) and comma (,) as decimal separators gracefully.
  /// Eliminates invalid thousand separators to prevent parsing errors.
  static Decimal parseInput(String input) {
    if (input.trim().isEmpty) return Decimal.zero;

    // 1. Remove spaces (often used as thousand separators) and convert all commas to dots.
    String cleaned = input.replaceAll(' ', '').replaceAll(',', '.');

    // 2. Find the positions of the first and last dots.
    int firstDotIndex = cleaned.indexOf('.');
    int lastDotIndex = cleaned.lastIndexOf('.');

    // 3. If there are multiple dots (e.g., "1.000.50" which became "1.000.50")
    if (firstDotIndex != -1 && firstDotIndex != lastDotIndex) {
      // Preserve the last dot (the true decimal separator) using a temporary placeholder 'X'.
      cleaned = cleaned.replaceRange(lastDotIndex, lastDotIndex + 1, 'X');

      // Remove all remaining dots (assumed to be accidental thousand separators).
      cleaned = cleaned.replaceAll('.', '');

      // Restore the true decimal separator.
      cleaned = cleaned.replaceAll('X', '.');
    }

    return Decimal.tryParse(cleaned) ?? Decimal.zero;
  }

  // --- FORMATTING (DOUBLE) ---

  /// Formats a double value as currency with the 'TL' suffix.
  static String moneyFromDouble(double value) => "${_getFormatter(2).format(value)} TL";

  /// Formats a double value to a string with the specified decimal precision.
  static String amountFromDouble(double value, {int precision = 2}) => _getFormatter(precision).format(value);

  // --- FORMATTING (DECIMAL) ---

  /// Formats a Decimal value as currency with the 'TL' suffix.
  static String money(Decimal value) => "${_getFormatter(2).format(value.toDouble())} TL";

  /// Formats a Decimal value to a string with the specified precision.
  static String amount(Decimal value, String symbol, {int precision = 2}) => _getFormatter(precision).format(value.toDouble());

  /// Formats a Decimal value with a '+' or '-' prefix based on its sign.
  static String signedAmount(Decimal value, {int precision = 2}) {
    final prefix = value > Decimal.zero ? '+' : '';
    return "$prefix${amount(value, "", precision: precision)}";
  }

  /// Formats large numbers compactly using Turkish localized suffixes (Mr, M)
  /// and respects the tr_TR comma separator for decimals.
  static String compactMoney(Decimal amount, [String symbol = "TL"]) {
    final double val = amount.toDouble().abs();
    final String sign = amount < Decimal.zero ? "-" : "";

    if (val >= 1000000000) {
      // Milyar
      return '$sign${_getFormatter(2).format(val / 1000000000)} Mr $symbol';
    } else if (val >= 1000000) {
      // Milyon
      return '$sign${_getFormatter(2).format(val / 1000000)} M $symbol';
    }

    return money(amount);
  }

  // --- PERCENTAGES & PNL ---

  /// Formats a double value as a percentage.
  static String percent(double value, {int precision = 2}) => "%${_getFormatter(precision).format(value * 100)}";

  /// Formats a Decimal Profit & Loss (PnL) value with a sign prefix.
  static String pnlValue(Decimal value) {
    final prefix = value > Decimal.zero ? '+' : '';
    return "$prefix${_getFormatter(2).format(value.toDouble())} TL";
  }

  /// Formats a double Profit & Loss (PnL) percentage with a sign prefix.
  static String signedPercent(double value, {int precision = 2}) => "${value > 0 ? '+' : ''}${percent(value, precision: precision)}";

  // --- DATE & TIME ---

  /// Formats a DateTime object into a human-readable string.
  /// Returns the day of the week for dates within the last 7 days, otherwise 'dd.MM.yy'.
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
  /// [IMPORTANT]: Standalone 'TRY' is preserved to avoid empty titles in the UI.
  static String cleanAssetCode(String code) {
    if (code == 'TRY' || code == 'TRY=X') return 'TRY';
    return code
        .replaceAll('.IS', '')
        .replaceAll('=X', '')
        .replaceAll('/TRY', '') // Ex: USD/TRY -> USD
        .replaceAll('TRY', '')  // Ex: USDTRY -> USD
        .replaceAll('/', '')
        .replaceAll('-USD', '');
  }

  /// Sanitizes asset names by removing redundant currency suffixes for a cleaner UI.
  static String cleanAssetName(String name) {
    return name.replaceAll(' USD', '').replaceAll('(USD)', '').trim();
  }
}

// --- EXTENSIONS ---

/// Provides color mapping for Decimal Profit & Loss (PnL) values.
extension DecimalPnlColor on Decimal {
  Color toPnlColor() {
    final double val = toDouble();

    // If the value is between -0.005 and +0.005, it rounds to 0.00 on the UI.
    if (val.abs() < 0.005) return const Color(0xFF9E9E9E); // Neutral grey

    return val > 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935); // Green for profit, Red for loss
  }
}

/// Provides color mapping for double Profit & Loss (PnL) values.
extension DoublePnlColor on double {
  Color toPnlColor() {
    // If the value is between -0.005 and +0.005, it rounds to 0.00 on the UI.
    if (abs() < 0.005) return const Color(0xFF9E9E9E); // Neutral grey

    return this > 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935); // Green for profit, Red for loss
  }
}