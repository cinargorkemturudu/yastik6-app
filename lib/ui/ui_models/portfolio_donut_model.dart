import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';

class PortfolioDonutItem {
  final AssetType type;
  final String title;
  final Decimal tlValue; // Upgraded to Decimal
  final Decimal pnlTl;   // Upgraded to Decimal
  final double pnlPct;   // Percentage can stay double for UI display
  final Color color;

  const PortfolioDonutItem({
    required this.type,
    required this.title,
    required this.tlValue,
    required this.pnlTl,
    required this.pnlPct,
    required this.color,
  });
}

class PortfolioDonutModel {
  final Decimal totalTl;    // Upgraded to Decimal
  final Decimal totalPnlTl; // Upgraded to Decimal
  final double totalPnlPct;
  final String totalValueText;
  final String totalPnlText;
  final Color pnlColor;

  final List<PortfolioDonutItem> items;

  const PortfolioDonutModel({
    required this.totalTl,
    required this.totalPnlTl,
    required this.totalPnlPct,
    required this.totalValueText,
    required this.totalPnlText,
    required this.pnlColor,
    required this.items,
  });
}