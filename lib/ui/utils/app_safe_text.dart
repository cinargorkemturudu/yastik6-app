import 'package:flutter/material.dart';

/// Finansal uygulamalarda büyük sayıların ve uzun varlık isimlerinin
/// ekrandan taşmasını engelleyen, standartlaştırılmış güvenli metin bileşeni.
class AppSafeText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final bool flex; // Genellikle Row/Column içinde kullanıldığı için esneklik (Flexible) varsayılan olarak açıktır.

  const AppSafeText(
      this.text, {
        super.key,
        this.style,
        this.maxLines = 1,
        this.flex = true,
      });

  @override
  Widget build(BuildContext context) {
    // 1. Orijinal Metin Bileşeni (Taşma korumalı)
    Widget content = Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );

    // 2. Layout Koruması
    // Eğer bir Row veya Column içindeyse diğer widget'ları itip ekranı patlatmasını (RenderFlex Overflow) 
    // önlemek için Flexible ile sarılır.
    return flex ? Flexible(child: content) : content;
  }
}