enum LoopMode { none, all, one }

/// Abstraction over the playback core (TECH_SPEC §4.2). Only one implementation
/// owns the real media_kit Player; the UI never talks to it directly.
abstract interface class PlayerEngine {
  Stream<bool> get playing;
  Stream<Duration> get position;
  Stream<int?> get currentIndex;
  Stream<bool> get completed;
  Stream<String> get errors;

  Future<void> openQueue(
    List<String> filePaths, {
    int startIndex = 0,
    bool autoplay = true,
  });
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> jumpTo(int index);
  Future<void> add(String filePath);
  Future<void> insert(int index, String filePath);

  /// Removes the item at [index]. If it is the current item, the next one
  /// (or the previous one at the end of the list) becomes current.
  Future<void> remove(int index);

  /// Moves an item so that it ends up at [to] in the resulting list.
  Future<void> move(int from, int to);
  Future<void> setLoopMode(LoopMode mode);
  Future<void> dispose();
}
