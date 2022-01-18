//
//  TrackingAlgorithm
//
//  Created by vedran on 15/12/2019.
//  Copyright © 2019 vedran. All rights reserved.
//

import UIKit
import CoreLocation

var locationManager2 = CLLocationManager()
var locationManagerLow = CLLocationManager()

class GeofencingManager: NSObject {
   
    enum MonitoringMode {
        case none
        case normal
        case spare
    }

    let useStandardLocationUpdates = true
    let useSignificantLocationUpdates = true
    let useRegionMonitoringUpdates = true
    let stopStandardLocationUpdatesByLowAccuracy = false

    var notifyServerFrequency = 20//30//10//30
    let regionMonitoredRadius = 20
    let spareModeLocationDistanceTimeout = 30   // seconds

    var monitoringMode: MonitoringMode = .none
    var requestLocationActive = false

    var lastRegionMonitored: CLRegion?
    var lastLocation: CLLocation?
    
    var spareModeActivationTimer: Timer?
    var timerPerformOnce: Timer?
    var timerPerformOnceTime: Date?

    var batteryUsage: (Float,Date)?
    
    var id: Int = 300
    var log = "start"

    override init() {
        
        super.init()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        
        UNUserNotificationCenter.current().delegate = self
        
        switch UIApplication.shared.backgroundRefreshStatus {
        case .available:
            self.printLogged("Refresh available")
        case .denied:
            self.printLogged("Refresh denied")
        case .restricted:
            self.printLogged("Refresh restricted")
        @unknown default:
            break
        }
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        self.printLogged("UIDevice.BatteryState \(100*level)")
        
        batteryUsage = (100*level,Date())
        
        let batteryUsageInterval = 10 * 60
        
        Timer.scheduledTimer(withTimeInterval: TimeInterval(batteryUsageInterval), repeats: true) { (timer) in
            
            let level = UIDevice.current.batteryLevel
            self.printLogged("UIDevice.BatteryState \(100*level)")

            let batteryUsageNow = (100*level,Date())
            
            if let batteryUsage = self.batteryUsage {
                let interval = batteryUsageNow.1.timeIntervalSince(batteryUsage.1)
                let perHour  = (batteryUsage.0 - batteryUsageNow.0) * 3600 / Float(interval)
//                print("Battery usage perHour \(perHour)")

                self.alert(withTitle: nil, message: "Battery usage perHour \(perHour)")

            }
        }

        locationManager2.delegate = self
        locationManager2.disallowDeferredLocationUpdates()
        locationManager2.allowsBackgroundLocationUpdates = true
//        locationManager2.showsBackgroundLocationIndicator = true
        locationManager2.pausesLocationUpdatesAutomatically = false
        
        locationManagerLow.delegate = self
        locationManagerLow.disallowDeferredLocationUpdates()
        locationManagerLow.allowsBackgroundLocationUpdates = true
//        locationManagerLow.showsBackgroundLocationIndicator = true
        locationManagerLow.pausesLocationUpdatesAutomatically = false
                
        DispatchQueue.main.async {
            locationManager2.requestAlwaysAuthorization()
            locationManagerLow.requestAlwaysAuthorization()
        }

        if #available(iOS 10.0, *) {
            let options: UNAuthorizationOptions = [.badge, .sound, .alert]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: options) { success, error in
                        if let error = error {
                            self.printLogged("Geofencing - Error: \(error)")
                        }
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
    }

    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: nil)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }

    @objc private func appDidEnterBackground() {
        
        // no activity needed
        
        // all application logic based on user's movement or not is based on distance from last two location updates, not on app foreground/background state
        
        printLogged("appDidEnterBackground")

//        // skip waiting for regin exit...
//        if let lastLocation = lastLocation {
//            self.activateStandardTracking()
//        }
        
//        if monitoringMode == .normal {
//            self.activateStandardTracking()
//        }
//        else if monitoringMode == .spare {
        
//        if monitoringMode != .spare {
            if let lastLocation = lastLocation {
                self.activateSpareTracking(location: lastLocation)
            }
//        }

    }

    @objc private func appDidBecomeActive() {
        
        printLogged("appDidBecomeActive")
        
        // update spare timer to next e.g. 30 seconds
        // ...
        
        
        // if we are in spare mode, switch to normal one
        
        if monitoringMode != .normal {
            self.activateStandardTracking()
        }
    }
    
    func printLogged(_ message: String) {
        print("\(Date()) \(message)")
        
        DispatchQueue.main.async {
            self.log = self.log + "\n----- \(Date()) \(message)"
        }
    }
    
    func activateSpareTracking(location: CLLocation, updateOnly: Bool = false) {
        
        locationManager2.requestAlwaysAuthorization()
        locationManagerLow.requestAlwaysAuthorization()

        if CLLocationManager.authorizationStatus() != .authorizedAlways &&
            CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
              let message = """
        Not still authorised to access the device location for spare tracking.
        """
              alert(withTitle:"Warning", message: message)
            
            return
          }

        // if we are alreaady in spare mode (due to fast/multiple location update events)
        
        if !updateOnly && monitoringMode == .spare {

            self.printLogged("we are alreaady in spare mode")

            return
        }
        
        monitoringMode = .spare

        // stop regular location tracking

        if stopStandardLocationUpdatesByLowAccuracy {
            locationManager2.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager2.distanceFilter = kCLLocationAccuracyThreeKilometers
        } else {
            locationManager2.stopUpdatingLocation()
        }
        
        // start significant location tracking and region monitoring
        
        if useSignificantLocationUpdates {
//            locationManager.desiredAccuracy = 15.0
//            locationManager.distanceFilter = 15.0
            locationManager2.startMonitoringSignificantLocationChanges()
//            locationManager2.activityType = .fitness //.otherNavigation
        }
        
        self.printLogged("locationManager.monitoredRegions \(locationManagerLow.monitoredRegions) pre")
        
        // stop monitoring previous region(s)
        for monitoredRegion in locationManagerLow.monitoredRegions {
            locationManagerLow.stopMonitoring(for: monitoredRegion)
        }

        lastRegionMonitored = region(with: location.coordinate, radius: CLLocationDistance(regionMonitoredRadius), identifier: "here \(regionMonitoredRadius)m \(id)")
        id += 1
                        
        if let lastRegionMonitored = lastRegionMonitored {
            locationManagerLow.startMonitoring(for: lastRegionMonitored)
            self.printLogged("Geofencing - starting region \(lastRegionMonitored.identifier) monitoring")
        }
        self.printLogged("locationManager.monitoredRegions \(locationManagerLow.monitoredRegions) post")

        alert(withTitle: nil, message: "SpareTracking activated")
        
    }

    func activateStandardTracking() {
        
        locationManager2.requestAlwaysAuthorization()
        
        if CLLocationManager.authorizationStatus() != .authorizedAlways &&
            CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
              let message = """
        Not still authorised to access the device locationfor normal tracking.
        """
              alert(withTitle:"Warning", message: message)
            
            return
          }

        if monitoringMode == .normal {

            self.printLogged("we are alreaady in normal mode")

            return
        }

        monitoringMode = .normal
        
        // stop significant location tracking and region monitoring

        if useSignificantLocationUpdates {
            locationManager2.stopMonitoringSignificantLocationChanges()
        }
        
        for monitoredRegion in locationManagerLow.monitoredRegions {
            locationManagerLow.stopMonitoring(for: monitoredRegion)
        }
        self.lastRegionMonitored = nil

        // start regular location tracking

        locationManager2.desiredAccuracy = 15.0//15.0
        locationManager2.distanceFilter = 15.0//15.0
        locationManager2.activityType = .fitness
        locationManager2.startUpdatingLocation()

        alert(withTitle: nil, message: "StandardTracking activated")
        
    }
    
    func performOnce( block: (() -> Void)?, in seconds: Int) {

        if let timerPerformOnceTime = timerPerformOnceTime {
            if Int(-timerPerformOnceTime.timeIntervalSinceNow) <= seconds {
                
                self.printLogged("performOnce invalidate \(timerPerformOnce)")
                timerPerformOnce?.invalidate()
                timerPerformOnce = nil
            }
            
        } else {
            timerPerformOnceTime = Date()
            self.printLogged("performOnce start new timer \(timerPerformOnceTime)")
        }
 
        self.printLogged("schedule after 10")
        timerPerformOnce = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { (timer) in
            
            self.timerPerformOnce = nil
            self.timerPerformOnceTime = nil
            
            self.printLogged("performOnce execute block")
            self.printLogged("----------------------------------------------------------------------------------------")
            block?()

        }
    }

   func performOnceImmedaetly( block: (() -> Void)?, in seconds: Int) {

       if let timerPerformOnceTime = timerPerformOnceTime {
           if Int(-timerPerformOnceTime.timeIntervalSinceNow) <= seconds {
               
            // skip
            self.printLogged("performOnceImmedaetly skip block")

            return
           }
        }
    
       timerPerformOnceTime = Date()
    
       self.printLogged("performOnceImmedaetly execute block")
       self.printLogged("----------------------------------------------------------------------------------------")
       block?()

   }

    func notifyServer(location: CLLocation) {
        let url = "https://api.spectrumtracking.com/v1/asset-logs"
        let authKey = "33bedd43-209c-4025-b157-d7c6df1211e3"
        
        self.printLogged("Geofencing - push() url: \(url) try")
        
        if let url = URL(string: url) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue(authKey, forHTTPHeaderField: "X-SpectrumTracking-TrackerEndpointKey")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-M-d HH:mm:ss"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let str_utc_time = dateFormatter.string(from: Date())
            
            do {
                let report: [String : Any] = [
                    "reportingId": Global.shared.app_user["email"].stringValue,
                    "dateTime" : str_utc_time,
                    "lat": location.coordinate.latitude,
                    "lng": location.coordinate.longitude,
                    "speedInMph": location.speed,
                    "ACCStatus": 1,
                    "OBDMileage": 0,
                    "trackerModel": "phone",
                    "lastAlert": "",
                ]
                self.printLogged("report \(report)")
                
                let reportData = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted])
                
                request.httpBody = reportData
            } catch {
                self.printLogged("Geofencing - push error: \(error.localizedDescription)")
            }

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    //There was an error
                    self.printLogged("Geofencing - fetchNearbyPlaces() failed with the following error: \(error)")

                } else {
                    //The HTTP request was successful

                    self.printLogged("Geofencing - push() stay: succesfull")
//                    self.printLogged(data)

                    if let data = data {
                        let s = String(data: data, encoding: .utf8)
//                        self.printLogged(s)
                        self.printLogged("Geofencing - push() stay: data: \(s)")
                    }
                    do {

                        let json = try JSONSerialization.jsonObject(with: data!, options: [])
                        if let object = json as? [String: Any] {
                            // json is a dictionary
                            self.printLogged("Geofencing - push - \(object.count) dictionary objects")
                        } else if let object = json as? [[String:Any]] {
                            // json is an array
//                            self.printLogged(object.count)
                            self.printLogged("Geofencing - push - \(object.count) places")

                        } else {
                            self.printLogged("Geofencing - push: JSON is invalid")
                        }
                    } catch {
                        self.printLogged("Geofencing - push error: \(error.localizedDescription)")
                    }

                }

            }
            task.resume()
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.printLogged("Geofencing - didAuthorize \(status)")
        self.printLogged("Geofencing - didAuthorize always \(status == .authorizedAlways)")
        
        //        2019-07-22 15:31:57.866774+0200 MyApp[508:31702] Geofencing - didUpdateLocations: [<+45.80049365,+15.96997018> +/- 65.00m (speed -1.00 mps / course -1.00) @ 22/07/2019, 15:31:48 Central European Summer Time]

        DispatchQueue.main.async {
            if CLLocationManager.authorizationStatus() == .authorizedAlways ||
                CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
                
                // always start first with normal tracking and switch to spare one later if needed
                
                // to skip multiple registrations
                if manager == locationManager2 {
                    let phoneTrackingFlag = UserDefaults.standard[.phoneTracking] ?? false
                    if phoneTrackingFlag {
                        self.activateStandardTracking()
                    }
                }
              }

        }

    }
    
    func region(with coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String) -> CLCircularRegion {
        
        // 1
        let region = CLCircularRegion(center: coordinate,
                                      radius: radius,
                                      identifier: identifier)
        // 2
        region.notifyOnEntry = true
        region.notifyOnExit = true
        return region
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?,
                         withError error: Error) {
        self.printLogged("monitoringDidFailFor - Monitoring failed for region with identifier: \(region!.identifier) \(error)")
        
        alert(withTitle: "monitoringDidFailFor", message: "Monitoring failed for region with identifier: \(region!.identifier) \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.printLogged("didFailWithError - Location Manager failed with the following error: \(error)")
        
        alert(withTitle: "didFailWithError", message: "Location Manager failed with the following error: \(error)")

    }
    
    func showAlert(withTitle title: String?, message: String?) {
        self.printLogged("showAlert \(title) - \(message)")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)

//        present(alert, animated: true, completion: nil)
        let window = UIApplication.shared.windows.first
        window?.rootViewController?.present(alert, animated: true, completion: nil)
    }

}

