import UIKit
import Flutter
import WatchConnectivity

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var counter: Int = 0
    var flutterEventSink: FlutterEventSink?
    var timer: Timer?
    var methodChannel: FlutterMethodChannel?
    let wcSession = WCSession.default
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            // Initializing FlutterViewController, he is needed for the binary messenger
            let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
            methodChannel = FlutterMethodChannel(name: "samples.flutter.dev/battery",
                                                      binaryMessenger: controller.binaryMessenger)
            // Event channel - stream on Flutter side
            let eventChannel = FlutterEventChannel(name: "samples.flutter.dev/counter", binaryMessenger: controller.binaryMessenger)
            eventChannel.setStreamHandler(self)
            
            // Activating session for watch
            if( WCSession.isSupported()) {
                wcSession.delegate = self
                wcSession.activate()
            } else {
                print("Watch not supported")
            }
            
            // Incomming method invocations from Flutter side
            methodChannel?.setMethodCallHandler({ [weak self]
                (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
                
                // Check conditions for ANY messaging
                guard
                    let watchSession = self?.wcSession,
                    watchSession.activationState == .activated,
                    watchSession.isPaired == true,
                    watchSession.isWatchAppInstalled == true
                else {
                    print("Conditions for messaging are not met.")
                    result(false)
                    return
                }
                
                switch call.method {
                case "presentTableData":
                    // Get data from arguments of a call from Flutter
                    guard let tableData = call.arguments as? Array<String> else { return }
                    let watchData: [String: Any] = ["method": "presentTableData", "data": tableData]
                    print("Sedinging table data: \n", tableData)
                    // If reachable, go with live messaging, if  not reachable update application context
                    if watchSession.isReachable == true {
                        //print("Watch app is reachable! Going  live... ")
                        watchSession.sendMessage(watchData, replyHandler: nil, errorHandler: nil)
                    } else {
                        //print("Watch app is not reachable, updating context... ")
                        do {
                            try watchSession.updateApplicationContext(watchData)
                        } catch(_) {
                            //print("Error occurred while updating application context: ", error)
                        }
                    }
                    result(true)
                    
                case "incrementWatchCounter":
                    guard let methodData = call.arguments as? Int else {
                            result("false")
                            return
                        }
                    
                    let watchData: [String: Any] = ["method": "incrementWatchCounter", "data": methodData]
                    print("Sedinging incrementWatchCounter: \n", watchData)
                    watchSession.sendMessage(watchData, replyHandler: nil, errorHandler: nil)
                    result(true)
                    
                case "getBatteryLevel":
                    self?.receiveBatteryLevel(result: result)
                    
                default:
                    result(FlutterMethodNotImplemented)
                }
                
            })
            
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

// MARK: - WCSessionDelegate methods -

extension AppDelegate: WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Session became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Session deactivatd")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Invoking method for to Flutter side, MUST BE ON MAIN THREAD!
        DispatchQueue.main.async { [weak self] in
            if
            let method = message["method"] as? String,
            let controller = self?.window?.rootViewController as? FlutterViewController {
                self?.methodChannel?.invokeMethod(method, arguments: message)
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
            print("@session did complete with: acctivation state: ", activationState.rawValue)
    }
}

// MARK: - Flutter stream handler -
extension AppDelegate: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.flutterEventSink = events
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onTimerUp), userInfo: nil, repeats: true)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        timer?.invalidate()
        flutterEventSink = nil
        return nil
    }
    
    @objc func onTimerUp() {
        counter += 1
        flutterEventSink?(counter)
    }
}
