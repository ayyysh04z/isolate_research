//parellel comp test
// ignore_for_file: avoid_print, body_might_complete_normally_catch_error

import 'dart:isolate';
import 'dart:math';

const int maxIsolates = 1;
final List<Isolate> isolates = [];
var finishedIsolates = 0;

void exp2(List<String> arguments) async {
  final rootReceivePort = ReceivePort();
  final exitReceivePort = ReceivePort();
  double ans = 0;
  int i = 0;
  var startTime = DateTime.now();
  rootReceivePort.listen((data) {
    ans += data;
    i++;
    if (i == 10) {
      print(ans);
      var runTime = DateTime.now().difference(startTime);
      print("done in $runTime");
    }
  });

  for (var i = 0; i < 10; i++) {
    isolates.add(await Isolate.spawn(
      _createIsoForTask2,
      rootReceivePort.sendPort,
      onExit: exitReceivePort.sendPort,
      errorsAreFatal: false,
      debugName: 'isolate ${i + 1}',
    ).catchError((error) {
      print('Isolate spawn error: $error');
    }));
  }
}

void exp3(List<String> arguments) async {
  final rootReceivePort = ReceivePort();
  final exitReceivePort = ReceivePort();
  var startTime = DateTime.now();
  rootReceivePort.listen((data) {
    print(data);
    var runTime = DateTime.now().difference(startTime);
    print("done in $runTime");
  });

  await Isolate.spawn(
    _createIsoForTask1,
    rootReceivePort.sendPort,
    onExit: exitReceivePort.sendPort,
    errorsAreFatal: false,
    debugName: 'isolate 1',
  ).catchError((error) {
    print('Isolate spawn error: $error');
  });
}

void exp4(List<String> arguments) async {
  final rootReceivePort = ReceivePort();
  final exitReceivePort = ReceivePort();
  var startTime = DateTime.now();
  rootReceivePort.listen((data) {
    print(data);
    var runTime = DateTime.now().difference(startTime);
    print("done in $runTime");
  });

  await Isolate.spawn(
    _createIsoForTask3,
    rootReceivePort.sendPort,
    onExit: exitReceivePort.sendPort,
    errorsAreFatal: false,
    debugName: 'isolate 1',
  ).catchError((error) {
    print('Isolate spawn error: $error');
  });
}

void _createIsoForTask1(SendPort sendPort) {
  var startTime = DateTime.now();
  print('Starting ${Isolate.current.debugName}...');
  double res = 0;
  for (var i = 0; i < 6000000000; i++) {
    res += tan(
        atan(tan(atan(tan(atan(tan(atan(tan(atan(123456789.123456789))))))))));
  }
  var runTime = DateTime.now().difference(startTime);
  print('${Isolate.current.debugName} run time: ${runTime.toString()}');
  sendPort.send(res);
}

//divide by 10
void _createIsoForTask2(SendPort sendPort) {
  var startTime = DateTime.now();
  print('Starting ${Isolate.current.debugName}...');
  double res = 0;
  for (var i = 0; i < 600000000; i++) {
    res += tan(
        atan(tan(atan(tan(atan(tan(atan(tan(atan(123456789.123456789))))))))));
  }
  var runTime = DateTime.now().difference(startTime);
  print('${Isolate.current.debugName} run time: ${runTime.toString()}');
  sendPort.send(res);
}

//divide by 100
void _createIsoForTask3(SendPort sendPort) {
  var startTime = DateTime.now();
  print('Starting ${Isolate.current.debugName}...');
  double res = 0;
  for (var i = 0; i < 60000000; i++) {
    res += tan(
        atan(tan(atan(tan(atan(tan(atan(tan(atan(123456789.123456789))))))))));
  }
  var runTime = DateTime.now().difference(startTime);
  print('${Isolate.current.debugName} run time: ${runTime.toString()}');
  sendPort.send(res);
}
