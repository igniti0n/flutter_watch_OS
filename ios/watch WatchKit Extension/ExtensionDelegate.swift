//
//  ExtensionDelegate.swift
//  watch WatchKit Extension
//
//  Created by Ivan Stajcer on 28.02.2022..
//

import WatchKit
import ClockKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    private let weatherService =  WeatherService.shared

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        CommunicationService.instance.setupService()
        weatherService.fetchWeatherBackground(isFirst: true)
        updateComplications()
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        print("HANDLE CALLED for  some background tasks: \n", backgroundTasks)
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                print("APP REFRESH BACKGROUND  TASK!: \n", backgroundTasks)
                //WeatherService.shared.fetchWeatherBackground()
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                print("URL SESSION TASK!: \n", urlSessionTask)
                weatherService.onUrlSessionBackgroundTaskCompleted = { [weak self] shouldUpdate in
                    //weatherService.fetchWeatherBackground(isFirst: false) // schedule anotheer refresh
                    if (shouldUpdate) {
                        print("UPDATING COMPLICATIONS")
                        self?.updateComplications()
                    } else {
                        print("Did not update any complications")
                    }
                    urlSessionTask.setTaskCompletedWithSnapshot(false)
                }
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}


// MARK: - Private methods -

private extension ExtensionDelegate {
    func updateComplications() {
        Task {
            let complicationServer = CLKComplicationServer.sharedInstance()
            let activeComplications = await complicationServer.getActiveComplications()
            print("Active complications: ", activeComplications)
            for complication in activeComplications {
                complicationServer.reloadTimeline(for: complication)
            }
        }
    }
}



// This is used to get active complciations safely, check apple documetation
extension CLKComplicationServer {
    
    // Safely access the server's active complications, main actor enabels the code torun on the main thread
    @MainActor
    func getActiveComplications() async -> [CLKComplication] {
        return await withCheckedContinuation { continuation in
            
            // First, set up the notification.
            let center = NotificationCenter.default
            let mainQueue = OperationQueue.main
            var token: NSObjectProtocol?
            token = center.addObserver(forName: .CLKComplicationServerActiveComplicationsDidChange, object: nil, queue: mainQueue) { _ in
                center.removeObserver(token!)
                continuation.resume(returning: self.activeComplications!)
            }
            
            // Then check to see if we have a valid active complications array.
            if activeComplications != nil {
                center.removeObserver(token!)
                continuation.resume(returning: self.activeComplications!)
            }
        }
    }
}