extension GeofencingManager: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        self.printLogged("Geofencing - Location Manager didEnterRegion \(region)")
        if region is CLCircularRegion {
            handleEvent(for: region,description: "enter \(region.identifier) @\(Date())")
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        self.printLogged("Geofencing - Location Manager didExitRegion \(region)")
        if region is CLCircularRegion {
            handleEvent(for: region,description: "exit \(region.identifier) @\(Date())")
        }
                
//        if monitoringMode != .normal {
//            self.activateStandardTracking()
//        }
        
        // be careful because this stops standard location updates!!!
        DispatchQueue.main.async {
            self.requestLocationActive = true
            locationManagerLow.requestLocation()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        self.printLogged("Geofencing - didStartMonitoringFor: \(region.identifier)")
        self.printLogged("locationManager.monitoredRegions didStartMonitoringFor  \(locationManagerLow.monitoredRegions)")
        
        alert(withTitle: "didStartMonitoringFor", message: " \(region.identifier) @\(Date())")
    }
        
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        printLogged("Geofencing - didUpdateLocations: \(locations)")
        
        let location = locations.last!

        // if we got location that is close to previous one, suppose user is stopping and try to switch to
        // spare mode, if no significant movement was recognised in meantime
        
        // if there is a significant movement, cancel attmpt to switch to spare mode
        
//        if let lastLocation = lastLocation {
        
        Global.shared.userLocation = location.coordinate
        
        let dist = lastLocation?.distance(from: location)
        
        self.printLogged("Distance \(dist) meters")

        self.handleEvent(for: location, description: "\(Int(dist ?? 999)) meters move @\(location.timestamp)")
        
        if Global.shared.app_user != nil {
            DispatchQueue.main.async {
                self.performOnceImmedaetly(block: {
                    self.notifyServer(location: location)
                }, in: self.notifyServerFrequency)
            }
        }

        lastLocation = location
        
        // be careful because this stops standard location updates!!!
        DispatchQueue.main.async {
            if self.requestLocationActive {
//                locationManager2.startUpdatingLocation()
                self.requestLocationActive = false
                self.activateSpareTracking(location: location,updateOnly: true)
            }
        }
    }

}


