//
//  InterfaceController.swift
//  watch WatchKit Extension
//
//  Created by Ivan Stajcer on 28.02.2022..
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {
    @IBOutlet weak var label: WKInterfaceLabel!
    @IBOutlet weak var button: WKInterfaceButton!
    private  var counter = 0
    private let communicationService = CommunicationService.instance
    
    override func awake(withContext context: Any?) {
    }
    
    override  func willActivate() {
        communicationService.addDelegate(self)
    }
    
    override func willDisappear() {
        communicationService.removeDelegate(withId: self.id)
    }
    
    @IBAction func onButtonPressed() {
        communicationService.sendDataMessage(for: .sendCounterToFlutter, data: ["counter": counter + 1])
    }
}

extension InterfaceController: CommunicationServiceDelegate {
    var subscriptionTheme: WatchReceiveMethod {
        .incrementWatchCounter
    }
    
    var id: String {
        "interfaceId"
    }
    
    func onDataReceived(data: Any?) {
        self.counter = (data as? Int) ?? 0
        print("Receieved counter: ", counter)
        self.label.setText("Counter:  \(self.counter)")
    }
}
