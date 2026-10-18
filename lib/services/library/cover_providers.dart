import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nyaplayer/data/db/database_providers.dart'
    show coverCacheProvider;
import 'package:nyaplayer/domain/cover_source.dart';
import 'package:nyaplayer/services/library/cover_cache.dart';

export 'package:nyaplayer/data/db/database_providers.dart'
    show coverCacheProvider;

final coverProvider = FutureProvider.autoDispose
    .family<CachedCover?, CoverSource>(
      (ref, source) => ref.watch(coverCacheProvider).load(source),
    );

/// Reuse resolved paths immediately when a responsive layout remounts. Watching
/// the async provider still validates disk files and publishes loading errors.
final resolvedCoverProvider = Provider.autoDispose
    .family<CachedCover?, CoverSource>((ref, source) {
      final result = ref.watch(coverProvider(source));
      if (result.hasValue) return result.value;
      return ref.watch(coverCacheProvider).peek(source);
    });
