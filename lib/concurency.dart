//thread test
// ignore_for_file: avoid_print

import 'dart:isolate';
import 'dart:math';

class ConcurrencyTest {
  static const int maxIsolates = 8;
  static final List<Future> isolates = [];
  static var finishedIsolates = 0;

  static Future<void> start() async {
    final rootReceivePort = ReceivePort();
    final exitReceivePort = ReceivePort();
    var startTime = DateTime.now();
    exitReceivePort.listen((_) => _isolateDone(startTime));

    for (var i = 0; i < maxIsolates; i++) {
      isolates.add(Isolate.spawn(
        _createIsolate,
        rootReceivePort.sendPort,
        onExit: exitReceivePort.sendPort,
        errorsAreFatal: false,
        debugName: 'isolate ${i + 1}',
      ).catchError((error) {
        print('Isolate spawn error: $error');
      }));
    }

    await Future.wait(isolates);
    print("spawn done");
  }

  static void _createIsolate(SendPort sendPort) {
    var startTime = DateTime.now();
    for (var i = 0; i < 10000000000; i++) {
      // print('[${Isolate.current.debugName}] Executing task');
      tan(atan(
          tan(atan(tan(atan(tan(atan(tan(atan(123456789.123456789))))))))));
    }
    var endTime = DateTime.now();
    var runTime = endTime.difference(startTime);
    print(
        '[${Isolate.current.debugName}]\n run time: ${runTime.toString()} \n start time : ${startTime.toString()} \n end time :${endTime.toString()}');
  }

  static void _isolateDone(DateTime startTime) {
    if (++finishedIsolates >= maxIsolates) {
      var runTime = DateTime.now().difference(startTime);
      print('[${Isolate.current.debugName}]\n run time: ${runTime.toString()}');
      print("ALL TASK DONE");
      // exit(0);
    }
  }
}

/*
I/flutter ( 4531): [isolate 7]
I/flutter ( 4531):  run time: 0:00:27.518998
I/flutter ( 4531):  start time : 2023-12-16 20:57:58.256456
I/flutter ( 4531):  end time :2023-12-16 20:58:25.775454
I/flutter ( 4531): [isolate 1]
I/flutter ( 4531):  run time: 0:00:30.324274
I/flutter ( 4531):  start time : 2023-12-16 20:57:58.260123
I/flutter ( 4531):  end time :2023-12-16 20:58:28.584397
I/flutter ( 4531): spawn done
I/flutter ( 4531): [isolate 8]
I/flutter ( 4531):  run time: 0:00:31.767828
I/flutter ( 4531):  start time : 2023-12-16 20:57:58.256491
I/flutter ( 4531):  end time :2023-12-16 20:58:30.024319
I/flutter ( 4531): [isolate 2]
I/flutter ( 4531):  run time: 0:00:31.790391
I/flutter ( 4531):  start time : 2023-12-16 20:57:58.257806
I/flutter ( 4531):  end time :2023-12-16 20:58:30.048197
I/flutter ( 4531): [isolate 6]
I/flutter ( 4531):  run time: 0:00:34.240230
I/flutter ( 4531):  start time : 2023-12-16 20:57:58.262661
I/flutter ( 4531):  end time :2023-12-16 20:58:32.502891
I/flutter ( 4531): [isolate 5]
I/flutter ( 4531):  run time: 0:00:37.363188
I/flutter ( 4531):  start time : 2023-12-16 20:57:58.257080
I/flutter ( 4531):  end time :2023-12-16 20:58:35.620268
I/flutter ( 4531): [isolate 4]
I/flutter ( 4531):  run time: 0:00:38.573936
I/flutter ( 4531):  start time : 2023-12-16 20:57:58.257680
I/flutter ( 4531):  end time :2023-12-16 20:58:36.831616
I/flutter ( 4531): [isolate 3]
I/flutter ( 4531):  run time: 0:00:38.939488
I/flutter ( 4531):  start time : 2023-12-16 20:57:58.256991
I/flutter ( 4531):  end time :2023-12-16 20:58:37.196479
I/flutter ( 4531): [main]
I/flutter ( 4531):  run time: 0:00:39.399211
I/flutter ( 4531): ALL TASK DONE
*/