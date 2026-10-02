import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:read_next/state/navigation_provider.dart';
import 'package:read_next/state/zoom_provider.dart';

void main() {
  group('NavigationNotifier Tests', () {
    test('Navigation respects page boundaries and updates rotation', () {
      final container = ProviderContainer();
      final notifier = container.read(navigationProvider.notifier);

      notifier.setTotalPages(10);
      expect(container.read(navigationProvider).currentPage, equals(1));
      expect(container.read(navigationProvider).totalPages, equals(10));

      notifier.nextPage();
      expect(container.read(navigationProvider).currentPage, equals(2));

      notifier.prevPage();
      expect(container.read(navigationProvider).currentPage, equals(1));

      // Attempt previous page at start
      notifier.prevPage();
      expect(container.read(navigationProvider).currentPage, equals(1));

      notifier.lastPage();
      expect(container.read(navigationProvider).currentPage, equals(10));

      // Attempt next page at end
      notifier.nextPage();
      expect(container.read(navigationProvider).currentPage, equals(10));

      // Rotation
      expect(container.read(navigationProvider).rotation, equals(0));
      notifier.rotateClockwise();
      expect(container.read(navigationProvider).rotation, equals(90));
      notifier.rotateClockwise();
      expect(container.read(navigationProvider).rotation, equals(180));
      notifier.rotateClockwise();
      expect(container.read(navigationProvider).rotation, equals(270));
      notifier.rotateClockwise();
      expect(container.read(navigationProvider).rotation, equals(0));
    });
  });

  group('ZoomNotifier Tests', () {
    test('Zoom scales correctly and stays within limits', () {
      final container = ProviderContainer();
      final notifier = container.read(zoomProvider.notifier);

      expect(container.read(zoomProvider).scale, equals(1.0));

      notifier.zoomIn();
      expect(container.read(zoomProvider).scale, equals(1.25));

      notifier.zoomOut();
      expect(container.read(zoomProvider).scale, equals(1.0));

      notifier.setFitMode(FitMode.fitWidth);
      expect(container.read(zoomProvider).scale, equals(1.25));

      notifier.setFitMode(FitMode.actualSize);
      expect(container.read(zoomProvider).scale, equals(1.0));
    });

    test('Zooming does not automatically enable trimWhiteMargins (never cut on zoom)', () {
      final container = ProviderContainer();
      final notifier = container.read(zoomProvider.notifier);

      expect(container.read(zoomProvider).trimWhiteMargins, isFalse);
      notifier.zoomIn(); // 1.25
      expect(container.read(zoomProvider).trimWhiteMargins, isFalse);
      notifier.zoomIn(); // 1.50
      expect(container.read(zoomProvider).trimWhiteMargins, isFalse);
      notifier.setZoom(2.0);
      expect(container.read(zoomProvider).trimWhiteMargins, isFalse);
    });

    test('Upscale factor defaults to 1.5x and can be set or cycled', () {
      final container = ProviderContainer();
      final notifier = container.read(zoomProvider.notifier);

      expect(container.read(zoomProvider).upscaleFactor, equals(1.5));

      notifier.setUpscaleFactor(2.0);
      expect(container.read(zoomProvider).upscaleFactor, equals(2.0));

      notifier.cycleUpscale(); // 2.0 -> 3.0
      expect(container.read(zoomProvider).upscaleFactor, equals(3.0));

      notifier.cycleUpscale(); // 3.0 -> 1.0
      expect(container.read(zoomProvider).upscaleFactor, equals(1.0));

      notifier.cycleUpscale(); // 1.0 -> 1.5
      expect(container.read(zoomProvider).upscaleFactor, equals(1.5));
    });
  });
}
