import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/utils/app_formatter.dart';

import '../../domain/models/entities/asset.dart';

class MarketItemUiModel {
  final String assetCode;
  final String name;
  final Decimal ask;
  final Decimal bid;
  final String formattedAsk;
  final String formattedBid;
  final String changeRateText;
  final Color trendColor;
  final IconData trendIcon;
  final AssetType type;

  // YENİ EKLENEN UI ALANLARI
  final String displayTitle;
  final String? displaySubtitle;

  MarketItemUiModel({
    required this.assetCode,
    required this.name,
    required this.ask,
    required this.bid,
    required this.formattedAsk,
    required this.formattedBid,
    required this.changeRateText,
    required this.trendColor,
    required this.trendIcon,
    required this.type,
    required this.displayTitle,
    required this.displaySubtitle,
  });

  factory MarketItemUiModel.fromQuote(PriceQuote quote) {
    // Ensuring changeRate handles double operations cleanly
    final double changeRateDouble = quote.changeRate.toDouble();
    final rawDecimal = changeRateDouble / 100;

    IconData icon = Icons.remove;
    if (changeRateDouble > 0) icon = Icons.arrow_drop_up;
    if (changeRateDouble < 0) icon = Icons.arrow_drop_down;

    // --- SUNUM MANTIĞI (PRESENTATION LOGIC) ---
    String title;
    String? subtitle;

    switch (quote.type) {
      case AssetType.stock:
        title = quote.name;           // [DÜZELTİLDİ]: Şirket ismi tekrar ana başlık oldu
        subtitle = quote.assetCode;   // [DÜZELTİLDİ]: Sembol (Borsa Kodu) alt başlığa (sub) çekildi
        break;
      case AssetType.metal:
        title = quote.name;
        subtitle = null; // Harem API'den gelen placeholder (boşluk vs) iptal edildi
        break;
      default: // Kripto ve diğerleri
        title = AppFormatter.cleanAssetCode(quote.assetCode);
        // İsimde geçen yanıltıcı USD ibarelerini temizliyoruz
        subtitle = quote.name.replaceAll(' USD', '').replaceAll('(USD)', '').trim();
        break;
    }

    return MarketItemUiModel(
      assetCode: quote.assetCode,
      name: quote.name,
      ask: quote.ask,
      bid: quote.bid,
      type: quote.type,
      formattedAsk: quote.formattedAsk,
      formattedBid: quote.formattedBid,
      changeRateText: AppFormatter.signedPercent(rawDecimal),
      trendColor: changeRateDouble.toPnlColor(),
      trendIcon: icon,
      displayTitle: title,
      displaySubtitle: subtitle,
    );
  }
}