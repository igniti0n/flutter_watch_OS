//
//  WeatherService.swift
//  watch WatchKit Extension
//
//  Created by Ivan Stajcer on 03.03.2022..
//

import Foundation
import WatchKit

// api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={API key}

typealias WeatherCallback = (WeatherData) -> Void

struct WeatherData: Codable {
    let temperature: String
    let windSpeed: String
    let pressure: String
    
    static func mock() -> WeatherData {
        WeatherData(temperature: "mock", windSpeed: "mock", pressure: "mock")
    }
    
    static func createFromData(with data: Data) -> WeatherData {
        guard let weatherDataJSON = try? JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed) as? [String : Any] else {
            print("JSON object failed to be created.")
            return WeatherData.mock()
        }
        print("Created JSON object: \n", weatherDataJSON)
        guard
            let temp = (weatherDataJSON["main"] as? [String : Any])?["temp"] as? Double,
            let wind = (weatherDataJSON["wind"] as? [String : Any])?["speed"] as? Double,
            let pressure = (weatherDataJSON["main"] as? [String : Any])?["pressure"] as? Int
        else {
            print("Converting to data from JSON failed")
            return WeatherData.mock()
        }
        print("Success!")
        let weatherData = WeatherData(temperature: String(temp), windSpeed: String(wind), pressure: String(pressure))
        return weatherData
    }
}

protocol WeatherServiceProtocol {
    func fetchWeatherForeground(completion: WeatherCallback?)
    func fetchWeatherBackground(isFirst: Bool)
}

final class WeatherService: NSObject {
    
    // MARK: - Properties -
    
    static let shared = WeatherService()
    var onUrlSessionBackgroundTaskCompleted: ((_ shouldUpdate: Bool) -> Void)?
    private let tableDataPersistanceService = TableDataPersistanceService()
    private let apiKey = "33a595b1052037a58ebbd6503b0303ac"
    private var backgroundTask: URLSessionTask?  // Store task in order to complete it when finished
    
    // MARK: - Comupted properties -
    
    private var backgroundSession: URLSession {
        let sessionIdentifier = "backgroundConfigurationIdentifier"
        let config = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true

       return URLSession(configuration: config,
                                    delegate: self,
                                    delegateQueue: nil)

    }
    
    // MARK: - Init -
    
    private override init() {}
}

// MARK: - Public methods -

extension WeatherService: WeatherServiceProtocol {
    /* SCHEDULE A BACKGROOUND REFRESH TASK -> tis task DOES NOT ALLOW NETWORKING!
     
     Shedule task -> afte tim is up, system decides whento call and calles the WKExtension delegate handle method
     
     Can only have about 4 of them in 1h, when you have complications. Only 1 if not.
     */
    func scheduleBackgroundRefresh() {
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: Date(timeIntervalSinceNow: 8), userInfo: nil) { error in
            print("Error when shcedualing background refresh task: ", error)
        }
    }
    
    /* SCHEDULE A URL SESSION BACKGROUND TASK -> ALLOWS networking!
     
     Schedule task -> time passes -> WKEExtension delegategate 'handle' method called -> you set completion handler -> when task completed
     URL session delegate method 'didFinishDownloadingTo' gets called -> you call your completion ahndler there
     
     Can only have about 4 of them in 1h, when you have complications. Only 1 if not.
     */
    func fetchWeatherBackground(isFirst: Bool) {
        if (backgroundTask == nil) {
            let task = backgroundSession.downloadTask(with: getUrlRequest())
            // if not first task, schedule in 15 minutees
            task.earliestBeginDate = Date().addingTimeInterval(isFirst ? 10 : 15*60)
            backgroundTask = task
            task.resume()
        }
    }
    
    // Can only be called while app in foreground
    func fetchWeatherForeground(completion: WeatherCallback?) {
        let task = URLSession.shared.dataTask(with: getUrlRequest()) { [weak self] data, response, error in
            guard
            let data = data,
            let response = response as? HTTPURLResponse,
            200..<300 ~= response.statusCode
            else {
                return
            }
            let weatherData = WeatherData.createFromData(with: data)
            completion?(weatherData)
        }
        task.resume()
    }
}

// MARK: - URLSessionDownloadDelegate methods -

extension WeatherService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        processFile(at: location)
    }
    
    private func processFile(at url: URL){
        if let data = try? Data(contentsOf: url) {
            let weatherData = WeatherData.createFromData(with: data)
            tableDataPersistanceService.saveTableData(["Bok", "From", "Background", "WOW"])
            onUrlSessionBackgroundTaskCompleted?(true)
            print("Weather data from file downlaoded in background: \n", weatherData)
        } else {
            print("Can not get 'Data' from file at loaction: \n", url)
        }
    }
}


// MARK: - Private methods -

private extension WeatherService {
    func getUrlRequest() -> URLRequest {
        var urlComponents = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")!
        urlComponents.queryItems = [URLQueryItem(name: "lat", value: "45.5550"), URLQueryItem(name: "lon", value: "18.6955"), URLQueryItem(name: "appid", value: "33a595b1052037a58ebbd6503b0303ac")]
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        return request
    }
}


//extension WeatherService: URLSessionDownloadDelegate {
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
//        processFile(at: location)
//
//        self.pendingBackgroundTasks.forEach { task in
//            task.setTaskCompletedWithSnapshot(false)
//        }
//    }
//
//
//    private func processFile(at url: URL){
//        if let data = try? Data(contentsOf: url) {
//            let weatherData = WeatherData.createFromData(with: data)
//            print("Weather data from file downlaoded in background: \n", weatherData)
//            weatherLabel.setText("Temp: \(weatherData.temperature)")
//            windLabel.setText("Wind: \(weatherData.windSpeed)")
//            pressureLabel.setText("Pressure: \(weatherData.pressure)")
//        } else {
//            print("Can not get 'Data' from file at loaction: \n", url)
//        }
//    }
//}
