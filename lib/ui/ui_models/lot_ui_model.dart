import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import '../../domain/models/entities/asset.dart';

class SubTransactionUiModel {
  final String date;
  final String amount;
  final String price;
  final String profitText;
  final Color profitColor;

  SubTransactionUiModel({
    required this.date,
    required this.amount,
    required this.price,
    required this.profitText,
    required this.profitColor,
  });
}

class LotUiModel {
  final String transactionId;
  final String dateText;
  final DateTime sortDate;
  final String? note;

  final String assetName;
  final String symbol;
  final AssetType type;

  final String originalAmountText;
  final String remainingAmountText;
  final String soldAmountText;
  final String buyPriceText;
  final String totalCostText;

  final String profitPercent;

  final Decimal amountValue; // UPDATED to Decimal
  String get pureAmount => amountValue.toString();

  final String? currentUnrealizedPnl;
  final Color? unrealizedColor;
  final String? totalRealizedPnl;
  final Color? realizedColor;

  String get pnlText => (totalRealizedPnl != null) ? totalRealizedPnl! : (currentUnrealizedPnl ?? "");
  Color get pnlColor => (realizedColor != null) ? realizedColor! : (unrealizedColor ?? Colors.white);

  final double progressVal;
  final List<SubTransactionUiModel> allocations;
  final bool isSellCard;

  const LotUiModel({
    required this.transactionId,
    required this.dateText,
    required this.sortDate,
    this.note,
    required this.assetName,
    required this.symbol,
    required this.type,
    required this.originalAmountText,
    required this.remainingAmountText,
    required this.soldAmountText,
    required this.buyPriceText,
    required this.totalCostText,
    required this.amountValue, // EXPECTS Decimal
    required this.profitPercent,
    this.currentUnrealizedPnl,
    this.unrealizedColor,
    this.totalRealizedPnl,
    this.realizedColor,
    this.progressVal = 1.0,
    this.allocations = const [],
    this.isSellCard = false,
  });
}