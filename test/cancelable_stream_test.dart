import 'dart:async';

import 'package:cancelable_stream/cancelable_stream.dart';
import 'package:test/test.dart';

void main() {
  test('forwards events downstream', () {
    final source = StreamController<int>();
    final stream = source.stream.cancelable();

    source.add(1);
    source.add(2);
    source.add(3);

    expect(stream, emitsInOrder([1, 2, 3]));
  });

  test('unsubscribes source stream when downstream subscription is canceled', () async {
    final source = StreamController<int>();
    final stream = source.stream.cancelable();

    final subscription = stream.listen((_) {});
    expect(source.hasListener, isTrue);

    await subscription.cancel();
    expect(source.hasListener, isFalse);
  });

  test('subscribes source stream when downstream listener is registered', () {
    final source = StreamController<int>();
    final stream = source.stream.cancelable();

    expect(source.hasListener, isFalse);

    final _ = stream.listen((_) {});
    expect(source.hasListener, isTrue);
  });

  test('throws when single-subscription stream is listened more than once', () {
    final source = StreamController<int>();
    final stream = source.stream.cancelable();

    subscribeTwice() {
      stream.listen((_) {});
      stream.listen((_) {});
    }

    expect(subscribeTwice, throwsA(isA<StateError>()));
  });

  test('does not throw when broadcast stream is listened more than once', () {
    final source = StreamController<int>();
    final stream = source.stream.asBroadcastStream().cancelable();

    subscribeTwice() {
      stream.listen((_) {});
      stream.listen((_) {});
    }

    expect(subscribeTwice, returnsNormally);
  });
}
