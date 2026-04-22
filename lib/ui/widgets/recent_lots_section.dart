import 'package:flutter/material.dart';
import 'package:yastik_alti/ui/ui_models/lot_ui_model.dart';
import 'package:yastik_alti/ui/widgets/cards/lot_card.dart';
// [EKLENDİ] Tasarım sistemimiz
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';

class RecentLotsSection extends StatelessWidget {
  final List<LotUiModel> lots;
  final VoidCallback onShowAll;
  final Function(String id) onEdit;
  final Function(String id) onDelete;

  const RecentLotsSection({
    super.key,
    required this.lots,
    required this.onShowAll,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (lots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- BAŞLIK ALANI ---
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol Başlık
              Text(
                AppStrings.titles.recentTransactions.toUpperCase(), // [DÜZELTİLDİ]
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
              // Sağ Buton (Tıklanabilir)
              GestureDetector(
                onTap: onShowAll,
                child: Row(
                  children: [
                    const Icon(Icons.bolt, size: 14, color: AppColors.brandBlue),
                    const SizedBox(width: 4),
                    Text(
                      AppStrings.common.showAll, // [DÜZELTİLDİ]
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- LİSTE ALANI ---
        ...lots.map((lotModel) => LotCard(
          model: lotModel,
          onEdit: () => onEdit(lotModel.transactionId),
          onDelete: () => onDelete(lotModel.transactionId),
        )),

        const SizedBox(height: 24),
      ],
    );
  }
}