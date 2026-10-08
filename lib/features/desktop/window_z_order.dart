/// Tracks window stacking order for the desktop shell.
///
/// Holds the ids of currently visible windows with the most recently
/// shown LAST, matching `Stack` paint order (later children paint on
/// top). Hidden windows are untracked, so closing always drops the id
/// and reopening appends it to the front.
class WindowZOrder {
  final List<String> _order = [];

  /// Visible window ids, oldest first.
  List<String> get order => List.unmodifiable(_order);

  /// Returns true when membership actually changed.
  bool setVisible(String id, bool visible) {
    final had = _order.contains(id);
    if (had == visible) return false;
    if (visible) {
      _order.add(id);
    } else {
      _order.remove(id);
    }
    return true;
  }

  /// Moves an already-visible window to the front. Returns false when
  /// the id is untracked or already frontmost (no rebuild needed).
  bool moveToFront(String id) {
    if (!_order.contains(id)) return false;
    if (_order.last == id) return false;
    _order
      ..remove(id)
      ..add(id);
    return true;
  }

  /// Rank for sorting `Stack` children ascending: untracked windows
  /// rank -1 (they render nothing anyway), tracked ones by open order.
  /// `List.sort` is stable, so untracked windows keep declaration order.
  int rank(String id) => _order.indexOf(id);

  void clear() => _order.clear();
}
