import '../models/store_models.dart';
import 'catalog_store.dart';

/// واجهة متوافقة مع الشاشات — البيانات الفعلية من [CatalogStore] / قاعدة البيانات.
class MockStoreData {
  MockStoreData._();

  static CatalogStore? _store;

  static void bind(CatalogStore store) {
    _store = store;
  }

  static List<HomeBanner> get banners => _store?.banners ?? const [];

  static List<Category> get categories => _store?.categories ?? const [];

  static List<Product> get products => _store?.products ?? const [];

  static List<Product> get featured => _store?.featured ?? const [];

  static List<Product> byCategory(int categoryId) =>
      _store?.byCategory(categoryId) ?? const [];

  static Product? byId(int id) => _store?.byId(id);
}
