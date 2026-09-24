import 'package:flutter/material.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:decimal/decimal.dart';

class OwnedAssetListItemModel {
  final String assetId;
  final AssetType type;

  // Header Info
  final String title;
  final String amountText;
  final String currentPriceText;
  final String totalValueText;

  // PnL Info
  final String pnlPercent;
  final Color pnlColor;

  // Expanded Detail Info
  final String avgCostText;
  final Decimal averageBuyPrice;
  final String pnlValueText;

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
    required this.averageBuyPrice,
    required this.pnlValueText,
    required this.displayTitle,
    required this.displaySubtitle,
  });
}