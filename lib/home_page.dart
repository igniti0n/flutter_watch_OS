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
  final _textEditingController = TextEditingController();
  String _batteryLevel = "n/a";
  int _counter = 0;
  int _nativeClock = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initFlutterChannel();
    eventChannel
        .receiveBroadcastStream()
        .listen(_onDataRecieved, onError: _onError);
  }

  // Receiving data from native trough method invocation
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

  //  Stream data from EvenetChannel
  void _onDataRecieved(dynamic data) {
    if (data is int) {
      setState(() {
        _nativeClock = data;
      });
    }
    //log("Data received from stream: " + data.toString());
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
    // Send data to Native, with additional data
    try {
      await platformChannel.invokeMethod("incrementWatchCounter", _counter);
    } on PlatformException catch (error) {
      log("Error occurred while sending data to increment watch counter. \n" +
          error.toString());
    }
  }

  // Sending table data to watch
  void _sendTableData() async {
    try {
      final String currentText = _textEditingController.value.text;
      final tableData = currentText.split(" ");
      log("Table data is $tableData");
      final _response =
          await platformChannel.invokeMethod("presentTableData", tableData);
    } on PlatformException catch (error) {
      log("Error occurred while sending  table data. \n" + error.toString());
    }
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
              TextField(
                controller: _textEditingController,
              ),
              ElevatedButton(
                onPressed: _sendTableData,
                child: Text("Send table data"),
              ),
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Counter: \n $_counter",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    decorationStyle: TextDecorationStyle.wavy,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Native clock \n $_nativeClock",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    decorationStyle: TextDecorationStyle.wavy,
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading) CircularProgressIndicator()
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Counter +1',
        child: Icon(Icons.add),
      ),
    );
  }
}
