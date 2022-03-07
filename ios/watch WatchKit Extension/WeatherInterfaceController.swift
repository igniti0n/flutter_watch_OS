//
//  WeatherInterface.swift
//  watch WatchKit Extension
//
//  Created by Ivan Stajcer on 03.03.2022..
//

import Foundation
import WatchKit

final class WeatherInterfaceController: WKInterfaceController {
    @IBOutlet weak var weatherLabel: WKInterfaceLabel!
    @IBOutlet weak var windLabel: WKInterfaceLabel!
    @IBOutlet weak var pressureLabel: WKInterfaceLabel!
    private  var counter = 0
    private let weatherDataService = WeatherService.shared
    
    override func awake(withContext context: Any?) {

    }
    
    override  func willActivate() {
        print("WILL ACTIVATE")
        //weatherDataService.fetchWeatherBackground(delegate: self)
//        { [weak self] weatherData in

//        }
    }
    
    override func willDisappear() {
    }
    
    @IBAction func onFetchButtonPressed() {
        WeatherService.shared.fetchWeatherForeground { [weak self] weatherData in
            self?.updateUI(with: weatherData)
        }
    }
    
    func updateUI(with weatherData: WeatherData) {
        weatherLabel.setText("Temp: \(weatherData.temperature)")
        windLabel.setText("Wind: \(weatherData.windSpeed)")
        pressureLabel.setText("Pressure: \(weatherData.pressure)")
    }
}