import UserNotifications

extension GeofencingManager {
    
    func note(from identifier: String) -> String? {
        return "region"
    }
    
    func handleEvent(for region: CLRegion!, description: String) {
        self.printLogged("Geofencing - region Geofence triggered!")
        // Show an alert if application is active
        if false && UIApplication.shared.applicationState == .active {
//            guard let message = note(from: region.identifier) else { return }
//            showAlert(withTitle: nil, message: "\(message) \(description)")
        } else {
            NotificationCenter.default.post(name: NSNotification.Name("NotificationRegionChanged"), object: region)
        }
    }
    
    func handleEvent(for location: CLLocation!, description: String) {
        self.printLogged("Geofencing - Geofence location triggered!")
        // Show an alert if application is active
        if  false && UIApplication.shared.applicationState == .active {
//            showAlert(withTitle: nil, message: "location update \(description)")
        } else {
            NotificationCenter.default.post(name: NSNotification.Name("NotificationCurrentLocationChanged"), object: location)
        }
    }
    
    func alert(withTitle title: String?, message: String?) {
        self.printLogged("Geofencing - Geofence alert \(String(describing: title)) \(String(describing: message))")
        
        // Show an alert if application is active
        if  false && UIApplication.shared.applicationState == .active {
//            showAlert(withTitle: title, message: message)
        } else {
            // Otherwise present a local notification
            if #available(iOS 10.0, *) {
//                let notificationContent = UNMutableNotificationContent()
//                notificationContent.body = (title ?? "") + (message ?? "")
//                if #available(iOS 12.0, *) {
//                    notificationContent.sound = UNNotificationSound.defaultCritical
//                } else {
//                    // Fallback on earlier versions
//                }
//                notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
//                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
//                let request = UNNotificationRequest(identifier: "message \(id)",
//                                                    content: notificationContent,
//                                                    trigger: trigger)
//                id += 1
//
//                UNUserNotificationCenter.current().add(request) { error in
//                    if let error = error {
//                        self.printLogged("Geofencing - location Error: \(error)")
//                    }
//                }
            } else {
                // Fallback on earlier versions
//                self.printLogged("Geofencing - location fallback")
            }
        }
    }
}


extension GeofencingManager: UNUserNotificationCenterDelegate {

    //for displaying notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        //If you don't want to show notification when app is open, do something here else and make a return here.
        //Even you you don't implement this delegate method, you will not see the notification on the specified controller. So, you have to implement this delegate and make sure the below line execute. i.e. completionHandler.

        completionHandler([.alert, .badge, .sound])
    }

    // For handling tap and user actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        switch response.actionIdentifier {
        case "action1":
            print("Action First Tapped")
        case "action2":
            print("Action Second Tapped")
        default:
            break
        }
        completionHandler()
    }

}
