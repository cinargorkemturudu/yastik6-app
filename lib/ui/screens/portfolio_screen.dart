import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/screens/portfolio_page.dart';
import 'package:yastik_alti/ui/widgets/add_asset/add_asset_sheet.dart';
import '../../core/app_log.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Index 0 is our 'All' or 'General' tab. 
    // Any index greater than 0 corresponds to AssetType.values[index - 1].
    final tabName = index == 0 ? 'general' : AssetType.values[index - 1].name;

    AppLog.insight('swipe_tab', metadata: {'tab': tabName});
  }

  // --- [UX ŞAHESERİ BURADA DEVREYE GİRİYOR] ---
  void _handleTransaction(TransactionType type) {
    // Boş ekranı atla, kullanıcının niyetine göre DOĞRUDAN varlık seçiciyi aç!
    AddAssetSheet.showFlow(context, ref, type: type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          // Index 0: The "All Assets" view
          PortfolioPage(
            filterType: null,
            onTransaction: _handleTransaction,
          ),
          // Index 1 and beyond: Dynamically generated pages for every AssetType
          ...AssetType.values
              .where((type) => type != AssetType.indicator)
              .map(
                (type) => PortfolioPage(
              filterType: type,
              onTransaction: _handleTransaction,
            ),
          ),
        ],
      ),
    );
  }
}