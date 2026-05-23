import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart'; // [EKLENDİ] AssetType için
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/screens/type_category_screen.dart';
import 'package:yastik_alti/ui/utils/asset_visual_mapper.dart'; // [EKLENDİ] Enum'dan isim okumak için
import 'package:yastik_alti/ui/widgets/portfolio_overview_section.dart';
import 'package:yastik_alti/ui/states/home_view_model.dart';
import 'package:yastik_alti/ui/states/portfolio_provider.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';

class PortfolioPage extends ConsumerWidget {
  // [DÜZELTİLDİ]: String? categoryFilter yerine AssetType? filterType (Enum) kullanıyoruz.
  // Junior Notu: Alt katmanlar (Page, Section vb.) her zaman Enum ile çalışmalıdır.
  final AssetType? filterType;
  final Function(TransactionType, AssetType?) onTransaction;

  const PortfolioPage({
    super.key,
    this.filterType, // required değil çünkü 'Tümü' null olabilir
    required this.onTransaction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioData = ref.watch(portfolioProvider);
    final uiState = ref.watch(homeViewModelProvider);

    if (portfolioData.isLoading && portfolioData.snapshot.positions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // [DÜZELTİLDİ]: İsim lazımsa Mapper'ı kullanıyoruz. 
    // String'i kapıda (Screen'de) bıraktık, içeride güvende (Enum) çalışıyoruz.
    final filterName = filterType != null
        ? AssetVisualMapper.categoryNameOf(filterType!)
        : "";

    String pageTitle;

    if (uiState.isRealizedMode) {
      pageTitle = filterType == null
          ? AppStrings.titles.totalRealizedProfit
          : AppStrings.titles.profitOf(filterName);
    } else {
      pageTitle = filterType == null
          ? AppStrings.titles.generalPortfolio
          : AppStrings.titles.portfolioOf(filterName);
    }

    return PortfolioOverviewSection(
      title: pageTitle,
      // [DÜZELTİLDİ]: Alt widget'lara temiz Enum verisini gönderiyoruz.
      filterType: filterType,
      onTransaction: onTransaction,
      onLegendTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(
              // [DÜZELTİLDİ]: Detay ekranına da Enum gönderiyoruz.
              categoryType: filterType,
              categoryName: filterType == null
                  ? AppStrings.categories.all
                  : AppStrings.titles.assetsOf(filterName),
            ),
          ),
        );
      },
    );
  }
}