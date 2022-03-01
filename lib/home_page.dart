import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const platformChannel = MethodChannel('samples.flutter.dev/battery');
  static const eventChannel = EventChannel('samples.flutter.dev/counter');
  String _batteryLevel = "n/a";
  int _counter = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initFlutterChannel();
    eventChannel
        .receiveBroadcastStream()
        .listen(_onDataRecieved, onError: _onError);
  }

  //  Stream data from EvenetChannel
  void _onDataRecieved(dynamic data) {
    if (data is int) {
      setState(() {
        _counter = data;
      });
    }
    log("Data received from stream: " + data.toString());
  }

  void _onError(Object error) {
    log("Error on received brodcast stream: " + error.toString());
  }

  // Invoking batterly level method on native
  Future<void> getBatteryLevel() async {
    late String batteryLevel;
    try {
      final int level = await platformChannel.invokeMethod('getBatteryLevel');
      batteryLevel = "Battery $level";
    } on PlatformException catch (error) {
      batteryLevel = "Filed too get level: ${error.message}";
    }
    setState(() {
      _batteryLevel = batteryLevel;
      _isLoading = false;
    });
  }

// Invoking increment counte ron native
  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
    });

    // Send data to Native
    await platformChannel.invokeMethod(
        "flutterToWatch", {"method": "sendCounterToNative", "data": _counter});
  }

// Receiving data from  native
  Future<void> _initFlutterChannel() async {
    platformChannel.setMethodCallHandler((call) async {
      print("Recieved native data! " + call.toString());
      // Receive data from Native
      switch (call.method) {
        case "sendCounterToFlutter":
          _counter = call.arguments["data"]["counter"];
          _incrementCounter();
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_batteryLevel),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                  });
                  getBatteryLevel();
                },
                child: Text('Get battery data'),
              ),
              Text(
                "Counter: $_counter",
                style: TextStyle(
                  fontSize: 28,
                  decorationStyle: TextDecorationStyle.wavy,
                ),
              ),
            ],
          ),
          if (_isLoading) CircularProgressIndicator()
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
