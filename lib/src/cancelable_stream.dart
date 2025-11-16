import 'dart:async';

/// A [Stream] wrapper that allows explicit cancellation of the connection
/// to the underlying source stream.
///
/// A [CancelableStream] forwards events from an upstream stream until
/// [cancel] is invoked. Canceling unsubscribes from the source stream and
/// delivers a done event to downstream listeners.
///
/// This enables a listener to terminate a stream early, including
/// completing an active `await for` loop. The stream may also be canceled
/// pre-emptively before any events have been received.
abstract interface class CancelableStream<T> implements Stream<T> {
  factory CancelableStream.from(Stream<T> stream) = _CancelableStream.from;

  /// Unsubscribes from the upstream stream and completes downstream listeners.
  ///
  /// After a stream is canceled, no further events are delivered.
  Future<void> cancel();
}

/// Extension adding cancelation support to the stream.
extension CancelableStreamExtension<T> on Stream<T> {
  /// Returns a [CancelableStream] that forwards events from this stream
  /// and can be explicitly canceled.
  CancelableStream<T> cancelable() => CancelableStream.from(this);
}

class _CancelableStream<T> extends StreamView<T> implements CancelableStream<T> {
  factory _CancelableStream.from(Stream<T> stream) {
    final buffer = <T>[];
    late StreamSubscription<T>? subscription;

    final controller = stream.isBroadcast ? StreamController<T>.broadcast() : StreamController<T>();

    controller.onListen = () {
      // Start upstream only when first listener appears
      subscription = stream.listen(
        (event) {
          buffer.add(event);
          if (!controller.isClosed) controller.add(event);
        },
        onError: (e, st) {
          if (!controller.isClosed) controller.addError(e, st);
        },
        onDone: () {
          if (!controller.isClosed) controller.close();
        },
      );

      // Replay past events to this new listener
      for (final event in buffer) {
        if (!controller.isClosed) controller.add(event);
      }
    };

    controller.onCancel = () => subscription?.cancel();

    return _CancelableStream(
      controller.stream,
      onCancel: () async {
        if (!controller.isClosed) {
          await subscription?.cancel();
          await controller.close();
        }
      },
    );
  }

  _CancelableStream(super.stream, {required this.onCancel});

  final Future<void> Function() onCancel;

  Future<void>? _cancelFuture;
  var _cancelComplete = false;

  @override
  Future<void> cancel() async {
    if (_cancelComplete) return;

    if (_cancelFuture case var future?) {
      await future;
    }

    _cancelFuture = onCancel();
    await _cancelFuture;
    _cancelFuture = null;
    _cancelComplete = true;
  }
}
