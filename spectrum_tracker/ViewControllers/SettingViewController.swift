//
//  SettingViewController.swift
//  spectrum_tracker
//
//  Created by Admin on 6/7/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import MBRadioCheckboxButton

class SettingViewController: ViewControllerWaitingResult {
    
    @IBOutlet weak var milesRadioButton: RadioButton!
    @IBOutlet weak var kmRadioButton: RadioButton!
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "SettingViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }

    @IBOutlet var edit_delay: UITextField!
    @IBAction func onEditDelayChange(_ sender: Any) {
        if edit_delay.text == "" || edit_delay.text == "0" {
            return
        }
        Defaults[.uploadDelay] = Int(edit_delay.text ?? "30")
        geofencingManager.notifyServerFrequency = Defaults[.uploadDelay] ?? 30
    }
    @IBOutlet var icon_phonetracking: UIImageView!
    @IBOutlet var s_phonetracking: UISwitch!
    @IBAction func onPhoneTrackingChange(_ sender: Any) {
        Defaults[.phoneTracking] = s_phonetracking.isOn
        if s_phonetracking.isOn {
            MainContainerViewController.instance.setPhoneTracker()
            locationManager2.startUpdatingLocation()
        }else {
            locationManager2.stopUpdatingLocation()
        }
    }
    @IBOutlet var icon_contact: UIImageView!
    @IBAction func onContact(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/contact.html") else {return}
        UIApplication.shared.open(url)
    }
    @IBOutlet var icon_faq: UIImageView!
    @IBAction func onFAQ(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/faq.html") else {return}
        UIApplication.shared.open(url)
    }
    @IBOutlet var icon_activate: UIImageView!
    @IBAction func onActivate(_ sender: Any) {
        MainContainerViewController.instance.onActicate(self)
    }
    @IBOutlet var icon_alarm: UIImageView!
    @IBAction func onSetAlarms(_ sender: Any) {
        MainContainerViewController.instance.onSetAlarms(self)
    }
    @IBOutlet var icon_geofence: UIImageView!
    @IBAction func onGeofence(_ sender: Any) {
        MainContainerViewController.instance.onGeofence(self)
    }
    @IBOutlet var icon_order_service: UIImageView!
    @IBAction func onOrderService(_ sender: Any) {
        MainContainerViewController.instance.onService(self)
    }
    @IBAction func onVehicle(_ sender: Any) {
        MainContainerViewController.instance.onDriverInfo(self)
    }
    @IBOutlet var icon_logout: UIImageView!
    @IBAction func onLogout(_ sender: Any) {
        MainContainerViewController.instance.onLogout(self)
    }
    @IBOutlet var icon_screenLock: UIImageView!
    @IBOutlet var switch_SAutoLock: UISwitch!
    @IBAction func onScreenAutoLockChange(_ sender: UISwitch) {
        Defaults[.sautolock] = sender.isOn
        UIApplication.shared.isIdleTimerDisabled = Defaults[.sautolock] ?? false
    }
    let normalColor: UIColor = UIColor(hexString: "#777777")
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switch_SAutoLock.isOn = Defaults[.sautolock] ?? false
        s_phonetracking.isOn = Defaults[.phoneTracking] ?? false
        icon_alarm.image = icon_alarm.image?.withRenderingMode(.alwaysTemplate)
        icon_alarm.tintColor = normalColor
        
        icon_logout.image = icon_logout.image?.withRenderingMode(.alwaysTemplate)
        icon_logout.tintColor = normalColor
        
        icon_order_service.image = icon_order_service.image?.withRenderingMode(.alwaysTemplate)
        icon_order_service.tintColor = normalColor
        
        icon_geofence.image = icon_geofence.image?.withRenderingMode(.alwaysTemplate)
        icon_geofence.tintColor = normalColor
        
        icon_activate.image = icon_geofence.image?.withRenderingMode(.alwaysTemplate)
        icon_activate.tintColor = normalColor
        
        icon_faq.image = icon_faq.image?.withRenderingMode(.alwaysTemplate)
        icon_faq.tintColor = normalColor
        
        icon_contact.image = icon_contact.image?.withRenderingMode(.alwaysTemplate)
        icon_contact.tintColor = normalColor
        
        icon_screenLock.image = icon_screenLock.image?.withRenderingMode(.alwaysTemplate)
        icon_screenLock.tintColor = normalColor
        
        icon_phonetracking.image = icon_phonetracking.image?.withRenderingMode(.alwaysTemplate)
        icon_phonetracking.tintColor = normalColor
        
        edit_delay.text = String(Defaults[.uploadDelay] ?? 30)
        
        let distanceUnit = Defaults[.distanceUnit] ?? "miles"
        if distanceUnit == "km" {
            milesRadioButton.isOn = false
            kmRadioButton.isOn = true
        } else {
            milesRadioButton.isOn = true
            kmRadioButton.isOn = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        geofencingManager.notifyServerFrequency = Defaults[.uploadDelay] ?? 30
        super.viewWillDisappear(animated)
    }
    
    @IBAction func milesButtonTapped(_ sender: Any) {
        Defaults[.distanceUnit] = "miles"
    }
    
    @IBAction func kmButtonTapped(_ sender: Any) {
        Defaults[.distanceUnit] = "km"
    }
    
}
