import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Dedicated on-disk cache for book cover images (native platforms only —
/// see _BookCoverFillImage). A cover not viewed again within [stalePeriod],
/// or bumped past [maxNrOfCacheObjects] by less-recently-used covers, is
/// deleted the next time the cache is touched; a separate manager (with its
/// own key/db) keeps this eviction policy independent of any other
/// CachedNetworkImage usage that might rely on the package's own default.
class BookCoverCacheManager extends CacheManager {
  static const key = 'bookCoverCache';

  static final BookCoverCacheManager _instance = BookCoverCacheManager._();

  factory BookCoverCacheManager() => _instance;

  BookCoverCacheManager._()
      : super(Config(
          key,
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
        ));
}
