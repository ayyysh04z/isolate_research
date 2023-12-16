import 'dart:isolate';

import 'package:flutter/material.dart';

import 'concurency.dart';
import 'loadbalancer_api.dart';

Future<void> main(List<String> args) async {
  await LoadbalancerApi.init();
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

int task1(int arg) {
  print("running in ${Isolate.current.debugName}");
  int sum = 0;
  for (int i = 0; i < 1000000000; i++) {
    sum += i;
  }
  return sum;
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
                LoadbalancerApi.concurencyTest();
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
