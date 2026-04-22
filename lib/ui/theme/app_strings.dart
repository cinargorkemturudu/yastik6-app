// lib/ui/theme/app_strings.dart
class AppStrings {
  AppStrings._();

  static const common = _CommonStrings();
  static const labels = _LabelStrings();
  static const titles = _TitleStrings();
  static const form = _FormStrings();
  static const messages = _MessageStrings();
  static const categories = _CategoryStrings();
  static const navigation = _NavigationStrings();
  static const converter = _ConverterStrings();
}

class _CommonStrings {
  const _CommonStrings();

  final String search = "Ara";
  final String save = "Kaydet";
  final String update = "Güncelle";
  final String cancel = "İptal";
  final String delete = "Sil";
  final String edit = "Düzenle";
  final String showAll = "Tümünü Gör";
  final String ok = "Tamam";
  final String confirmSell = "Satışı Onayla";
  final String add = "Ekle";
  final String select = "Seçin";
  final String menu = "Menü";
}

class _LabelStrings {
  const _LabelStrings();

  final String buy = "Alış";
  final String sell = "Satış";
  final String avgCost = "Ortalama Maliyet";
  final String totalPnl = "Toplam Kar/Zarar";
  final String activeRemaining = "Aktif (Kalan)";
  final String realizedSold = "Gerçekleşen (Satılan)";
  final String profitRealization = "Kar Realizasyonu";

  final String selectedPrice = "Seçili Fiyat";
  final String currentPrice = "Anlık Fiyat";
  final String unitPnl = "Birim K/Z";
  final String units = "adet";
  final String avgShort = "Ort";
  final String maxShort = "Max";
  final String minShort = "Min";
}

class _TitleStrings {
  const _TitleStrings();

  final String history = "İşlem Geçmişi";
  final String generalPortfolio = "Genel Portföy Özeti";
  final String recentTransactions = "Son İşlemler";
  final String profitMode = "Kar Modu";
  final String totalValue = "Toplam Değer";
  final String assetType = "Varlık Tipi";
  final String liveMarkets = "Canlı Piyasalar";
  final String tickerCustomization = "Şerit Kişiselleştirme";

  String portfolioOf(String categoryName) => "$categoryName Portföyü";
  String profitOf(String categoryName) => "$categoryName Karı";
  final String totalRealizedProfit = "Toplam Gerçekleşen Kar";
  String assetsOf(String categoryName) => "$categoryName Varlıkları";

  final String systemHealthy = "Sistem Sağlıklı";
  final String connectionLost = "Bağlantı Koptu";
  final String delayedData = "Gecikmeli Veri";
  final String cloudBackup = "Bulut Yedekleme";

  // [DÜZELTİLDİ] Eksik olan başlıklar eklendi
  final String googleDriveBackup = "Google Drive Yedekleme";
  final String icloudBackup = "iCloud Yedekleme";
}

class _FormStrings {
  const _FormStrings();

  final String amount = "Miktar";
  final String date = "Tarih";
  final String noteOptional = "Not (Opsiyonel)";

  final String buyPrice = "Alış Fiyatı (TL)";
  final String sellPrice = "Satış Fiyatı (TL)";

  final String currentBuyRate = "Anlık Alış Kuru";
  final String currentSellRate = "Anlık Satış Kuru";

  final String searchAssetHint = "Varlık ara (Örn: Altın, Dolar)";
}

class _MessageStrings {
  const _MessageStrings();

  final String emptyData = "Görüntülenecek veri bulunmuyor.";
  final String emptyTicker = "Bu kategori için anlık piyasa verisi bulunamadı.";
  String noResultsFor(String query) => "'$query' ile eşleşen sonuç bulunamadı.";

  final String deleteWarningTitle = "İşlemi Sil?";
  final String deleteWarningBody = "Bu işlem geri alınamaz. Portföy hesaplamalarınız kalıcı olarak güncellenecektir.";

