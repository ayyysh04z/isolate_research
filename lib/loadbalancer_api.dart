// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:isolate/isolate.dart';

class Person {
  final String name;

  Person(this.name);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      map['name'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Person.fromJson(String source) => Person.fromMap(json.decode(source));

  @override
  String toString() => 'Person(name: $name)';
}

class UserService {
  LoadBalancer? balancer;

  Future<Person> fetchUser() async {
    String userData = '''
{
"name":"ayush yadav"
}
''';
    await Future.delayed(const Duration(seconds: 5));
    balancer ??= await LoadBalancer.create(5, IsolateRunner.spawn);
    Person ans = await balancer!.run(deserializeJson, userData, load: 1);
    print(ans.toString());
    return ans;
  }

  Person deserializeJson(String data) {
    print(Isolate.current.debugName);
    Map<String, dynamic> dataMap = jsonDecode(data);
    return Person(dataMap["name"]);
  }
}

Future<void> main_bl(List<String> args) async {
  UserService userService = UserService();
  // userService.balancer = await LoadBalancer.create(5, IsolateRunner.spawn);
  List<Future> calls = [];
  for (int i = 0; i < 100; i++) {
    calls.add(userService.fetchUser());
  }
  await Future.wait(calls);
}

class LoadbalancerApi {
  static LoadBalancer? balancer;

  static Future<void> init() async {
    balancer ??= await LoadBalancer.create(5, IsolateRunner.spawn);
  }

  static void excInPool<R, P>(
      FutureOr<R> Function(P argument) function, P argument) async {
    final ans = await balancer!.run(function, argument, load: 1);
    print(ans.toString());
  }

  static Future<void> concurencyTest() async {
    var startTime = DateTime.now();
    List<Future> alIsolatesRun = [];
    for (var i = 0; i < 8; i++) {
      alIsolatesRun.add(balancer!.run(_createIsolate, null, load: 1));
    }
    await Future.wait(alIsolatesRun);
    var runTime = DateTime.now().difference(startTime);
    print('run time: ${runTime.toString()}');
  }

  static void _createIsolate(_void) {
    var startTime = DateTime.now();
    print('[${Isolate.current.debugName}] Executing task');
    for (var i = 0; i < 10000000000; i++) {
      tan(atan(
          tan(atan(tan(atan(tan(atan(tan(atan(123456789.123456789))))))))));
    }
    var endTime = DateTime.now();
    var runTime = endTime.difference(startTime);
    print(
        '[${Isolate.current.debugName}]\n run time: ${runTime.toString()} \n start time : ${startTime.toString()} \n end time :${endTime.toString()}');
  }
}

/*logs:
5
I/flutter (  814): [IsolateRunnerRemote._create] Executing task
I/flutter (  814): [IsolateRunnerRemote._create]
I/flutter (  814):  run time: 0:00:15.254229
I/flutter (  814):  start time : 2023-12-16 20:43:19.571567
I/flutter (  814):  end time :2023-12-16 20:43:34.825796
I/flutter (  814): [IsolateRunnerRemote._create] Executing task
I/flutter (  814): [IsolateRunnerRemote._create]
I/flutter (  814):  run time: 0:00:16.391748
I/flutter (  814):  start time : 2023-12-16 20:43:19.571320
I/flutter (  814):  end time :2023-12-16 20:43:35.963068
I/flutter (  814): [IsolateRunnerRemote._create]
I/flutter (  814):  run time: 0:00:26.059895
I/flutter (  814):  start time : 2023-12-16 20:43:19.562978
I/flutter (  814):  end time :2023-12-16 20:43:45.622873
I/flutter (  814): [IsolateRunnerRemote._create] Executing task
I/flutter (  814): [IsolateRunnerRemote._create]
I/flutter (  814):  run time: 0:00:14.972355
I/flutter (  814):  start time : 2023-12-16 20:43:34.826405
I/flutter (  814):  end time :2023-12-16 20:43:49.798760
I/flutter (  814): [IsolateRunnerRemote._create]
I/flutter (  814):  run time: 0:00:34.900256
I/flutter (  814):  start time : 2023-12-16 20:43:19.562874
I/flutter (  814):  end time :2023-12-16 20:43:54.463130
I/flutter (  814): [IsolateRunnerRemote._create] Executing task
I/flutter (  814): [IsolateRunnerRemote._create]
I/flutter (  814):  run time: 0:00:40.691598
I/flutter (  814):  start time : 2023-12-16 20:43:19.562845
I/flutter (  814):  end time :2023-12-16 20:44:00.254443
I/flutter (  814): [IsolateRunnerRemote._create]
I/flutter (  814):  run time: 0:00:15.333698
I/flutter (  814):  start time : 2023-12-16 20:43:45.623147
I/flutter (  814):  end time :2023-12-16 20:44:00.956845
I/flutter (  814): [IsolateRunnerRemote._create]
I/flutter (  814):  run time: 0:00:17.080439
I/flutter (  814):  start time : 2023-12-16 20:43:54.463429
I/flutter (  814):  end time :2023-12-16 20:44:11.543868
I/flutter (  814): run time: 0:00:51.984164
*/