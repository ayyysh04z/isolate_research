/// Update the [IsolateController] to support input messages.
/// Now we should be able to send messages from the spawned isolate and
/// got a responses back to the main isolate.

import 'dart:async';
import 'dart:isolate';

/// A function that generates a stream of factorial numbers
/// from the given [number].
typedef FactGen = Iterable<String> Function(int);

void main() => Future<void>(() async {
      // Set payload as a generator of factorial numbers.
      // Mutate incoming messages to the factorial numbers and
      // send them back to the main isolate.
      final isolate = await IsolateController.spawn<FactGen, int, String>(
        //handler
        (payload, messages, send) async {
          // Pass the messages stream from the main isolate to the handler.
          await for (final msg in messages) {
            for (final result in payload(msg)) {
              send(result);
            }
          }
        },
        //payload
        (number) sync* {
          // Calculate factorial numbers and send back each step of the progress
          for (var i = 1, r = 1; i <= number; i++, r *= i) {
            yield '$i! = $r';
          }
        },
      )
        ..stream.listen((event) {
          print(event);
        })
        // Evaluate factorial numbers for 2, 3 and 7 by sending messages to the
        // spawned isolate.
        ..add(2)
        ..add(3)
        ..add(7);
      await Future<void>.delayed(const Duration(seconds: 1));
      isolate.close();
    });

/// Update the [IsolateController] to support input messages.
typedef IsolateHandler<Payload, In, Out> = FutureOr<void> Function(
  Payload payload, //function to execute
  Stream<In>
      messages, // Add a stream of incoming messages, In -> input type of payload
  void Function(Out out)
      send, //send to main isolate , Out ->output type of payload
);

//instead of passing list to isolate spawn args
class _IsolateArgument<Payload, In, Out> {
  final IsolateHandler<Payload, In, Out> handler;

  final Payload payload;

  final SendPort sendPort;

  _IsolateArgument({
    required this.handler,
    required this.payload,
    required this.sendPort,
  });

  /// Update the [call] method to support input messages from the main isolate.
  FutureOr<void> call(Stream<Object?> receiveStream) => handler(
        payload,
        // Filter out messages from the main isolate and cast them to the
        // expected type.
        receiveStream
            .where((e) => e is In)
            .cast<In>()
            .asBroadcastStream(), //filters data from isolate reciever port
        (Out data) => sendPort.send(data),
      );
}

/// Update the [IsolateController] to support input messages.
class IsolateController<In, Out> {
  IsolateController._({
    required this.stream,
    required this.add, // Add a method to send messages to the spawned isolate.
    required this.close,
  });

  static Future<void> _$entryPoint<Payload, In, Out>(
      _IsolateArgument<Payload, In, Out> argument) async {
    // Create a [ReceivePort] to receive messages from the main isolate.
    final sepIsoRecPort = ReceivePort();
    argument.sendPort.send(sepIsoRecPort.sendPort);
    try {
      // Pass the messages stream from the main isolate to the handler.
      await argument(sepIsoRecPort); //use .call(stream input)
    } finally {
      // Send a message to the main isolate about the exit.
      argument.sendPort.send(#exit);
    }
  }

  static Future<IsolateController<In, Out>> spawn<Payload, In, Out>(
    IsolateHandler<Payload, In, Out> handler,
    Payload payload,
  ) async {
    //main isolate
    final mainIsoRecPort = ReceivePort();
    final argument = _IsolateArgument<Payload, In, Out>(
      handler: handler,
      payload: payload,
      sendPort: mainIsoRecPort.sendPort,
    );

    //create handler isolate
    final isolate = await Isolate.spawn<_IsolateArgument<Payload, In, Out>>(
      _$entryPoint<Payload, In, Out>,
      argument,
      errorsAreFatal: true,
      debugName: 'MyIsolate',
    );

    final outputController = StreamController<Out>.broadcast();
    late final StreamSubscription<Object?> rcvSubscription;

    void close() {
      mainIsoRecPort.close();
      rcvSubscription.cancel().ignore();
      outputController.close().ignore();
      isolate.kill();
    }

    // Create a [Completer] to wait for the [SendPort] of the [ReceivePort]
    // belonging to the spawned isolate.
    final completer = Completer<SendPort>();
    rcvSubscription = mainIsoRecPort.listen(
      (message) {
        if (message is Out) {
          outputController.add(message);
        } else if (message is SendPort) {
          // Got the [SendPort] of the [ReceivePort] belonging to the spawned
          // isolate.
          completer.complete(message);
        } else if (message == #exit) {
          close();
        }
      },
      onError: outputController.addError,
      cancelOnError: false,
    );

    // Wait for the [SendPort] of the [ReceivePort] belonging to the spawned
    // isolate.
    final sendPort = await completer.future;

    return IsolateController<In, Out>._(
      // Pass data to the spawned isolate with the [add] method by passing
      // the data to the [SendPort] of the spawned isolate.
      add: sendPort.send,
      stream: outputController.stream,
      close: close,
    );
  }

  final Stream<Out> stream;

  /// Add a method to send messages to the spawned isolate.
  final void Function(In data) add;

  final void Function() close;
}
