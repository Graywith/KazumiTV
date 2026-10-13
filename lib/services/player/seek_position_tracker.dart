/// Keep an optimistic seek target until the native player acknowledges it.
class SeekPositionTracker {
  final Set<int> _pending = {};
  int _serial = 0;
  int? _latest;
  Duration? _target;
  DateTime? _expires;
  bool interactive = false;

  int begin(Duration target) {
    final token = ++_serial;
    _pending.add(token);
    _latest = token;
    preview(target);
    return token;
  }

  void preview(Duration target) {
    _target = target;
    _expires = DateTime.now().add(const Duration(seconds: 3));
  }

  void finish(int token, {required bool success}) {
    if (!_pending.remove(token)) return;
    if (success && token == _latest) {
      _expires = DateTime.now().add(const Duration(seconds: 3));
    }
    if (!success && token == _latest && _pending.isEmpty) _target = null;
  }

  Duration position(Duration native, {DateTime? now}) {
    final target = _target;
    if (target == null) return native;
    if (interactive || _pending.isNotEmpty) return target;
    if ((native - target).inMilliseconds.abs() <= 1000 ||
        !(now ?? DateTime.now()).isBefore(_expires!)) {
      _target = null;
      return native;
    }
    return target;
  }

  void clear() {
    _pending.clear();
    _target = null;
    _latest = null;
    interactive = false;
  }
}
