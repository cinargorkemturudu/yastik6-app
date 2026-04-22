import 'package:decimal/decimal.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';

enum ExchangeMode { bank, physical }

class ExchangeService {

  static Decimal calculateExchange({
    required ExchangeMode mode,
    required Decimal amount,
    required PriceQuote fromAsset,
    required PriceQuote toAsset,
  }) {
    if (fromAsset.assetCode == toAsset.assetCode) return amount;

    if (mode == ExchangeMode.bank) {
      Decimal tryEquivalent = amount * fromAsset.bid;
      return (tryEquivalent.toRational() / toAsset.ask.toRational()).toDecimal(scaleOnInfinitePrecision: 10);
    } else {
      Decimal rawParity = (fromAsset.bid.toRational() / toAsset.bid.toRational()).toDecimal(scaleOnInfinitePrecision: 10);

      final fromType = fromAsset.type;
      final toType = toAsset.type;

      bool hasYahooCurrency = (fromType == AssetType.currency || toType == AssetType.currency);

      Decimal syntheticPhysicalSpread = hasYahooCurrency ? Decimal.parse('0.002') : Decimal.zero;

      return (amount * rawParity) * (Decimal.one - syntheticPhysicalSpread);
    }
  }
}