  final String invalidAmount = "Lütfen geçerli bir miktar giriniz.";
  final String invalidPrice = "Lütfen geçerli bir fiyat giriniz.";
  final String insufficientBalance = "Yetersiz bakiye. Satış miktarı, mevcut varlık miktarını aşamaz.";
  final String transactionFailed = "İşlem başarısız";
  final String invalidForm = "Lütfen geçerli bir miktar ve fiyat giriniz.";

  final String emptyPortfolioForSell = "Portföyünüzde satışı yapılabilecek aktif bir varlık bulunmuyor.";
  final String selectAssetToBegin = "İşleme başlamak için lütfen bir varlık seçin.";
  String insufficientBalanceAmount(num amount) => "Yetersiz bakiye. Elinizde $amount adet bulunuyor.";
  String transactionFailedWith(String error) => "Kayıt sırasında hata oluştu: $error";

  final String systemHealthyBody = "Tüm piyasa verileri güncel.";
  final String offlineBody = "Sistem çevrimdışı. Sadece önbellekteki veriler gösteriliyor.";
  final String degradedBodyPrefix = "Şu veri tiplerinde gecikme yaşanıyor: ";

  final String menuPlaceholder = "Menü Seçenekleri Buraya Gelecek";
  final String converterUnderConstruction = "Çevirici Ekranı\n(Yapım Aşamasında)";

  final String chartLoadFailed = "Grafik yüklenemedi.";
  final String noDataForRange = "Bu aralık için veri yok.";

  final String emptyPastDate = "Geçmişteki bir kararın sonucunu görmek için tarih seçin.";
  final String noPastDataFound = "Seçilen tarih için geçmiş veri bulunamadı.";
  final String editUnderConstruction = "İşlem düzenleme modu yakında yeni tasarımla aktif olacak.";

  // Bulut Yedekleme Mesajları
  final String googleDriveBackupSubtitle = "Kişisel kasanızı Google Drive ile yedekleyin";
  final String icloudBackupSubtitle = "Kişisel kasanızı iCloud ile yedekleyin";

  final String googleDriveSuccess = "Verileriniz Google Drive'a başarıyla yedeklendi.";
  final String icloudSuccess = "Verileriniz iCloud'a başarıyla yedeklendi.";

  final String googleDriveError = "Google Drive bağlantısında bir sorun oluştu.";
  final String icloudError = "iCloud erişimi başarısız. Lütfen ayarlarınızı kontrol edin.";
  final String loginCanceled = "Giriş işlemi iptal edildi veya yetki verilmedi.";
  final String backupFailed = "Yedekleme işlemi tamamlanamadı.";

  final String unexpectedError = "Beklenmeyen bir hata oluştu.";
  final String transactionNotFound = "İşlem veritabanında bulunamadı.";
  final String editLockedWarning = "Bu işlemden satış yapıldığı için finansal veriler değiştirilemez. Sadece notu güncelleyebilirsiniz.";

  String connectionEstablished(String email) => "Bağlantı Kuruldu: $email";
}

class _CategoryStrings {
  const _CategoryStrings();

  final String metal = "Maden";
  final String currency = "Döviz";
  final String stock = "Hisse";
  final String crypto = "Kripto";
  final String indicator = "Gösterge";
  final String all = "Tüm Varlıklar";
}

class _NavigationStrings {
  const _NavigationStrings();

  final String portfolio = "Portföy";
  final String market = "Piyasa";
  final String converter = "Çevirici";
}

class _ConverterStrings {
  const _ConverterStrings();

  final String modeBank = "Banka (Makaslı)";
  final String modePhysical = "Sarrafiye (Parite)";
  final String sellAsset = "Satılacak Varlık";
  final String buyAsset = "Alınacak Varlık";
  final String opportunityCost = "Fırsat Maliyeti Analizi";
  final String selectDate = "Geçmiş Bir Tarih Seçin";
  final String modeWarning = "Seçilen varlıklar Kapalıçarşı'da (Fiziki) takas edilemez.";

  final String ifYouTradedThatDay = "Eğer bu takası tam o gün yapsaydınız:";
  final String youWouldHaveReceived = "alacaktınız.";
  final String difference = "Fark:";
  final String pastAnalysisDisclaimer = "*Geçmiş analizler gün sonu kapanış fiyatları üzerinden oluşturulur.";
}