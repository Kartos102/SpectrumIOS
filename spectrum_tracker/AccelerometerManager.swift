//
//  AccelerometerManager.swift
//  iOSTrackingAlgorithm
//
//  Created by vedran on 16/12/2019.
//  Copyright © 2019 vedran. All rights reserved.
//

import UIKit
import CoreMotion
import UserNotifications

class AccelerometerManager {
    
    let motion = CMMotionManager()
    
    var timer: Timer?
    var batteryUsage: (Float,Date)?

    init() {
        
//        super.init()
        
//        fetchNearbyPlaces()
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        print("UIDevice.BatteryState \(100*level)")
        
        batteryUsage = (100*level,Date())
        
        let batteryUsageInterval = 10 * 60
        
        Timer.scheduledTimer(withTimeInterval: TimeInterval(batteryUsageInterval), repeats: true) { (timer) in
            
            let level = UIDevice.current.batteryLevel
            print("UIDevice.BatteryState \(100*level)")

            let batteryUsageNow = (100*level,Date())
            
            if let batteryUsage = self.batteryUsage {
                let interval = batteryUsageNow.1.timeIntervalSince(batteryUsage.1)
                let perHour  = (batteryUsage.0 - batteryUsageNow.0) * 3600 / Float(interval)
//                print("Battery usage perHour \(perHour)")

                self.alert(withTitle: nil, message: "Battery usage perHour \(perHour)")

            }
        }

        if #available(iOS 10.0, *) {
            let options: UNAuthorizationOptions = [.badge, .sound, .alert]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                UNUserNotificationCenter.current()
                    .requestAuthorization(options: options) { success, error in
                        if let error = error {
                            NSLog("Geofencing - Error: \(error)")
                        }
                }
            }
        } else {
            // Fallback on earlier versions
        }
        
        startAccelerometers()
        
    }
    
    func startAccelerometers() {
       // Make sure the accelerometer hardware is available.
        
        let interval  = 1.0//60.0
        
       if self.motion.isAccelerometerAvailable {
          self.motion.accelerometerUpdateInterval = 5.0 / interval  // 60 Hz
          self.motion.startAccelerometerUpdates()

        Timer.scheduledTimer(withTimeInterval: (1.0/interval), repeats: true) { (timer) in
            // Get the accelerometer data.
            if let data = self.motion.accelerometerData {
               let x = data.acceleration.x
               let y = data.acceleration.y
               let z = data.acceleration.z

               // Use the accelerometer data in your app.
               print("AccelerometerManager \(x) \(y) \(z)")
        }
//          // Configure a timer to fetch the data.
//          self.timer = Timer(fire: Date(), interval: (1.0/interval),
//                repeats: true, block: { (timer) in
//             // Get the accelerometer data.
//             if let data = self.motion.accelerometerData {
//                let x = data.acceleration.x
//                let y = data.acceleration.y
//                let z = data.acceleration.z
//
//                // Use the accelerometer data in your app.
//                print("AccelerometerManager \(x) \(y) \(z)")
//             }
//          })
//
//          // Add the timer to the current run loop.
//        RunLoop.current.add(self.timer!, forMode: .default)
       }
        }
    }
    
    
    func alert(withTitle title: String?, message: String?) {
        NSLog("Geofencing - Geofence alert \(title) \(message)")
        
        // Show an alert if application is active
        if UIApplication.shared.applicationState == .active {
            showAlert(withTitle: title, message: message)
        } else {
            // Otherwise present a local notification
            if #available(iOS 10.0, *) {
                let notificationContent = UNMutableNotificationContent()
                notificationContent.body = (title ?? "") + (message ?? "")
                notificationContent.sound = UNNotificationSound.default
                notificationContent.badge = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(identifier: "location_change",
                                                    content: notificationContent,
                                                    trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        NSLog("Geofencing - location Error: \(error)")
                    }
                }
            } else {
                // Fallback on earlier versions
                NSLog("Geofencing - location fallback")
            }
        }
    }
    
    func showAlert(withTitle title: String?, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        
//        present(alert, animated: true, completion: nil)
        let window = UIApplication.shared.windows.first
        window?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
