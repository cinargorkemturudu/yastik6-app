import 'package:flutter/material.dart';
import 'package:yastik_alti/ui/ui_models/lot_ui_model.dart';
import 'package:yastik_alti/ui/widgets/cards/lot_card.dart';
import 'package:yastik_alti/ui/theme/app_colors.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';
import 'package:yastik_alti/ui/theme/app_text_style.dart';

class RecentLotsSection extends StatefulWidget {
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
  State<RecentLotsSection> createState() => _RecentLotsSectionState();
}

class _RecentLotsSectionState extends State<RecentLotsSection> {
  bool _isAtBottom = false;
  final ScrollController _scrollController = ScrollController();

  // Navigation Bar yüksekliği ve cihazın alt güvenli alanı için bırakılan pay
  final double _navbarClearance = 116.0;

  @override
  void initState() {
    super.initState();
    // Eğer liste çok kısaysa (ekrana sığıyorsa) en başta altını kapatması için kontrol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBottom();
    });
  }

  // [EKLENDİ]: Veri değiştiğinde (ör. toggle ile 2 karta düştüğünde) alt sınırı tekrar kontrol eder.
  @override
  void didUpdateWidget(covariant RecentLotsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lots.length != oldWidget.lots.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkBottom();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkBottom() {
    if (!_scrollController.hasClients) return;
    // Listenin bitmesine 15px kala altı kapat (zıplamaları önler)
    final atBottom = _scrollController.position.extentAfter <= 15.0;
    if (atBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = atBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lots.isEmpty) return const SizedBox.shrink();

    // [VİZYON]: Stack kullanarak arka planı (mor kutu) ve içeriği (liste) birbirinden ayırdık.
    return Stack(
      children: [
        // --- 1. ARKA PLAN VE ÇERÇEVE KATMANI ---
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          top: 0,
          left: 0,
          right: 0,
          // SİHİR BURADA: En dibe vurunca kutu Navigation Bar'ın arkasından çıkıp üstüne oturur!
          bottom: _isAtBottom ? _navbarClearance : 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: AppAlphas.tint),
              borderRadius: _isAtBottom
                  ? const BorderRadius.all(Radius.circular(24))
                  : const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: AppColors.brandBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
                left: BorderSide(
                  color: AppColors.brandBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
                right: BorderSide(
                  color: AppColors.brandBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
                // [DÜZELTİLDİ]: width 0.0 hatasını engellemek için her durumda 1.0'a sabitlendi.
                bottom: BorderSide(
                  color: AppColors.brandBlue.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
            ),
          ),
        ),

        // --- 2. İÇERİK VE MASKE KATMANI ---
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (Rect rect) {
              if (_isAtBottom) {
                // En dipte maske kapanır, netlik gelir
                return const LinearGradient(
                  colors: [Colors.white, Colors.white],
                ).createShader(rect);
              }
              // Gezinirken alt tarafta sönümleme (fading) efekti çalışır
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0.0, 0.70, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SABİT BAŞLIK ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.titles.recentTransactions.toUpperCase(),
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.brandBlue.withValues(alpha: 0.8),
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onShowAll,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt,
                              size: 14,
                              color: AppColors.brandBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.common.showAll,
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

                // --- LİSTE ---
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis == Axis.vertical) {
                        _checkBottom();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      controller: _scrollController,
                      // Listenin son elemanı tam görünmesi için bırakılan pay
                      padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        _navbarClearance + 16,
                      ),
                      // [DÜZELTİLDİ]: Liste kısa olsa bile kaydırma fiziği aktif kalır, donmayı önler.
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: widget.lots.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final lotModel = widget.lots[index];
                        return LotCard(
                          model: lotModel,
                          onEdit: () => widget.onEdit(lotModel.transactionId),
                          onDelete: () =>
                              widget.onDelete(lotModel.transactionId),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
