//
//  WeatherViewController.swift
//  spectrum_tracker
//
//  Created by Admin on 12/21/18.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreLocation
class WeatherViewController: BaseViewController {
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "WeatherViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    @IBAction func goMain(_ sender: Any) {
        self.slideMenuController()?.changeMainViewController(MonitorViewController.getNewInstance(), close: true)
    }
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var weather_view: UIStackView!
    @IBOutlet var first_weather_icon: UIImageView!
    @IBOutlet var first_temperature: UILabel!
    @IBOutlet var first_datetime: UILabel!
    @IBOutlet var first_humidity: UILabel!
    @IBOutlet var first_wind: UILabel!
    @IBOutlet var first_weather_state: UILabel!
    @IBOutlet var second_datetime: UILabel!
    @IBOutlet var second_weather_icon: UIImageView!
    @IBOutlet var second_temperature: UILabel!
    @IBOutlet var second_humidity: UILabel!
    @IBOutlet var second_wind: UILabel!
    @IBOutlet var second_weather_state: UILabel!
    @IBOutlet var third_datetime: UILabel!
    @IBOutlet var third_weather_icon: UIImageView!
    @IBOutlet var third_temperature: UILabel!
    @IBOutlet var third_humidity: UILabel!
    @IBOutlet var third_wind: UILabel!
    @IBOutlet var third_weather_state: UILabel!
    @IBOutlet var fourth_datetime: UILabel!
    @IBOutlet var fourth_weather_icon: UIImageView!
    @IBOutlet var fourth_temperature: UILabel!
    @IBOutlet var fourth_humidity: UILabel!
    @IBOutlet var fourth_wind: UILabel!
    @IBOutlet var fourth_weather_state: UILabel!
    @IBOutlet var main_weather_icon: UIImageView!
    @IBOutlet var main_temperature: UILabel!
    @IBOutlet var main_humidity: UILabel!
    @IBOutlet var main_wind: UILabel!
    @IBOutlet var main_pressure: UILabel!
    @IBOutlet var main_weather_label: UILabel!

    var startLocation: CLLocation!
    var temperatures: [String]!
    var dateTimes: [String]!
    var weatherIcons: [Data]!
    var humiditys: [String]!
    var pressures: [String]!
    var winds: [String]!
    var states: [String]!
    let imaURL: String = "https://openweathermap.org/img/w/"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        temperatures = [String]()
        humiditys = [String]()
        winds = [String]()
        pressures = [String]()
        dateTimes = [String]()
        weatherIcons = [Data]()
        states = [String]()
        
        NotificationCenter.default.addObserver(self, selector: #selector(locationChanged(_:)), name: NSNotification.Name("NotificationCurrentLocationChanged"), object: nil)
    }
    
    @objc func locationChanged(_ sender: Any) {
        guard let locationCoordinate = Global.shared.userLocation else { return }
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotificationCurrentLocationChanged"), object: nil)
        
        let lati = Float(CGFloat(locationCoordinate.latitude))
        let longi = Float(CGFloat(locationCoordinate.longitude))
        let path = "http://api.openweathermap.org/data/2.5/forecast?lat=\(lati)&lon=\(longi)&appid=0be1fd5d65ce6c964b3962a4649d4670"
        print(path)
        
        let url = URL(string: path)
        let request = URLRequest(url: url!)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error{
                print(error)
                self.indicator.isHidden = true
                self.view.makeToast("weather server connect error".localized())
            }
            else {
                //let queue = DispatchQueue(label:"work_queue",qos:.userInteractive)
                //queue.async {
                self.extractData(weatherData: data! as NSData)
                DispatchQueue.main.sync{
                    //self.extractData(weatherData: data! as NSData)
                    self.setValues()
                }
                //}
            }
        }
        task.resume()
    }
}
extension WeatherViewController {
    func setValues()
    {
        if(temperatures.count != 0 && humiditys.count != 0 && winds.count != 0 && pressures.count != 0 && states.count != 0) {
        main_temperature.text = temperatures[0]
        main_humidity.text = humiditys[0]
        main_wind.text = winds[0]
        main_pressure.text = pressures[0]
        main_weather_label.text = states[0]
        
        first_temperature.text = temperatures[1]
        first_humidity.text = humiditys[1]
        first_wind.text = winds[1]
        first_weather_state.text = states[1]
        first_datetime.text = dateTimes[1]
        
        second_temperature.text = temperatures[2]
        second_humidity.text = humiditys[2]
        second_wind.text = winds[2]
        second_weather_state.text = states[2]
        second_datetime.text = dateTimes[2]
        
        third_temperature.text = temperatures[3]
        third_humidity.text = humiditys[3]
        third_wind.text = winds[3]
        third_weather_state.text = states[3]
        third_datetime.text = dateTimes[3]
        
        fourth_temperature.text = temperatures[4]
        fourth_humidity.text = humiditys[4]
        fourth_wind.text = winds[4]
        fourth_weather_state.text = states[4]
        fourth_datetime.text = dateTimes[4]
        }
        if(weatherIcons.count != 0) {
            main_weather_icon.image = UIImage(data: weatherIcons[0])
            first_weather_icon.image = UIImage(data: weatherIcons[1])
            second_weather_icon.image = UIImage(data: weatherIcons[2])
            third_weather_icon.image = UIImage(data: weatherIcons[3])
            fourth_weather_icon.image = UIImage(data: weatherIcons[4])
        }
        weather_view.isHidden = false
        indicator.isHidden = true
    }
    func extractData(weatherData: NSData) {
        let res = try? JSON.init(data: weatherData as Data)
        print(res ?? "")
        let lists = res!["list"]
        for i in 0..<5 {
            let list = lists[i]
            let datetime = list["dt_txt"].stringValue
            let start = datetime.index(datetime.startIndex,offsetBy:5)
            let end = datetime.index(datetime.endIndex,offsetBy:-3)
            let range = start..<end
            dateTimes.append(String(datetime[range]))
            let main = list["main"]
            temperatures.append(String(format: "%d", Int((main["temp"].doubleValue-273)*9/5+32))+"℉")
            pressures.append(String(format: "%.2f", main["pressure"].doubleValue)+"hpa")
            humiditys.append(String(format: "%.1f", main["humidity"].doubleValue)+"%")
            let wind = list["wind"]
            winds.append(String(format: "%.2f", wind["speed"].doubleValue)+"m/s")
            let weather = list["weather"][0]
            states.append(weather["description"].stringValue)
            var flag = true
            guard let imageData = try? Data(contentsOf: URL(string: "\(self.imaURL)\(weather["icon"].stringValue).png")!) else {
                flag = false
                self.view.makeToast("weather server connect error".localized())
                return
            }
            if flag {
                weatherIcons.append(imageData)
            }
        }
        //setValues()
    }
}
