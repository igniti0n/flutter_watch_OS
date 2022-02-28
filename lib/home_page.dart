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
    eventChannel
        .receiveBroadcastStream()
        .listen(_onDataRecieved, onError: _onError);
  }

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
    );
  }
}
