//
//  SetAlarmViewController.swift
//  spectrum_tracker
//
//  Created by Robin on 2018/09/28.
//  Copyright © 2018 Robin. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftyUserDefaults

class SetAlarmViewController: ViewControllerWaitingResult,UIScrollViewDelegate {

    static var instance: UIViewController!
    static func getNewInstance() -> UIViewController {
        if instance == nil {
            let storyboardName = "Main"
            let viewControllerIdentifier = "SetAlarmViewController"
            
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
            return vc
        } else {
            return instance
        }
    }
    
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var bottomTableView: UIView!
    @IBOutlet var table_handler: UIImageView!
    @IBOutlet var s_speedingAlarmStatus: UISwitch!
    @IBOutlet var s_harshTurnAlarmStatus: UISwitch!
    @IBOutlet var s_harshAcceAlarmStatus: UISwitch!
    @IBOutlet var s_harshDeceAlarmStatus: UISwitch!
    @IBOutlet var s_tamperAlarmStatus: UISwitch!
    @IBOutlet var s_geoFenceAlarmStatus: UISwitch!
    @IBOutlet var s_textAlertAlarmStatus: UISwitch!
    @IBOutlet var s_emailAlarmStatus: UISwitch!
    @IBOutlet var s_engineOnAlarmStatus: UISwitch!
    @IBOutlet var s_alertSoundAlarmStatus: UISwitch!
    @IBOutlet var s_engineOffAlarmStatus: UISwitch!
    @IBOutlet var s_airplaneModeStatus: UISwitch!
    @IBOutlet var s_vibrationAlarmStatus: UISwitch!
    @IBOutlet var topView: UIScrollView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var tableViewHC: NSLayoutConstraint!
    @IBOutlet var txt_textAlertPhoneNumber: UITextField!
    @IBOutlet var txt_userTracker_speedLimit: UITextField!
    @IBOutlet var txt_userTracker_email: UITextField!
    
    @IBOutlet weak var s_coolant: UISwitch!
    @IBOutlet weak var s_engineIdle: UISwitch!
    @IBOutlet weak var s_engineHealth: UISwitch!
    @IBOutlet var assetSingleSelectTableView: AssetSingleSelectTableView! {
        didSet {
            assetSingleSelectTableView.parentVC = self
        }
    }
    
    var changeFlag: Bool = false
    var trackerList: [TrackerModel] = []
    var selectedTracker: TrackerModel? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.panGestureRecognizer.delaysTouchesBegan = true
        self.scrollView.delegate = self
        
        SetAlarmViewController.instance = self
        
        table_handler.image = table_handler.image?.withRenderingMode(.alwaysTemplate)
        table_handler.tintColor = UIColor.gray
        
        initUI()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topView.frame.origin.y = scrollView.contentOffset.y
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        initialize_comps()
        
        if Global.shared.AllTrackerList.count > 0 {
            self.trackerList = Global.shared.AllTrackerList
            for tracker in self.trackerList {
                if selectedTracker == nil, Global.shared.selectedTrackerIds.contains(tracker._id) {
                    tracker.isSelected = true
                    selectedTracker = tracker
                } else {
                    tracker.isSelected = false
                }
            }
            
            if selectedTracker == nil {
                selectedTracker = trackerList.first
            }
            
            setSelectedTracker(tracker: selectedTracker)
        } else {
            loadAllDrivers()
        }
        
