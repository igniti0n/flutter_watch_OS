import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var timer = Timer()
    var counter: Int = 0
    var flutterEventSink: FlutterEventSink?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            
            // Initializing FlutterViewController, he is needed for the binary messenger
            let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
            let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/battery",
                                                      binaryMessenger: controller.binaryMessenger)
            
            batteryChannel.setMethodCallHandler({ [weak self]
                (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                guard call.method == "getBatteryLevel" else {
                    result(FlutterMethodNotImplemented)
                    return
                }
                self?.receiveBatteryLevel(result: result)
            })
            
            let eventChannel = FlutterEventChannel(name: "samples.flutter.dev/counter", binaryMessenger: controller.binaryMessenger)
            
            eventChannel.setStreamHandler(self)
            
            GeneratedPluginRegistrant.register(with: self)

            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
    
    private func receiveBatteryLevel(result: FlutterResult) {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        if device.batteryState == UIDevice.BatteryState.unknown {
            result(FlutterError(code: "UNAVAILABLE",
                                message: "Battery info unavailable",
                                details: nil))
        } else {
            result(Int(device.batteryLevel * 100))
        }
    }
    
}

extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.flutterEventSink = events
        print("ON LISSTEN IN PLATFORM SIDE")
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(incrementCounterOnStream), userInfo: nil, repeats: true)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        timer.invalidate()
        flutterEventSink = nil
        return nil
    }
    
    @objc func incrementCounterOnStream() {
        guard let flutterEventSink = flutterEventSink else {
            return
        }
        counter += 1
        flutterEventSink(counter)
    }
}
