import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/screens/portfolio_page.dart';
import 'package:yastik_alti/ui/widgets/add_asset/add_asset_sheet.dart';
import 'package:yastik_alti/ui/utils/category_helper.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {

  // --- [UX ŞAHESERİ BURADA DEVREYE GİRİYOR] ---
  void _handleTransaction(TransactionType type) {
    // Boş ekranı atla, kullanıcının niyetine göre DOĞRUDAN varlık seçiciyi aç!
    AddAssetSheet.showFlow(context, ref, type: type);
  }

  @override
  Widget build(BuildContext context) {
    // [MERKEZİ STANDART]: Market ekranı ile aynı kategorileri çekiyoruz.
    // En başa 'Tümü' seçeneğini ekleyerek listeyi portföye özel hale getiriyoruz.
    final categories = CategoryHelper.marketCategories;

    return DefaultTabController(
      length: categories.length, // Dinamik sekme sayısı
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: Text(AppStrings.titles.generalPortfolio, style: AppTextStyles.h2),
          // [CİLA]: Market ekranındaki şık TabBar tasarımını buraya da uyguladık.
        ),
        body: TabBarView(
          children: categories.map((cat) {
            final assetType = CategoryHelper.toAssetType(cat);
            return PortfolioPage(
              filterType: assetType,
              onTransaction: _handleTransaction,
            );
          }).toList(),
        ),
      ),
    );
  }
}