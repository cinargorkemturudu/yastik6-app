import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../ui_models/current_rates_ticker_model.dart';
import 'ticker_item.dart';

class CurrentRatesTicker extends StatefulWidget {
  final List<TickerItemUiModel> items;

  const CurrentRatesTicker({
    super.key,
    required this.items,
  });

  @override
  State<CurrentRatesTicker> createState() => _CurrentRatesTickerState();
}

class _CurrentRatesTickerState extends State<CurrentRatesTicker> with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final Ticker _ticker;

  Duration _lastElapsed = Duration.zero;
  List<TickerItemUiModel> _loopedItems = [];

  static const double _pixelsPerSecond = 30;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _rebuildLoopedItems(widget.items);

    _ticker = createTicker(_onTick);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _ticker.start();
    });
  }

  @override
  void didUpdateWidget(covariant CurrentRatesTicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    final structureChanged = !_sameStructure(oldWidget.items, widget.items);
    final valuesChanged = !_sameValues(oldWidget.items, widget.items);

    if (structureChanged) {
      _rebuildLoopedItems(widget.items);
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    } else if (valuesChanged) {
      setState(() {
        _updateLoopedItems(widget.items);
      });
    }
  }

  bool _sameStructure(List<TickerItemUiModel> a, List<TickerItemUiModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].assetCode != b[i].assetCode) return false;
    }
    return true;
  }

  bool _sameValues(List<TickerItemUiModel> a, List<TickerItemUiModel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].bid != b[i].bid || a[i].ask != b[i].ask) return false;
    }
    return true;
  }

  void _rebuildLoopedItems(List<TickerItemUiModel> items) {
    if (items.isEmpty) {
      _loopedItems = [];
      if (mounted) setState(() {});
      return;
    }
    _loopedItems = [...items, ...items];
    if (mounted) setState(() {});
  }

  void _updateLoopedItems(List<TickerItemUiModel> items) {
    if (items.isEmpty) {
      _loopedItems = [];
      return;
    }
    final next = List<TickerItemUiModel>.from(items, growable: false);
    _loopedItems = [...next, ...next];
  }

  void _onTick(Duration elapsed) {
    if (!_scrollController.hasClients) return;

    final deltaMilliseconds = (elapsed - _lastElapsed).inMilliseconds;
    _lastElapsed = elapsed;

    if (deltaMilliseconds <= 0) return;

    final position = _scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final viewport = position.viewportDimension;

    if (maxScroll <= 0) return;

    final singleLoopExtent = (maxScroll + viewport) / 2;

    final step = _pixelsPerSecond * (deltaMilliseconds / 1000.0);
    var nextOffset = position.pixels + step;

    if (nextOffset >= singleLoopExtent) {
      nextOffset -= singleLoopExtent;
      if (nextOffset < 0) nextOffset = 0;
    }

    position.jumpTo(nextOffset);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loopedItems.isEmpty) return const SizedBox(height: 28);

    return SizedBox(
      height: 28,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _loopedItems.length,
        itemBuilder: (context, i) => TickerItem(model: _loopedItems[i]),
      ),
    );
  }
}