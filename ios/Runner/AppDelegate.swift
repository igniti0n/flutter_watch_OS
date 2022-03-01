import UIKit
import Flutter
import  WatchConnectivity

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var counter: Int = 0
    var flutterEventSink: FlutterEventSink?
    let wcSession = WCSession.default
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            
            activateSession()
            // Initializing FlutterViewController, he is needed for the binary messenger
            let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
            let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/battery",
                                                      binaryMessenger: controller.binaryMessenger)
            
            batteryChannel.setMethodCallHandler({ [weak self]
                (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                
                switch call.method {
                case "flutterToWatch":
                    guard let watchSession = self?.wcSession, watchSession.isPaired,
                          watchSession.isReachable, let methodData = call.arguments as? [String: Any],
                          let method = methodData["method"], let data = methodData["data"] as? Any else {
                              result(false)
                              return
                          }
                    
                    let watchData: [String: Any] = ["method": method, "data": data]
                    watchSession.sendMessage(watchData, replyHandler: nil, errorHandler: nil)
                    result(true)
                case "getBatteryLevel":
                    self?.receiveBatteryLevel(result: result)
                    
                default:
                    result(FlutterMethodNotImplemented)
                }
                
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
    
    func activateSession() {
        print("Activating session")
        wcSession.delegate = self
        wcSession.activate()
    }
    
    
}

extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.flutterEventSink = events
        print("ON LISSTEN IN PLATFORM SIDE")
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        flutterEventSink = nil
        return nil
    }
}

extension AppDelegate: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message: ", message)
        print("Received context:", wcSession.receivedApplicationContext)
        DispatchQueue.main.async {
            if let method = message["method"] as? String, let controller = self.window?.rootViewController as? FlutterViewController {
                let channel = FlutterMethodChannel(
                    name: "samples.flutter.dev/battery",
                    binaryMessenger: controller.binaryMessenger)
                channel.invokeMethod(method, arguments: message)
            }
        }
        
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("@session did complete with: acctivation state: ", activationState.rawValue)
        print("Activated state...")
        print("Is reachable: ", wcSession.isReachable)
    }
}
