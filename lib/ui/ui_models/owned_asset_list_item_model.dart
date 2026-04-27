import 'package:flutter/material.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';

class OwnedAssetListItemModel {
  final String assetId;
  final AssetType type;

  // Header Info
  final String title;             // e.g. "Gram Altın"
  final String amountText;        // e.g. "12.50 gr"
  final String currentPriceText;  // e.g. "2,950.00 TL" (Unit Price)
  final String totalValueText;    // e.g. "35,000 TL"

  // PnL Info
  final String pnlPercent;        // e.g. "%15.4"
  final Color pnlColor;

  // Expanded Detail Info
  final String avgCostText;       // e.g. "2,400 TL" (Ort. Maliyet)
  final String pnlValueText;      // e.g. "+5,000 TL" (Absolute PnL)

  // [YENİ EKLENEN ALANLAR]: Arayüzün doğrudan okuyacağı kısımlar
  final String displayTitle;
  final String? displaySubtitle;

  const OwnedAssetListItemModel({
    required this.assetId,
    required this.type,
    required this.title,
    required this.amountText,
    required this.currentPriceText,
    required this.totalValueText,
    required this.pnlPercent,
    required this.pnlColor,
    required this.avgCostText,
    required this.pnlValueText,
    required this.displayTitle,
    required this.displaySubtitle,
  });
}