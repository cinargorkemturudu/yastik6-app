import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';

void main() {
  group('AppFormatter.parseInput', () {
    test('parses a plain integer string', () {
      final result = AppFormatter.parseInput('100');
      expect(result, Decimal.parse('100'));
    });

    test('parses comma as the decimal separator', () {
      final result = AppFormatter.parseInput('100,50');
      expect(result, Decimal.parse('100.50'));
    });

    test('parses dot as the decimal separator', () {
      final result = AppFormatter.parseInput('100.50');
      expect(result, Decimal.parse('100.50'));
    });

    test('parses dotted thousands with a comma decimal', () {
      // Dot = thousands separator, comma = decimal separator (Turkish convention)
      final result = AppFormatter.parseInput('1.234,56');
      expect(result, Decimal.parse('1234.56'));
    });

    test('treats the last dot as the true decimal separator when ambiguous', () {
      // Two raw dots with no comma at all: same disambiguation branch as above,
      // just reached without going through the comma->dot conversion first.
      final result = AppFormatter.parseInput('1.000.50');
      expect(result, Decimal.parse('1000.50'));
    });

    test('treats a single dot as a decimal point, not a thousands separator', () {
      // Only fires the multi-dot disambiguation when there are 2+ dots, so a lone
      // dot always means "decimal point" here (international convention) — the
      // opposite of the backend's TryParseTurkishMoney, which treats a lone dot
      // in raw Harem data as a thousands separator. Different input sources,
      // different conventions; this test locks in which one this function picks.
      final result = AppFormatter.parseInput('1.234');
      expect(result, Decimal.parse('1.234'));
    });

    test('returns zero for empty or whitespace-only input', () {
      expect(AppFormatter.parseInput(''), Decimal.zero);
      expect(AppFormatter.parseInput('   '), Decimal.zero);
    });

    test('returns zero for unparseable garbage input', () {
      final result = AppFormatter.parseInput('abc');
      expect(result, Decimal.zero);
    });

    test('removes spaces used as thousand separators', () {
      final result = AppFormatter.parseInput('1 234,56');
      expect(result, Decimal.parse('1234.56'));
    });
  });
}
