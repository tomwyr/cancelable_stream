import 'package:cancelable_stream/cancelable_stream.dart';

void main() async {
  // A stream that emits numbers at one-second intervals
  createStream() async* {
    for (var value in [1, 2, 3, 4, 5]) {
      await Future.delayed(Duration(seconds: 1));
      print('Emit $value');
      yield value;
    }
    print('Producer done');
  }

  // Wrap the stream so it can be canceled
  final stream = createStream().cancelable();

  // Cancel the stream after 2.5 seconds
  Future.delayed(Duration(milliseconds: 2500), stream.cancel);

  // Listen to the events
  await for (var value in stream) {
    print('Consume $value');
  }
  print('Subscriber done');

  // Prints:
  // Emit 1
  // Consume 1
  // Emit 2
  // Consume 2
  // Emit 3   // Print occurs before yield; the value is never delivered
  // Subscriber done
}
