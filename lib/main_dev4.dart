import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:isolate_pool_2/isolate_pool_2.dart';

void exp3(List<String> arguments) async {
  // Start and await for the pool to complete launching
  var pool = IsolatePool(4);
  await pool.start();

  // SAMPLE 1, Poold Job
  await multiplierJobs(pool);

  // SAMPLE 2, Pooled Instance
  // await randomViaPooledInstances(pool);

  // Stop isolate and let the process finish
  pool.stop();
}

////////////////////////////
// SAMPLE 1, PooledJob<T> //
////////////////////////////

Future<void> multiplierJobs(IsolatePool pool) async {
  print('\n\nEXAMPLE1\n');
  var futures = <Future<double>>[];
  // Schedule mutliple jobs on the isolate pool and store all futures returned
  for (var i = 0; i < 15; i++) {
    futures.add(pool.scheduleJob<double>(DoubleNumbersJob(101 + i)));
  }

  // Wait for all futures to complete and collect the results
  // var sum = (await Future.wait<int>(futures)).fold<int>(0, (p, c) => p + c);
  var sum = (await Future.wait<double>(futures)).forEach((element) {
    print('Multiplication result: $element');
  });
}

// `DoubleNumbersJob` class inherits `PooledJob` and implements an operation to be executed in the pool.
// In this case we do multiplication in `job()` method that is overriden.
// `T` in `PooledJob<T>` defines the result type returned by `job()`, it is `int` here
class DoubleNumbersJob extends PooledJob<double> {
  final int number;

  DoubleNumbersJob(this.number);

  @override
  Future<double> job() async {
    var startTime = DateTime.now();
    print('Starting ${Isolate.current.debugName}...');
    double res = 0;
    for (int i = 0; i < 100000000000; i++) {
      res += tan(atan(
          tan(atan(tan(atan(tan(atan(tan(atan(123456789.123456789))))))))));
    }
    var runTime = DateTime.now().difference(startTime);
    print('${Isolate.current.debugName} run time: ${runTime.toString()}');
    return res;
  }
}

//////////////////////////////
// SAMPLE 2, PooledInstance //
//////////////////////////////

Future<void> randomViaPooledInstances(IsolatePool pool) async {
  print('\n\nEXAMPLE2\n');
  var proxies = List<PooledInstanceProxy>.empty(growable: true);

  // Create pooled instances in isolates inside pool,
  // collect proxy objects to comminucate with them from within main isolate
  for (var i = 0; i < 4; i++) {
    proxies.add(await pool.addInstance(RandomBytesGenerator()));
  }

  // Call remote methods via proxies
  var futures = List<Future<RandomBytes>>.generate(proxies.length,
      (i) => proxies[i].callRemoteMethod(GetNBytesAction(1024 * 1024)));

  // Await for remote method results
  var results = await Future.wait(futures);
  for (var r in results) {
    print('Min: ${r.min}, Max: ${r.max}, Avg: ${r.avg.toStringAsFixed(1)},');
  }

  // Repeating stats computation by trnasferig to isolaes bytes
  print('Recalculating stats');
  var i = 0;
  futures = results
      .map((r) =>
          proxies[i++].callRemoteMethod<RandomBytes>(ComputeStats(r.bytes)))
      .toList();

  results = await Future.wait(futures);
  for (var r in results) {
    print('Min: ${r.min}, Max: ${r.max}, Avg: ${r.avg.toStringAsFixed(1)},');
  }
}

class Tuple {
  final int min;
  final int max;
  final double avg;

  Tuple(this.min, this.max, this.avg);
}

// Pooled instance implementation that will run all operations outside main isolate.
// Generating random numbers (which can be slow) and computing basic stats.
class RandomBytesGenerator extends PooledInstance {
  late Random _rand;

  @override
  Future init() async {
    _rand = Random();
  }

  // Internal imnplementation, generating random bytes
  RandomBytes getBytes(int n) {
    var items = [Uint8List(n)];
    for (var i = 0; i < n; i++) {
      items[0][i] = _rand.nextInt(256);
    }

    Tuple stat = getStats(items[0]);

    var t = TransferableTypedData.fromList(items);
    return RandomBytes(t, stat.min, stat.max, stat.avg);
  }

  // And calculating stats
  Tuple getStats(Uint8List items) {
    var min = 255;
    var max = 0;
    var avg = 0.0;

    for (var i = 0; i < items.length; i++) {
      if (items[i] < min) {
        min = items[i];
      }
      if (items[i] > max) {
        max = items[i];
      }
      avg += items[i];
    }

    avg /= items.length;

    return Tuple(min, max, avg);
  }

  // This method is called by isolate pool whenever there's
  // a call to `callRemoteMethod()` on a proxy object in main isolate
  // `Action` object is used to determine the operation requested (type of the object)
  // and transfer a payload - the Action obhject is passed in from the main isolate as-is
  @override
  Future<dynamic> receiveRemoteCall(Action action) async {
    if (action is GetNBytesAction) {
      return getBytes(action.numberOfBytes);
    } else if (action is ComputeStats) {
      Tuple stat = getStats(action.bytes.materialize().asUint8List());

      return RandomBytes(
          TransferableTypedData.fromList([]), stat.min, stat.max, stat.avg);
    } else {
      throw 'Unknown action ${action.runtimeType}';
    }
  }
}

// Action that requests N random bytes
class GetNBytesAction extends Action {
  final int numberOfBytes;
  GetNBytesAction(this.numberOfBytes);
}

// An action that sends a list of bytes and receives statistics for that numbers
class ComputeStats extends Action {
  // Using TransferableTypedData, a more verbose alternative to Uint8List (yet possibly faster)
  final TransferableTypedData bytes;
  ComputeStats(this.bytes);
}

// Payload that is used as return value for GetNBytes and
class RandomBytes {
  final TransferableTypedData bytes;
  final int min;
  final int max;
  final double avg;

  RandomBytes(this.bytes, this.min, this.max, this.avg);
}
