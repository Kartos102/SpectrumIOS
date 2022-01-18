//
//  MainContainerViewController.swift
//  spectrum_tracker
//
//  Created by Admin on 2/20/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import StoreKit
import SwiftyJSON
import SCLAlertView
import Alamofire
import Firebase
import MBRadioCheckboxButton

class MainContainerViewController: ViewControllerWaitingResult {
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "MainContainerViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    static var instance: MainContainerViewController!
    
    @IBAction func onSwitchGetPhone(_ sender: Any) {
        Defaults[.phoneTracking] = switchGetPhone.isOn
        if switchGetPhone.isOn {
            setPhoneTracker()
            locationManager2.startUpdatingLocation()
        }else {
            locationManager2.stopUpdatingLocation()
        }
    }
    
    @IBOutlet weak var switchGetPhone: UISwitch!
    @IBAction func onSwitchKeepScreen(_ sender: Any) {
        Defaults[.sautolock] = switchKeepScreen.isOn
        UIApplication.shared.isIdleTimerDisabled = Defaults[.sautolock] ?? false
    }
    @IBOutlet weak var switchKeepScreen: UISwitch!
    @IBOutlet weak var topbar_view: UIView!
    @IBOutlet var lineView: UIView!
    @IBOutlet var mainContainerView: UIView!
    @IBOutlet var backView: UIView!
    @IBOutlet var menuView: UIView!
    @IBOutlet var icon_activate: UIImageView!
    @IBOutlet var icon_alarms: UIImageView!
    @IBOutlet var icon_monitor: UIImageView!
    @IBOutlet var icon_geofence: UIImageView!
    @IBOutlet var icon_reports: UIImageView!
    @IBOutlet var icon_order_service: UIImageView!
    @IBOutlet var icon_driver_info: UIImageView!
    @IBOutlet var icon_family: UIImageView!
    @IBOutlet var icon_share: UIImageView!
    @IBOutlet var icon_order_tracker: UIImageView!
    @IBOutlet var icon_replay: UIImageView!
    @IBOutlet var icon_faq: UIImageView!
    @IBOutlet var icon_contact: UIImageView!
    @IBOutlet weak var overlayContainerView: UIView!
    
    @IBOutlet weak var btn_miles: RadioButton!
    @IBOutlet weak var btn_kilometer: RadioButton!
    @IBAction func onKilometer(_ sender: Any) {
        Defaults[.distanceUnit] = "km"
    }
    @IBAction func onMiles(_ sender: Any) {
        Defaults[.distanceUnit] = "miles"
    }
    @IBOutlet weak var icon_logout: UIImageView!
    @IBOutlet weak var label_reports: UILabel!
    @IBOutlet weak var label_replay: UILabel!
    @IBOutlet weak var label_monitor: UILabel!
    @IBOutlet weak var label_add_device: UILabel!
    @IBOutlet weak var icon_add_device: UIImageView!
    var currentSelectedVC: UIViewController? = nil
    var overlayNavVC: UINavigationController? = nil
    
    var totalUnreadCount = 0
    
