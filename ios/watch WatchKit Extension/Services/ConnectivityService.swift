//
//  ConnectivityService.swift
//  watch WatchKit Extension
//
//  Created by Ivan Stajcer on 02.03.2022..
//

import Foundation
import WatchConnectivity

protocol CommunicationServiceDelegate {
    var id: String { get }
    var subscriptionTheme: WatchReceiveMethod { get }
    func onDataReceived(data: Any?)
}

enum WatchReceiveMethod: String {
    case incrementWatchCounter
    case presentTableData
}

enum WatchSendMethod: String {
    case sendCounterToFlutter
}

final class CommunicationService: NSObject {
    
    // MARK: - Properties -
    
    static let instance = CommunicationService()
    private var delegates = [CommunicationServiceDelegate]()
    private let tableDataPersistanceService = TableDataPersistanceService()
    private let wcSession = WCSession.default
    
    // MARK: - Int -
    
    private override init() {}
}

// MARK: - WCSessionDelegate methods
extension CommunicationService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("@session did complete with: acctivation state: ", activationState.rawValue)
        print("Is reachable: ", wcSession.isReachable)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleIncommingMessages(message: message, replyHandler: nil)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleIncommingMessages(message: applicationContext, replyHandler: nil)
    }
}

// MARK: - Public methods -

extension CommunicationService {
    func setupService() {
        if(WCSession.isSupported()) {
            wcSession.delegate = self
            wcSession.activate()
        }
    }
    
    func addDelegate(_ delegate: CommunicationServiceDelegate) {
        delegates.append(delegate)
        print("Added delegate, now list: ", delegates)
    }
    
    func removeDelegate(withId id: String) {
        delegates.removeAll { delegate in
            delegate.id == id
        }
        print("Removed delegates, now list: ", delegates)
    }
    
    func sendDataMessage(for method: WatchSendMethod, data: [String: Any] = [:]) {
        sendMessage(for: method.rawValue, data: data)
    }
    
    func sendMessage(for method: String, data: [String: Any] = [:]) {
        guard wcSession.isReachable else {
            return
        }
        let messageData: [String: Any] = ["method": method, "data": data]
        wcSession.sendMessage(messageData, replyHandler: nil, errorHandler: nil)
    }
}

// MARK: - Private methods -

private extension CommunicationService {
    func handleIncommingMessages(message: [String : Any], replyHandler: (([String : Any]) -> Void)?) {
        print("Watch received message: ", message)
        guard let method = message["method"] as? String, let subscriptionTheme = WatchReceiveMethod(rawValue: method) else {
            print("No such method for watch: ", message["method"] ?? "n/a")
            return
        }
        let data = message["data"]
        
        if (subscriptionTheme == .presentTableData) {
            handleTableData(data: data)
        }

        delegates.forEach { delegate in
            if (delegate.subscriptionTheme == subscriptionTheme) {
                delegate.onDataReceived(data: data)
            }
        }
    }
    
    func handleTableData(data: Any?) {
        guard let tableData = data as? Array<String> else {
            return
        }
        tableDataPersistanceService.saveTableData(tableData)
    }
}
