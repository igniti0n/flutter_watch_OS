//
//  InterfaceController.swift
//  watch WatchKit Extension
//
//  Created by Ivan Stajcer on 28.02.2022..
//

import WatchKit
import Foundation
import WatchConnectivity


class InterfaceController: WKInterfaceController,  WCSessionDelegate {
    @IBOutlet weak var label: WKInterfaceLabel!
    @IBOutlet weak var button: WKInterfaceButton!
    var wcSession:  WCSession?
    private  var counter = 0
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        print("Activating session")
        wcSession = WCSession.default
        wcSession!.delegate = self
        wcSession!.activate()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    
    @IBAction func onButtonPressed() {
        //counter += 1
        sendDataMessage(for: .sendCounterToFlutter, data: ["counter": counter + 1])
    }
    
    // Add more cases if you have more receive method
    enum WatchReceiveMethod: String {
        case sendCounterToNative
    }
    
    // Add more cases if you have more sending method
    enum WatchSendMethod: String {
        case sendCounterToFlutter
    }
    
    func sendDataMessage(for method: WatchSendMethod, data: [String: Any] = [:]) {
        sendMessage(for: method.rawValue, data: data)
    }
    
    // Receive message From AppDelegate.swift that send from iOS devices
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Received message: ", message)
        print("Received context:", wcSession!.receivedApplicationContext)
        DispatchQueue.main.async {
            guard let method = message["method"] as? String, let enumMethod = WatchReceiveMethod(rawValue: method) else {
                return
            }
            
            switch enumMethod {
            case .sendCounterToNative:
                self.counter = (message["data"] as? Int) ?? 0
                self.label.setText("Counter:  \(self.counter)")
            }
        }
    }
    
    func sendMessage(for method: String, data: [String: Any] = [:]) {
        guard wcSession!.isReachable else {
            return
        }
        let messageData: [String: Any] = ["method": method, "data": data]
        wcSession!.sendMessage(messageData, replyHandler: nil, errorHandler: nil)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("@session did complete with: acctivation state: ", activationState.rawValue)
        print("Activated state...")
        print("Is reachable: ", wcSession!.isReachable)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Received application context: ", applicationContext)
    }

}
