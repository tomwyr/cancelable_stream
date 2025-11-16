/// Support for streams that can be canceled explicitly.
///
/// This library provides [CancelableStream], a [Stream] wrapper that allows
/// unsubscribing from an upstream source and completing downstream listeners
/// on demand. It can be used to:
///
/// - Stop event delivery from long-lived or infinite streams.
/// - Pre-emptively cancel a stream before all events are emitted.
/// - Automatically terminate an active `await for` loop when canceled.
///
/// Example usage:
/// ```dart
/// final stream = Stream.periodic(Duration(seconds: 1), (i) => i);
/// final cancelable = stream.cancelable();
///
/// Future.delayed(Duration(seconds: 5), () => cancelable.cancel());
///
/// await for (var value in cancelable) {
///   print(value);
/// }
/// ```
///
/// Prints:
/// ```
/// 0
/// 1
/// 2
/// 3
/// 4
/// ```
///
/// After `cancel()`, the upstream stream is unsubscribed and the `await for` loop terminates.
library;

export 'src/cancelable_stream.dart';
