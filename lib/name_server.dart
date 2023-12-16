import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

class ThreadPool {
  static const thread1 = "thread1";
  static const thread2 = "thread2";
  static Future<void> thead1Callback(SendPort mainThreadPort) async {
    ReceivePort thread1RecPort = ReceivePort(thread1);
    IsolateNameServer.registerPortWithName(
        thread1RecPort.sendPort, Isolate.current.debugName!);
    await for (final List data in thread1RecPort) {
      final fnc = data[0];
      final arg = data[1];
      if (fnc is Function) {
        final result = fnc.call(arg ?? Never);
        mainThreadPort.send(result);
      }
    }
  }

  static Future<void> thead2Callback(SendPort mainThreadPort) async {
    ReceivePort thread2RecPort = ReceivePort(thread2);
    IsolateNameServer.registerPortWithName(
        thread2RecPort.sendPort, Isolate.current.debugName!);
    await for (final List data in thread2RecPort) {
      final fnc = data[0];
      final arg = data[1];
      if (fnc is Function) {
        final result = fnc.call(arg ?? Never);
        mainThreadPort.send(result);
      }
    }
  }

  Future<void> initPool() async {
    ReceivePort mainThreadPort = ReceivePort();
    ReceivePort exitPort = ReceivePort();
    ReceivePort errorPort = ReceivePort();

    //exit listner
    exitPort.listen((exitMsg) {
      print("[EXIT MSG] $exitMsg");
    });

    //exit listner
    errorPort.listen((errorMsg) {
      print("[ERROR MSG] $errorMsg");
    });

    //main thread listner
    mainThreadPort.listen((msg) {
      print("[MAIN THREAD MSG] $msg");
    });

    //start threads
    await Isolate.spawn(thead1Callback, mainThreadPort.sendPort,
        debugName: thread1,
        onExit: exitPort.sendPort,
        onError: errorPort.sendPort);
    await Isolate.spawn(thead2Callback, mainThreadPort.sendPort,
        debugName: thread2,
        onExit: exitPort.sendPort,
        onError: errorPort.sendPort);
  }

  static void excTaskInThread1<R, P>(
      FutureOr<R> Function(P argument) function, P argument) {
    IsolateNameServer.lookupPortByName(thread1)!.send([function, argument]);
  }

  static void excTaskInThread2<R, P>(
      FutureOr<R> Function(P argument) function, P argument) {
    IsolateNameServer.lookupPortByName(thread2)!.send([function, argument]);
  }
}
