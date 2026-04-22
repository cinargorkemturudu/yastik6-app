import 'package:decimal/decimal.dart';
import '../entities/asset.dart';

abstract class PortfolioReportBase {
  Decimal get totalDisplayValue;
  Decimal get totalPnlTl;
  double get totalPnlPct;
  List<ReportItemBase> get reportItems;
}

abstract class ReportItemBase {
  AssetType get assetType;
  String get displayTitle;
  Decimal get donutValue;
  Decimal get itemPnlTl;
  double get itemPnlPct;

  Decimal get itemCostBasis;
}