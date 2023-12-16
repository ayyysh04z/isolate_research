import 'dart:isolate';

import 'package:flutter/material.dart';

import 'loadbalancer_api.dart';
import 'name_server.dart';

Future<void> main(List<String> args) async {
  // await LoadbalancerApi.init();
  await ThreadPool().initPool();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

int task1() {
  print("running in ${Isolate.current.debugName}");
  int sum = 0;
  for (int i = 0; i < 2000000000; i++) {
    sum += i;
  }
  return sum;
}

int task2(int x) {
  print("running in ${Isolate.current.debugName}");
  if (x <= 0) return 0;
  if (x == 1) return 1;

  int first = 0;
  int second = 1;
  int result = 0;

  for (int i = 2; i <= x; i++) {
    result = first + second;
    first = second;
    second = result;
  }
  return result;
}

void task3() {
  print("running in ${Isolate.current.debugName}");
  int sum = 0;
  for (int i = 0; i < 2000000000; i++) {
    sum += i;
  }
  print("task 3 done");
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Testing app")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Testing app',
            ),
            TextButton(
              child: const Text("Btn1"),
              onPressed: () async {
                // await ConcurrencyTest.start();
                // LoadbalancerApi.concurencyTest();
                ThreadPool.excTaskInThread1<int, void>(
                    (void _) => task1(), null);
              },
            ),
            TextButton(
              child: const Text("Btn2"),
              onPressed: () async {
                // await ConcurrencyTest.start();
                // LoadbalancerApi.concurencyTest();
                ThreadPool.excTaskInThread2<int, int>(task2, 2000000000);
              },
            ),
            TextButton(
              child: const Text("Btn3"),
              onPressed: () async {
                // await ConcurrencyTest.start();
                // LoadbalancerApi.concurencyTest();
                ThreadPool.excTaskInThread1<void, void>(
                    (void _) => task3(), null);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This is a SnackBar!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
