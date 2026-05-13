import '../models/entities/asset.dart';

class AssetCatalog {

  static bool isPricedInUsd(String code) {
    final upper = code.toUpperCase();

    if (upper == 'USD' || upper == 'USDTRY=X' || upper == 'EUR' ||
        upper == 'GBP') {
      return false;
    }

    if (upper.endsWith('-USD') || upper == 'BTC' || upper == 'ETH') {
      return true;
    }

    // [KRİTİK GÜNCELLEME]: GÜMÜŞ_ONS yerine GUMUS_ONS
    if (upper == 'ONS' || upper == 'GUMUS_ONS') {
      return true;
    }

    return false;
  }

  static bool

  isPhysicalEligible(AssetType type, String code) {
    if (type == AssetType.metal) return true;
    // [GÜNCELLENDİ]: 'TRY' listeye eklendi
    final physicalCurrencies = [
      'USD',
      'EUR',
      'GBP',
      'CHF',
      'SAR',
      'AUD',
      'CAD',
      'JPY',
      'TRY'
    ];
    return physicalCurrencies.any((currency) =>
        code.toUpperCase().contains(currency));
  }
}