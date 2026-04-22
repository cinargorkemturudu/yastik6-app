// lib/ui/states/ticker_preferences_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yastik_alti/core/app_log.dart';

// ============================================================================
// ADIM 1: PROVIDER TANIMI (Global Erişim Noktası)
// ============================================================================
// Bu değişken, uygulamanın herhangi bir yerinden (UI veya başka Provider) 
// bu state'e ulaşmamızı sağlayan köprüdür. 
// Veriyi cihaz hafızasından okuyacağımız (await) için AsyncNotifierProvider kullanıyoruz.
// İçerisinde sadece "Seçili olan Varlıkların Kodlarını (List<String>)" tutacağız.
final tickerPreferencesProvider = AsyncNotifierProvider<TickerPreferencesNotifier, List<String>>(
  TickerPreferencesNotifier.new,
);


// ============================================================================
// ADIM 2: NOTIFIER SINIFI (İş Mantığı ve State Yönetimi)
// ============================================================================
// UI'ın ihtiyacı olan fonksiyonları (toggle) barındıran ve verinin mutasyonunu
// (değişimini) kontrol eden ana sınıftır.
class TickerPreferencesNotifier extends AsyncNotifier<List<String>> {

  // SharedPreferences'a kaydederken kullanacağımız benzersiz anahtar kelime
  static const _prefsKey = 'ticker_active_assets';

  // Fallback (B Planı): Kullanıcı uygulamayı ilk kurduğunda şerit boş kalmasın diye
  // gösterilecek varsayılan varlık listesi.
  static const _defaultAssets = ['USDTRY=X', 'EURTRY=X', 'GRAM_ALTIN', 'BTC-USD'];

  // --------------------------------------------------------------------------
  // A. BUILD METODU (Initialization / Başlangıç)
  // --------------------------------------------------------------------------
  // Bu metot, Provider ilk defa izlendiğinde (ref.watch) otomatik çalışır.
  // Görevi: State'in (bizim durumumuzda List<String>) İLK HALİNİ dönmektir.
  @override
  Future<List<String>> build() async {
    AppLog.debug('TickerPreferencesNotifier built: Loading preferences', domain: 'STATE');

    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getStringList(_prefsKey);

    // Hafızada varsa onu dön, yoksa null coalescing (??) ile varsayılanı dön.
    return savedList ?? _defaultAssets;
  }

  // --------------------------------------------------------------------------
  // B. AKSİYON / MUTASYON METODU (UI'dan tetiklenecek fonksiyon)
  // --------------------------------------------------------------------------
  // Kullanıcı arayüzde bir Checkbox'a (veya satıra) dokunduğunda bu metot çağrılır.
  Future<void> toggleAsset(String assetCode) async {
    // 1. Güvenlik Duvarı: State henüz belleğe yüklenmediyse (loading) dokunma
    if (state.value == null) return;

    // 2. Immutability (Değişmezlik) Kuralı: 
    // Riverpod (ve Flutter genelinde) referans tipli değişkenler (List, Map, Object)
    // doğrudan değiştirilmez (örn: list.add() yapılmaz). 
    // Mevcut listenin BİR KOPYASI (List.from) oluşturulur.
    final currentList = List<String>.from(state.value!);

    // 3. İş Mantığı (Ekle/Çıkar)
    if (currentList.contains(assetCode)) {
      currentList.remove(assetCode); // İşaretliyse kaldır
    } else {
      currentList.add(assetCode);    // İşaretli değilse ekle
    }

    // 4. UI'ı Tetikleme (Reaktivite)
    // Yeni kopyayı "state" değişkenine atadığımız an, bu Provider'ı (ref.watch)
    // dinleyen tüm ekranlar (Ticker Şeridi ve Ayarlar Bottom Sheet'i) anında yeniden çizilir.
    state = AsyncData(currentList);

    // 5. Kalıcı Kayıt (Side Effect)
    // Uygulama kapatılıp açıldığında tercihlerin kaybolmaması için diske yazıyoruz.
    // UI güncellenmesi beklemesin diye asenkron fire-and-forget mantığıyla çalışır.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, currentList);
      AppLog.debug('Ticker preferences saved: ${currentList.length} items', domain: 'STATE');
    } catch (e, stack) {
      AppLog.error('Failed to save ticker preferences', domain: 'STATE', error: e, stackTrace: stack);
    }
  }
}