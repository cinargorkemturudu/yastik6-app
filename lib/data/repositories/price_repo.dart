import 'package:yastik_alti/data/remote/remote_market_data.dart';
import 'package:yastik_alti/domain/irepositories/price_irepository.dart';
import 'package:yastik_alti/domain/models/value_objects/price_point.dart';
import 'package:yastik_alti/domain/models/value_objects/price_quote.dart';

class PriceRepo implements PriceIRepository {
  final RemoteMarketData _remote;

  PriceRepo(this._remote);

  @override
  Future<List<PriceQuote>> getLatestAll() => _remote.fetchLatestAll();

  @override
  Future<List<PricePoint>> getHistory(String assetCode, String range) {
    return _remote.fetchHistory(assetCode: assetCode, range: range);
  }
}