        setSwitchHeight()
        self.indicator.alpha = 0
    }
    
    func initUI() {
        self.bottomTableView.layer.borderColor = UIColor.gray.cgColor
        self.bottomTableView.layer.borderWidth = 0.5
        self.bottomTableView.layer.cornerRadius = 20.0
        self.bottomTableView.backgroundColor = UIColor(hexInt: 0xFDE5F3)
        self.bottomTableView.layer.masksToBounds = false
    }
    
    func setBottomTableData() {
        self.assetSingleSelectTableView.setData(self.trackerList)
        self.assetSingleSelectTableView.reloadData()
        self.tableViewHC.constant = self.assetSingleSelectTableView.getHeight()
    }
    
    func setSwitchHeight() {
        let scaleY = 0.7
        let scaleX = 0.7

        s_speedingAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_harshTurnAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_harshAcceAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_harshDeceAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_tamperAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_geoFenceAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_emailAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_engineOnAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_engineOffAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_alertSoundAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_vibrationAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_textAlertAlarmStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_airplaneModeStatus.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_coolant.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_engineIdle.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
        s_engineHealth.transform = CGAffineTransform(scaleX: CGFloat(scaleX), y: CGFloat(scaleY))
    }
    
    @IBAction func OnSetAlarmButtonClick(_ sender: Any) {
        if !changeFlag { return }
        
        guard let selectedTracker = self.selectedTracker else {
            self.view.makeToast("Please choose vehicle")
            return
        }
        
        if ( s_emailAlarmStatus.isOn == true) && (txt_userTracker_email.text?.contains("@") == false){
            self.view.makeToast("Use valid email address.")
            return
        }
        
        // send alarm setting
        let reqInfo = URLManager.modify()
        let parameters: Parameters = [
            "id" : selectedTracker._id,
            "speedLimit" : txt_userTracker_speedLimit.text!,
            "harshTurn": "120",
            "harshAcceleration" : "1",
            "harshDeceleration" : "1",
            "email" : txt_userTracker_email.text!,
            "phoneNumber" : txt_textAlertPhoneNumber.text!,
            "airplaneMode" : s_airplaneModeStatus.isOn,
            "phoneAlarmStatus" : s_textAlertAlarmStatus.isOn,
            "speedingAlarmStatus" : s_speedingAlarmStatus.isOn,
            "harshTurnAlarmStatus": s_harshTurnAlarmStatus.isOn,
            "harshAcceAlarmStatus": s_harshAcceAlarmStatus.isOn,
            "harshDeceAlarmStatus": s_harshDeceAlarmStatus.isOn,
            "geoFenceAlarmStatus": s_geoFenceAlarmStatus.isOn,
            "tamperAlarmStatus": s_tamperAlarmStatus.isOn,
            "emailAlarmStatus": s_emailAlarmStatus.isOn,
            "accAlarmStatus": s_engineOnAlarmStatus.isOn,
            "stopAlarmStatus": s_engineOffAlarmStatus.isOn,
            "soundAlarmStatus": s_alertSoundAlarmStatus.isOn,
            "vibrationAlarmStatus": s_vibrationAlarmStatus.isOn,
            "coolantTempAlarmStatus": s_coolant.isOn,
            "engineIdleAlarmStatus": s_engineIdle.isOn,
            "engineAlarmStatus": s_engineHealth.isOn
        ]
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        //showIndicator()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString {
            dataResponse in
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            print(json)
            if(code == 200) {
                self.view.makeToast("Success")
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
  
    @objc func loadAllDrivers() {
       self.view.endEditing(true)
       
       if URLManager.isConnectedToInternet == false {
           print("Yes! internet is unavailable.")
           self.view.makeToast("Weak cell phone signal is detected!".localized())
           return
       }
       
       let reqInfo = URLManager.assets()
       
       let parameters: Parameters = [:]
       
       let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]
       
       if Global.shared.AllTrackerList.count == 0 {
           self.showLoader()
       }
       
       let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
       
       request.responseString { dataResponse in
           
           self.hideLoader()
           
           if(dataResponse.response == nil || dataResponse.value == nil) {
               self.view.makeToast("server connect error".localized())
               return
           }
           
           let code = dataResponse.response!.statusCode
           
           let json = JSON.init(parseJSON: dataResponse.value!)
           
           if(code == 200) {
               let items = json["items"]
               let newTrackerList = items.arrayValue.map({ TrackerModel.parseJSON($0) })
               let isPhoneTracking = Defaults[.phoneTracking] ?? false
               
               self.trackerList.removeAll()
               self.selectedTracker = nil
               
               for tracker in newTrackerList {
                   if tracker.lat == 0.0, tracker.lng == 0.0 {
                       continue
                   }
                   if abs(tracker.lat) > 90.0 || abs(tracker.lng) > 180 {
                       continue
                   }
                   if !isPhoneTracking, tracker.spectrumId == Global.shared.username {
                       continue
                   }
                   
                   if self.selectedTracker == nil, Global.shared.selectedTrackerIds.contains(tracker._id) {
                       tracker.isSelected = true
                       self.selectedTracker = tracker
                   } else {
                       tracker.isSelected = false
                   }
               }
               
               if self.selectedTracker == nil {
                   self.selectedTracker = self.trackerList.first
               }
               
               self.setSelectedTracker(tracker: self.selectedTracker)
           } else {
               let error = ErrorModel.parseJSON(json)
               self.view.makeToast(error.message)
           }
       }
    }

    override func setResult(_ result: Any, from id: String, sender: Any? = nil) {
        if id == "AssetSingleSelectTableViewCell-selectedItem" {
            let tracker = result as? TrackerModel
            setSelectedTracker(tracker: tracker)
        }
    }
    
    func setSelectedTracker(tracker: TrackerModel?) {
        guard let _tracker = tracker else { return }
        
        for tracker in self.trackerList {
            if tracker._id == _tracker._id {
                tracker.isSelected = true
                self.selectedTracker = tracker
            } else {
                tracker.isSelected = false
            }
        }
        
        self.setBottomTableData()
        requestAlarmData()
    }

    func requestAlarmData() {
        guard let selectedTracker = self.selectedTracker else { return }
        
        initialize_comps()

        let trackerId = selectedTracker._id
        let reqInfo = URLManager.alarm(trackerId)

        let parameters: Parameters = [:]
        let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]

        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)

        request.responseString {
            dataResponse in

            print(dataResponse)

            if(dataResponse.data == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }

            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let data : AlarmModel = AlarmModel.parseJSON(json)
                self.loadAlarmValues(values: data)
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    func loadAlarmValues(values : AlarmModel) {
        txt_userTracker_speedLimit.text = values.speedLimit
        txt_userTracker_email.text = values.email
        txt_textAlertPhoneNumber.text = values.phoneNumber

        s_speedingAlarmStatus.isOn = values.speedingAlarmStatus
        s_harshTurnAlarmStatus.isOn = values.harshTurnAlarmStatus
        s_harshAcceAlarmStatus.isOn = values.harshAcceAlarmStatus
        s_harshDeceAlarmStatus.isOn = values.harshDeceAlarmStatus
        s_tamperAlarmStatus.isOn = values.tamperAlarmStatus
        s_geoFenceAlarmStatus.isOn = values.geoFenceAlarmStatus
        s_emailAlarmStatus.isOn = values.emailAlarmStatus
        s_engineOnAlarmStatus.isOn = values.engineAlarmStatus
        s_engineOffAlarmStatus.isOn = values.stopAlarmStatus
        s_alertSoundAlarmStatus.isOn = values.soundAlarmStatus
        s_vibrationAlarmStatus.isOn = values.vibrationAlarmStatus
        s_textAlertAlarmStatus.isOn = values.phoneAlarmStatus
        s_airplaneModeStatus.isOn = values.airplaneModeStatus
        s_coolant.isOn = values.coolantAlarmStatus
        print("s_coolant:",s_coolant.isOn)
        s_engineIdle.isOn = values.engineIdleAlarmStatus
        print("s_engineIdle:",s_engineIdle.isOn)
        s_engineHealth.isOn = values.engineHealthAlarmStatus
        print("s_engineHealth:",s_engineHealth.isOn)
        changeFlag = true
    }
    
    func initialize_comps() {
        changeFlag = false
        txt_userTracker_speedLimit.text = ("")
        txt_userTracker_email.text = ("")
        txt_textAlertPhoneNumber.text = ("")
        
        s_speedingAlarmStatus.isOn = false
        s_harshTurnAlarmStatus.isOn = (false)
        s_harshAcceAlarmStatus.isOn = (false)
        s_harshDeceAlarmStatus.isOn = (false)
        s_tamperAlarmStatus.isOn = (false)
        s_geoFenceAlarmStatus.isOn = (false)
        s_engineOffAlarmStatus.isOn = (false)
        s_emailAlarmStatus.isOn = (false)
        s_textAlertAlarmStatus.isOn = (false)
        s_airplaneModeStatus.isOn = (false)
        s_engineOnAlarmStatus.isOn = (false)
        s_vibrationAlarmStatus.isOn = (false)
        s_alertSoundAlarmStatus.isOn = (false)
        s_coolant.isOn = (false)
        s_engineIdle.isOn = (false)
        s_engineHealth.isOn = (false)
    }
    
    @IBAction func onCoolant(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    @IBAction func onEngineHealth(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    @IBAction func onEngineIdle(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
}

extension SetAlarmViewController {
    @IBAction func onSpeedingChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onHarshTurnChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onHarshAcceChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onHarshDeceChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onTamperChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onGeofenceChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onTextAlertChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onEmailSChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onEngineOnChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onAlertSoundChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onEngineOffChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onAirplaneModeChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onVibrationChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onPhoneNumberChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onSpeedLimitChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func onEmailTChange(_ sender: Any) {
        self.OnSetAlarmButtonClick(self)
    }
    
    @IBAction func actionAlertSound(_ sender: UISwitch) {
        //Defaults[.alertSound] = sender.isOn
    }
    
    @IBAction func actionVibration(_ sender: UISwitch) {
        //Defaults[.vibration] = sender.isOn
    }
}