    func logout_func()
    {
        
        if URLManager.isConnectedToInternet == false {
            self.view.makeToast("Weak cell phone signal is detected!")
            return
        }
        
        let reqInfo = URLManager.authLogout()
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            //print(dataResponse.response)
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    @IBAction func onLogout(_ sender: Any) {
        let appearance = SCLAlertView.SCLAppearance(showCloseButton:false, showCircularIcon: true)
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("Yes") {
            alertView.closeLeft()
            Defaults[.remember] = true
            Defaults[.isLoggedIn] = false
            Global.shared.csrfToken = ""
            self.logout_func()
            self.dismiss(animated: true, completion: nil)
        }
        alertView.addButton("No") {
            alertView.closeLeft()
            Defaults[.remember] = false
            Defaults[.isLoggedIn] = false
            Global.shared.csrfToken = ""
            self.logout_func()
            self.dismiss(animated: true, completion: nil)
            
        }
        alertView.addButton("Cancel") {
            alertView.closeLeft()
            self.hideMenuView(self)
        }
        alertView.showInfo("Log Out",subTitle: "Remember account on this device?",colorStyle:0xec9d20,animationStyle:.topToBottom)
//        Defaults[.isLoggedIn] = false
//        Global.shared.csrfToken = ""
//        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onOrderTracker(_ sender: Any) {
        let controller = OrderTrackerViewController.getNewInstance()
        setPage(controller: controller)
        icon_order_tracker.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onChat(_ sender: Any) {
        topbar_view.backgroundColor = UIColor.white
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatRoomListVC") as! ChatRoomListVC
        setPage(controller: vc)
        hideMenuView(self)
    }
    @IBAction func onContactUs(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/contact.html") else {return}
        UIApplication.shared.open(url)
        resetAllViews()
        icon_contact.tintColor = selectedColor
    }
    @IBAction func onFaq(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/faq.html") else {return}
        UIApplication.shared.open(url)
        resetAllViews()
        icon_faq.tintColor = selectedColor
    }
    @IBAction func onActicate(_ sender: Any) {
        hideOverlay()
        topbar_view.backgroundColor = UIColor(hexString: "#007aff")
        let controller = ActivateTrackerViewController.getNewInstance()
        setPage(controller: controller)
        icon_add_device.tintColor = selectedColor
        label_add_device.textColor = selectedColor
    }
    
    @IBAction func onFamily(_ sender: Any) {
        let controller = FamilyViewController.getNewInstance()
        setPage(controller: controller)
        icon_family.tintColor = selectedColor
        hideMenuView(self)
    }
    @IBAction func onShare(_ sender: Any) {
        let controller = ShareTrackerViewController.getNewInstance()
        setPage(controller: controller)
        icon_share.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onDriverInfo(_ sender: Any) {
        let controller = UpdateDriverInfoViewController.getNewInstance()
        setPage(controller: controller)
        icon_driver_info.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onGeofence(_ sender: Any) {
        let controller = GeofenceViewController.getNewInstance()
        setPage(controller: controller)
        icon_geofence.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onService(_ sender: Any) {
        topbar_view.backgroundColor = UIColor(hexString: "#007aff")
        let controller = OrderServiceViewController.getNewInstance()
        setPage(controller: controller)
        icon_order_service.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onAlarms(_ sender: Any) {
        let controller = AlarmsViewController.getNewInstance()
        setPage(controller: controller)
        hideMenuView(self)
    }
    
    @IBAction func onReports(_ sender: Any) {
        hideOverlay()
        topbar_view.backgroundColor = UIColor.white
        let controller = ReportsViewController.getNewInstance()
        setPage(controller: controller)
        icon_reports.tintColor = selectedColor
        label_reports.textColor = selectedColor
    }
    
    @IBAction func onSetAlarms(_ sender: Any) {
        let controller = SetAlarmViewController.getNewInstance()
        setPage(controller: controller)
        icon_alarms.tintColor = selectedColor
        hideMenuView(self)
    }
    
    @IBAction func onMonitor(_ sender: Any) {
        topbar_view.backgroundColor = UIColor.white
        if !overlayContainerView.isHidden {
            hideOverlay()
        } else {
            let controller = MonitorViewController.getNewInstance()
            setPage(controller: controller)
            icon_monitor.tintColor = selectedColor
            label_monitor.textColor = selectedColor
        }
    }
    
    @IBAction func onReplay(_ sender: Any) {
        hideOverlay()
        topbar_view.backgroundColor = UIColor.white
        let controller = ReplayViewController.getNewInstance()
        setPage(controller: controller)
        icon_replay.tintColor = selectedColor
        label_replay.textColor = selectedColor
    }
    
    @IBAction func showMenuView(_ sender: Any) {
        hideOverlay()
        topbar_view.backgroundColor = UIColor(hexString: "#007aff")
        self.backView.isHidden = false
        self.menuView.isHidden = false
    }
    
    @IBAction func hideMenuView(_ sender: Any) {
        self.backView.isHidden = true
        self.menuView.isHidden = true
    }
    
    let normalColor: UIColor = UIColor(hexString: "#777777")
    let whiteColor: UIColor = UIColor(hexString: "#f7f7f7")
    let selectedColor: UIColor = UIColor(hexString: "#008efb")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        resetAllViews()
        switchKeepScreen.isOn = Defaults[.sautolock] ?? false
        switchGetPhone.isOn = Defaults[.phoneTracking] ?? false
        let distanceUnit = Defaults[.distanceUnit] ?? "miles"
        if distanceUnit == "km" {
            btn_miles.isOn = false
            btn_kilometer.isOn = true
        } else {
            btn_miles.isOn = true
            btn_kilometer.isOn = false
        }
        self.showRateDialog()
        MainContainerViewController.instance = self
        
        icon_monitor.image = icon_monitor.image?.withRenderingMode(.alwaysTemplate)
        icon_monitor.tintColor = selectedColor
        label_monitor.textColor = selectedColor
        
        self.lineView.layer.shadowColor = selectedColor.cgColor
        self.lineView.layer.shadowOffset = CGSize(width:5.0,height:5.0)
        self.lineView.layer.shadowOpacity = 0.9
        self.lineView.layer.shadowRadius = 6.0
        self.lineView.layer.masksToBounds = false
        
        self.backView.isHidden = false
        
        self.currentSelectedVC = MonitorViewController.instance
        
        self.startInitChatting()
        
        if let _ = Defaults[.fcmToken] {
            self.uploadFCMToken()
            
            Messaging.messaging().subscribe(toTopic: "TestMessage")
        }
    }
    
    func showRateDialog()
    {
        
        if URLManager.isConnectedToInternet == false {
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
        }
        
        let reqInfo = URLManager.getUserInfo()
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            //print(dataResponse.response)
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                Global.shared.app_user = json
                
                if Global.shared.app_user["email"].stringValue == "" {
                    Global.shared.app_user["email"] = JSON(stringLiteral: Defaults[.username] ?? "")
                }
                
                let review_number = json["appReview"].intValue
                var runningCount = UserDefaults.standard.integer(forKey: "RunningCount")
                runningCount += 1
                UserDefaults.standard.set(runningCount, forKey: "RunningCount")
                UserDefaults.standard.synchronize()
                
                if runningCount % 5 == 0 && review_number <= 2{
                    self.showReview()
                }
//                if json["phoneTracker"] == JSON.null || !json["phoneTracker"].boolValue {
//                    self.setPhoneTracker()
//                }
                print("review_number:\(review_number)")
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    func setPhoneTracker() {
        
        let reqInfo = URLManager.registerPhoneTracker()
        
        let parameters: Parameters = [
            "reportingId" : Global.shared.app_user["email"].stringValue,
            "userId" : Global.shared.app_user["_id"].stringValue
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: JSONEncoding.default , headers: headers)
        
        request.responseString {
            dataResponse in
            
            if(dataResponse.data == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            if(code == 201) {
                self.setAsset(json["_id"].stringValue)
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
       
    }
    func setAsset(_ id : String) {
        
        let reqInfo = URLManager.createPhoneAsset()
        
        let parameters: Parameters = [
            "trackerId" : id,
            "name" : Global.shared.app_user["firstName"].string ?? "driver",
            "spectrumId" : Global.shared.app_user["email"].string ?? "phone",
            "driverName" : Global.shared.app_user["firstName"].string ?? "driver",
            "userId" : Global.shared.app_user["_id"].stringValue
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: JSONEncoding.default , headers: headers)
        
        request.responseString {
            dataResponse in
            
            if(dataResponse.data == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            if(code == 200) {
                self.setUserPhoneTracker()
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
        
    }
    func setUserPhoneTracker() {
        let reqInfo = URLManager.setPhoneTrackerFlag()
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: JSONEncoding.default , headers: headers)
        
        request.responseString {
            dataResponse in
            
            if(dataResponse.data == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            if(code == 200) {
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    func addReview()
    {
        
        if URLManager.isConnectedToInternet == false {
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
        }
        
        let reqInfo = URLManager.addReviewNumber(Global.shared.username)
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            //print(dataResponse.response)
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.view.makeToast("Success!")
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    func showReview() {
        let appearance = SCLAlertView.SCLAppearance(showCloseButton:false, showCircularIcon: true)
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("REMIND ME LATER".localized()) {
            alertView.closeLeft()
        }
        alertView.addButton("NO THANKS".localized()) {
            alertView.closeLeft()
        }
        alertView.addButton("RATE IT!".localized()) {
            alertView.closeLeft()
            self.addReview()
        }
        alertView.showInfo("Rate Spectrum Tracker".localized(),subTitle: "If you enjoy using Spectrum Tracker, please take a moment to rate it. Thanks for your support!".localized(),colorStyle:0xec9d20,animationStyle:.topToBottom)
    }
    func setPage(controller: UIViewController) {
        mainContainerView.subviews.forEach { $0.removeFromSuperview() }

        if !children.contains(controller) {
            addChild(controller)
        }
        
        controller.willMove(toParent: self)
        controller.view.frame = mainContainerView.bounds
        mainContainerView.addSubview(controller.view)
        mainContainerView.bringSubviewToFront(controller.view)
        controller.didMove(toParent: self)
        
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        controller.view.topAnchor.constraint(equalTo: mainContainerView.topAnchor).isActive = true
        controller.view.leadingAnchor.constraint(equalTo: mainContainerView.leadingAnchor).isActive = true
        controller.view.trailingAnchor.constraint(equalTo: mainContainerView.trailingAnchor).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: mainContainerView.bottomAnchor).isActive = true
        resetAllViews()
        
        self.currentSelectedVC = controller
        mainContainerView.layoutIfNeeded()
    }
    
    func resetAllViews() {
        icon_monitor.image = icon_monitor.image?.withRenderingMode(.alwaysTemplate)
        icon_monitor.tintColor = normalColor
        
        icon_contact.image = icon_contact.image?.withRenderingMode(.alwaysTemplate)
        icon_contact.tintColor = whiteColor
        
        icon_logout.image = icon_logout.image?.withRenderingMode(.alwaysTemplate)
        icon_logout.tintColor = whiteColor
        
        
        icon_replay.image = icon_replay.image?.withRenderingMode(.alwaysTemplate)
        icon_replay.tintColor = normalColor
        
        icon_reports.image = icon_reports.image?.withRenderingMode(.alwaysTemplate)
        icon_reports.tintColor = normalColor
        
        
        icon_add_device.image = icon_add_device.image?.withRenderingMode(.alwaysTemplate)
        icon_add_device.tintColor = normalColor
        
        label_add_device.textColor = normalColor
        label_replay.textColor = normalColor
        label_reports.textColor = normalColor
        label_monitor.textColor = normalColor
        
        
        icon_share.image = icon_share.image?.withRenderingMode(.alwaysTemplate)
        icon_share.tintColor = whiteColor
        
        icon_family.image = icon_family.image?.withRenderingMode(.alwaysTemplate)
        icon_family.tintColor = whiteColor
        
        icon_alarms.image = icon_alarms.image?.withRenderingMode(.alwaysTemplate)
        icon_alarms.tintColor = whiteColor
        
        icon_geofence.image = icon_geofence.image?.withRenderingMode(.alwaysTemplate)
        icon_geofence.tintColor = whiteColor
        
        icon_order_service.image = icon_order_service.image?.withRenderingMode(.alwaysTemplate)
        icon_order_service.tintColor = whiteColor
        
        icon_driver_info.image = icon_driver_info.image?.withRenderingMode(.alwaysTemplate)
        icon_driver_info.tintColor = whiteColor
    }
    
    func showOverlay(vc: UIViewController) {
        self.overlayNavVC?.setViewControllers([vc], animated: false)
        self.overlayContainerView.isHidden = false
    }
    
    func hideOverlay() {
        overlayContainerView.isHidden = true
        overlayNavVC?.viewControllers.removeAll()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueOverlay" {
            self.overlayNavVC = segue.destination as? UINavigationController
        }
        
        super.prepare(for: segue, sender: sender)
    }
    
    func uploadFCMToken() {
        if URLManager.isConnectedToInternet == false {
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
        }
        
        let reqInfo = URLManager.postFirebaseToken()
        
        let parameters: Parameters = [
            "email": Defaults[.username] ?? "",
            "pushToken": Defaults[.fcmToken] ?? ""
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
        }
    }
}

extension MainContainerViewController: ChannelManagerDelegate {
    func didGetPublicChannelList() {
        
    }
    
    func didGetPrivateChannelList() {
//        if Global.shared.AllAssetList.count == 0 {
//            DispatchQueue.global().async {
//                while Global.shared.AllAssetList.count == 0 {
//                    Thread.sleep(forTimeInterval: 0.2)
//                }
//                
//                DispatchQueue.main.async {
//                    self.initializeAllChattingChannels()
//                }
//            }
//        } else {
//            self.initializeAllChattingChannels()
//        }
        checkChatInvitation()
    }
    
    func startInitChatting() {
        MessagingManager.shared.loginWithUsername(username: Global.shared.username) { (result, error) in
            if error == nil, result {
                
            }
        }
        ChannelManager.sharedManager.delegate = self
    }
    
    func initializeAllChattingChannels() {
        for tracker in Global.shared.AllTrackerList {
            let myId = Global.shared.username
            let partnerId = tracker.spectrumId
            
            if myId == partnerId || tracker.trackerModel.lowercased() != "phone" {
                continue
            }
            
            let channelName = ChannelManager.sharedManager.getChannelName(partnerId: partnerId)
            ChannelManager.sharedManager.joinOrCreatePrivateChannelWith(name: channelName, partnerId: partnerId)
        }
    }
    
    func onUpdatedUnreadCount() {
        var unreadCount = ChannelManager.sharedManager.unreadCountMap.values.reduce(0, +)
        if totalUnreadCount < unreadCount, !(overlayNavVC?.viewControllers.first is ChatRoomVC) {
            
        }
        
        self.totalUnreadCount = unreadCount
        MonitorViewController.instance.updateUnreadCount()
        
//        if let vc = overlayNavVC?.viewControllers.first as? ChatRoomListVC {
//            vc.updateList()
//        }
    }
    
    func checkChatInvitation() {
        if let chatRoomListVC = overlayNavVC?.viewControllers.first as? ChatRoomListVC {
            chatRoomListVC.updateList()
        } else if let monitorVC = self.currentSelectedVC as? MonitorViewController {
            monitorVC.checkChatInvitation()
        }
    }
}
