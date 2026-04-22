import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yastik_alti/core/app_log.dart';
import 'package:yastik_alti/di/providers.dart';
import 'package:yastik_alti/domain/models/dtos/asset_holding.dart';
import 'package:yastik_alti/domain/models/dtos/portfolio_data.dart';
import 'package:yastik_alti/domain/models/dtos/realized_profit.dart';
import 'package:yastik_alti/domain/models/entities/transaction.dart';
import 'package:yastik_alti/ui/states/live_price_provider.dart';
import 'package:yastik_alti/domain/models/dtos/market_state.dart';

// 1. [YENİ] Dart 3 Record Tipi: Tüm DB verisini tek bir pakette tutar.
typedef RawDbData = ({
List<AssetHolding> holdings,
List<Transaction> transactions,
Map<String, List<Map<String, dynamic>>> allocations,
PortfolioRealizedSummary realized,
});

// 2. [YENİ] 4 ayrı Provider yerine tek bir Master Provider
final _dbMasterProvider = FutureProvider<RawDbData>((ref) async {
  final service = ref.watch(portfolioServiceProvider);

  // Bağımsız verileri PARALEL (aynı anda) çekerek performansı ikiye katlıyoruz
  final results = await Future.wait([
    service.getHoldings(),
    service.getAllTransactions(),
    service.getRealizedProfitReport(),
  ]);

  final holdings = results[0] as List<AssetHolding>;
  final transactions = results[1] as List<Transaction>;
  final realized = results[2] as PortfolioRealizedSummary;

  // Sadece işlemlere (transactions) bağımlı olan tahsisatları (allocations) sonra çekiyoruz
  final allocations = await service.loadAllocationsMap(transactions);

  return (
  holdings: holdings,
  transactions: transactions,
  allocations: allocations,
  realized: realized,
  );
});

final portfolioProvider = NotifierProvider<PortfolioNotifier, PortfolioData>(PortfolioNotifier.new);

class PortfolioNotifier extends Notifier<PortfolioData> {

  @override
  PortfolioData build() {
    AppLog.debug('PortfolioEngine BUILD triggered. Gathering data...', domain: 'STATE');

    final marketState = ref.watch(livePriceProvider).valueOrNull ?? MarketState.initial();

    final dbAsync = ref.watch(_dbMasterProvider);

    // 1. ÇÖZÜMÜN KALBİ BURASI: Önce adamın kafası yarılmış mı ona bak!
    if (dbAsync.hasError) {
      AppLog.error('Veritabanından veri çekilirken patladı: ${dbAsync.error}', domain: 'STATE', error: dbAsync.error);
      // Hata paketini UI'a yolla. UI artık errorMessage'i görüp boş loading yerine kırmızı bir hata ekranı çizebilir.
      return PortfolioData.error('Veritabanı okunamadı. Lütfen uygulamayı yeniden başlatın.');
    }

    final db = dbAsync.valueOrNull;

    // 2. Kafası yarılmamış ama eli de boş. Demek ki hala depoda arıyor.
    if (db == null) {
      return PortfolioData.initial();
    }

    AppLog.debug('Computing snapshot... (Holdings: ${db.holdings.length}, Prices: ${marketState.priceMap.length})', domain: 'STATE');

    final stopwatch = Stopwatch()..start();

    final snapshot = ref.read(portfolioServiceProvider).computeSnapshot(
      holdings: db.holdings,
      prices: marketState.priceMap,
    );

    stopwatch.stop();

    AppLog.info('Snapshot computed in ${stopwatch.elapsedMilliseconds}ms. Positions: ${snapshot.positions.length}', domain: 'STATE');

    if (!dbAsync.isLoading && db.holdings.isNotEmpty) {
      AppLog.insight('portfolio_calculated', metadata: {
        'duration_ms': stopwatch.elapsedMilliseconds,
        'holdings_count': db.holdings.length,
      });
    }

    return PortfolioData(
      snapshot: snapshot,
      realizedSummary: db.realized,
      transactions: db.transactions,
      allocationsMap: db.allocations,
      isLoading: dbAsync.isLoading,
      errorMessage: null, // Her şey yolunda, hata yok.
    );
  }

  void refreshDb() {
    AppLog.info('Database refresh requested. Invalidating Master Provider...', domain: 'STATE');
    AppLog.insight('portfolio_db_refresh');

    // Artık sadece tek bir yeri invalid ediyoruz
    ref.invalidate(_dbMasterProvider);
  }
}