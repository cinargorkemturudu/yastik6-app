// lib/ui/ui_models/ticker_preference_item_ui_model.dart
import 'package:yastik_alti/domain/models/entities/asset.dart';

class TickerPreferenceItemUiModel {
  final String assetCode;
  final String displayName;
  final AssetType type;
  final bool isSelected;

  const TickerPreferenceItemUiModel({
    required this.assetCode,
    required this.displayName,
    required this.type,
    required this.isSelected,
  });

  TickerPreferenceItemUiModel copyWith({
    String? assetCode,
    String? displayName,
    AssetType? type,
    bool? isSelected,
  }) {
    return TickerPreferenceItemUiModel(
      assetCode: assetCode ?? this.assetCode,
      displayName: displayName ?? this.displayName,
      type: type ?? this.type,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}