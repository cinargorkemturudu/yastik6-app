import 'package:yastik_alti/domain/models/entities/asset.dart';
import 'package:yastik_alti/ui/theme/app_strings.dart';

class CategoryHelper {
  /// Bottom Sheet'ler ve Ayarlar (Core) ekranları için standart kategoriler
  static List<String> get coreCategories => [
    AppStrings.categories.all,
    AppStrings.categories.metal,
    AppStrings.categories.currency,
    AppStrings.categories.stock,
    AppStrings.categories.crypto,
  ];

  /// Piyasa (Market) ekranı gibi geniş listeler için ek kategoriler (Örn: Göstergeler)
  static List<String> get marketCategories => [
    ...coreCategories,
    AppStrings.categories.indicator,
  ];

  /// UI'dan gelen String kategoriyi, Domain'deki AssetType ile eşleştirir
  static bool matchesCategory(AssetType type, String selectedCategory) {
    if (selectedCategory == AppStrings.categories.all) return true;
    if (selectedCategory == AppStrings.categories.metal) return type == AssetType.metal;
    if (selectedCategory == AppStrings.categories.currency) return type == AssetType.currency;
    if (selectedCategory == AppStrings.categories.crypto) return type == AssetType.crypto;
    if (selectedCategory == AppStrings.categories.stock) return type == AssetType.stock;
    if (selectedCategory == AppStrings.categories.indicator) return type == AssetType.indicator;
    return false;
  }
}