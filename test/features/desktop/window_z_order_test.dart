import 'package:flutter_test/flutter_test.dart';
import 'package:jent_web/features/desktop/window_z_order.dart';

void main() {
  group('WindowZOrder', () {
    test('starts empty with everything unranked', () {
      final order = WindowZOrder();
      expect(order.order, isEmpty);
      expect(order.rank('mail'), -1);
    });

    test('latest shown window ranks last', () {
      final order = WindowZOrder()
        ..setVisible('mail', true)
        ..setVisible('music', true);

      expect(order.order, ['mail', 'music']);
      expect(order.rank('mail'), lessThan(order.rank('music')));
    });

    test('hiding drops the id; reopening moves it to the front', () {
      final order = WindowZOrder()
        ..setVisible('mail', true)
        ..setVisible('music', true)
        ..setVisible('mail', false);

      expect(order.order, ['music']);

      order.setVisible('mail', true);
      expect(order.order, ['music', 'mail']);
    });

    test('no-op transitions report no change', () {
      final order = WindowZOrder();
      expect(order.setVisible('mail', false), isFalse);
      expect(order.setVisible('mail', true), isTrue);
      expect(order.setVisible('mail', true), isFalse);
      expect(order.order, ['mail']);
    });

    test('clear empties the order', () {
      final order = WindowZOrder()
        ..setVisible('mail', true)
        ..clear();
      expect(order.order, isEmpty);
    });

    test('moveToFront brings a behind window forward', () {
      final order = WindowZOrder()
        ..setVisible('mail', true)
        ..setVisible('music', true);

      expect(order.moveToFront('mail'), isTrue);
      expect(order.order, ['music', 'mail']);
    });

    test('moveToFront is a no-op when untracked or already front', () {
      final order = WindowZOrder()..setVisible('mail', true);

      expect(order.moveToFront('music'), isFalse);
      expect(order.moveToFront('mail'), isFalse);
      expect(order.order, ['mail']);
    });
  });
}
