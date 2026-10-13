import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/services/player/seek_position_tracker.dart';

void main() {
  test(
    'Old native positions cannot overwrite queued 5-second target steps',
    () {
      final tracker = SeekPositionTracker();
      final first = tracker.begin(const Duration(seconds: 5));
      final second = tracker.begin(const Duration(seconds: 10));
      tracker.finish(first, success: true);
      expect(tracker.position(Duration.zero), const Duration(seconds: 10));
      expect(
        tracker.position(const Duration(seconds: 5)),
        const Duration(seconds: 10),
      );
      tracker.finish(second, success: true);
      expect(
        tracker.position(const Duration(seconds: 5)),
        const Duration(seconds: 10),
      );
      expect(
        tracker.position(const Duration(milliseconds: 10100)),
        const Duration(milliseconds: 10100),
      );
      expect(
        tracker.position(const Duration(seconds: 11)),
        const Duration(seconds: 11),
      );
    },
  );
  test(
    'Rewind to start remains stable until native position acknowledges zero',
    () {
      final tracker = SeekPositionTracker();
      final token = tracker.begin(Duration.zero);
      expect(tracker.position(const Duration(seconds: 5)), Duration.zero);
      tracker.finish(token, success: true);
      expect(tracker.position(const Duration(seconds: 5)), Duration.zero);
      expect(tracker.position(Duration.zero), Duration.zero);
    },
  );
  test(
    'Failed or unacknowledged seek eventually returns to actual position',
    () {
      final tracker = SeekPositionTracker();
      final token = tracker.begin(const Duration(seconds: 10));
      tracker.finish(token, success: false);
      expect(
        tracker.position(const Duration(seconds: 5)),
        const Duration(seconds: 5),
      );
      final next = tracker.begin(const Duration(seconds: 20));
      tracker.finish(next, success: true);
      expect(
        tracker.position(
          const Duration(seconds: 5),
          now: DateTime.now().add(const Duration(seconds: 4)),
        ),
        const Duration(seconds: 5),
      );
    },
  );
  test(
    'Old player completion does not release a new player seek, interactive preview is preserved',
    () {
      final tracker = SeekPositionTracker();
      final old = tracker.begin(const Duration(seconds: 10));
      tracker.clear();
      final current = tracker.begin(const Duration(seconds: 30));
      tracker.finish(old, success: true);
      expect(tracker.position(Duration.zero), const Duration(seconds: 30));
      tracker.finish(current, success: true);
      tracker.interactive = true;
      tracker.preview(const Duration(seconds: 40));
      expect(
        tracker.position(
          const Duration(seconds: 30),
          now: DateTime.now().add(const Duration(seconds: 30)),
        ),
        const Duration(seconds: 40),
      );
    },
  );
}
