//
//  ActivateTrackerViewController.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import ActiveLabel
import DropDown
import SCLAlertView
import LGButton

class ActivateTrackerViewController: BaseViewController {

    @IBOutlet var txtTrackerId: UITextField!
    @IBOutlet var txtPlateNumber: UITextField!
    @IBOutlet var txtDriverName: UITextField!
    @IBOutlet var topStackView: UIStackView!
    @IBOutlet var labelView: ActiveLabel!
    @IBOutlet var txtDataPlan: UILabel!
    @IBOutlet weak var planInfoButtonContainerView: UIView!
    @IBOutlet weak var txtCategory: UILabel!
    @IBOutlet weak var txtAutoRenew: UILabel!
    @IBOutlet var txtCVCode: UITextField!
    @IBOutlet var txtCardExpiry: UITextField!
    @IBOutlet var txtCardNumber: UITextField!
    @IBOutlet var txtCardName: UITextField!
    @IBOutlet weak var txtCardStreet: UITextField!
    @IBOutlet weak var txtCardCity: UITextField!
    @IBOutlet weak var txtCardState: UITextField!
    @IBOutlet weak var txtCardZip: UITextField!
    @IBOutlet weak var txtCardCountry: UILabel!
    @IBOutlet var btnPlan: UIButton!
    @IBOutlet weak var btnCategory: UIButton!
    @IBOutlet weak var btnAutoRenew: UIButton!
    @IBOutlet weak var btnCountry: UIButton!
    
    @IBOutlet weak var btn_wifi_plan: UIButton!
    @IBOutlet weak var last4View: UIStackView!
    @IBOutlet weak var newCardView: UIStackView!
    @IBAction func onChangeMethod(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            if self.isCardExist == false {
                SweetAlert().showAlert("", subTitle: "Sorry, you don't have any card now.", style: AlertStyle.error)
                self.switchMethod.selectedSegmentIndex = 1
            }
            last4View.isHidden = false
            newCardView.isHidden = true
            self.paymentType = "token"
        }else {
            newCardView.isHidden = false
            last4View.isHidden = true
            self.paymentType = "card"
        }
    }
    @IBOutlet weak var switchMethod: UISegmentedControl!
    @IBOutlet weak var txtLast4digits: CustomTextField!
    @IBOutlet weak var txtWifiPlan: UILabel!
    var selectedTracker: TrackerModel? = nil
    @IBOutlet weak var btn_activate: LGButton!
    
    var dataPlanDropDown: DropDown!
    var wifiPlanDropDown: DropDown!
    var categoryDropDown: DropDown!
    var autoRenewDropDown: DropDown!
    var coutriesDropDown: DropDown!
    
    var planList: [[String: [String]]] = []
    var planKeys: [String] = []
    var wifiPlanKeys: [String] = []
    var selectedPlanIndex = 0
    var selectedWifiPlanIndex = 0
    var total_amount = 0.0
    var tracking_amount = 0.0
    var wifi_amount = 0.0
    var isCardExist = true
    var user_id: String!
    var email: String!
    var paymentType = "card"
    
    @IBAction func onSpectrumIdChanged(_ sender: Any) {
        if txtTrackerId.text == "" {
            self.txtDataPlan.text = ""
            return
        }
        dataPlanDropDown.dataSource = [String]()
        self.txtDataPlan.text = ""
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
        }
        var trackerId:String = txtTrackerId.text ?? ""
        let regex = try! NSRegularExpression(pattern: "/(^\\s+|\\s+$)/", options: .caseInsensitive)
        let range = NSMakeRange(0, trackerId.count)
        trackerId = regex.stringByReplacingMatches(in: trackerId, options: [], range: range, withTemplate: "").uppercased()
        trackerId = trackerId.replacingOccurrences(of: " ", with: "")
//        let reqInfo = URLManager.getTrackerBySpectrumId(trackerId)
        let reqInfo = URLManager.getTrackerModelBySpectrumId(trackerId)
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            if dataResponse.value == "" {return}
            let json = JSON.init(parseJSON: dataResponse.value!)
            print(json)
            if(code == 200) {
                let plansMobile = json["plansMobile"].arrayValue.map({ $0.dictionaryValue })
                let plansWifi = json["LTEPlan"].arrayValue
                self.planList.removeAll()
                self.planKeys.removeAll()
                self.wifiPlanKeys.removeAll()
                
                for plan in plansMobile {
                    let _plan = plan.mapValues({ value -> [String] in
                        return value.arrayValue.map({ $0.stringValue })
                    })
                    self.planList.append(_plan)
                }
                
                var dropDownDataSource: [String] = []
                for plan in self.planList {
                    let keys = plan.keys.map({ String($0) })
                    if keys.count > 0 {
                        let key = keys[0]
                        let values = plan[key]
                        
                        self.planKeys.append(key)
                        dropDownDataSource.append(values?.first ?? "")
                    }
                }
                
                if self.planList.count == 0 {
                    self.planInfoButtonContainerView.isHidden = true
                } else {
                    self.planInfoButtonContainerView.isHidden = false
                }
                
                self.dataPlanDropDown.dataSource = dropDownDataSource
                self.txtDataPlan.text = self.dataPlanDropDown.dataSource.first
                self.selectedPlanIndex = 0
                
                var wifiDropDownDataSource: [String] = []
                for plan in plansWifi {
                    let plan_value = plan.dictionaryValue
                    let keys = plan_value.keys.map({ String($0) })
                    if keys.count > 0 {
                        let key = keys[0]
                        self.wifiPlanKeys.append(key)
                        wifiDropDownDataSource.append(plan[key].stringValue)
                    }
                }
                self.wifiPlanDropDown.dataSource = wifiDropDownDataSource
                self.txtWifiPlan.text = self.wifiPlanDropDown.dataSource.first
                self.selectedWifiPlanIndex = 0
            }
        }
    }
    @IBAction func onPlanSelect(_ sender: Any) {
        if dataPlanDropDown.isHidden {
            dataPlanDropDown.show()
        }
        else {
            dataPlanDropDown.hide()
        }
    }
    
    @IBAction func onWifiPlanSelect(_ sender: Any) {
        if wifiPlanDropDown.isHidden {
            wifiPlanDropDown.show()
        }else {
            wifiPlanDropDown.hide()
        }
    }
    @IBAction func onCategorySelect(_ sender: Any) {
        categoryDropDown.show()
    }
    
    @IBAction func onAutoRenewSelect(_ sender: Any) {
        autoRenewDropDown.show()
    }
    
    @IBAction func onCountrySelect(_ sender: Any) {
        coutriesDropDown.show()
    }
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "ActivateTrackerViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    func loadLableView() {
        let customType1 = ActiveType.custom(pattern: "\\sSPECTRUMID\\b")
        let customType2 = ActiveType.custom(pattern: "\\sCLICK HERE\\s")
        let customType3 = ActiveType.custom(pattern: "\\sCLICK HERE.")
        labelView.enabledTypes.append(customType1)
        labelView.enabledTypes.append(customType2)
        labelView.enabledTypes.append(customType3)
        labelView.customize { (labelView) in
            labelView.font = labelView.font.withSize(11.0)
            let text:String = "1. Put the SPECTRUMID into the box below.\n\n" +
                "2. For OBD tracker, plug the tracker into the OBD II port. CLICK HERE to locate OBD port.\nFor portable tracker, fully charge your device for 3 hours.\n\n" +
                "3. Drive your car for 5-10 minutes to get GPS location. Portable one can take up to 10 minutes when it is used the first time.\n\n" +
                "4. Demo video here CLICK HERE.\n"
            labelView.text = text
            labelView.numberOfLines = 50
            labelView.customColor[customType1] = UIColor(hexInt: 0x0761a9)
            labelView.customColor[customType2] = UIColor(hexInt: 0x0761a9)
            labelView.customColor[customType3] = UIColor(hexInt: 0x0761a9)
            labelView.handleCustomTap(for: customType2) { (element) in
                print(element)
                guard let url = URL(string: "https://www.carmd.com/wp/locating-the-obd2-port-or-dlc-locator") else {return}
                UIApplication.shared.open(url)
            }
            
            
            labelView.handleCustomTap(for: customType3) { (element) in
                print(element)
                guard let url = URL(string: "https://spectrumtracking.com/video.html") else {return}
                UIApplication.shared.open(url)
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        loadLableView()
        doAuth()
        initDropDown()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        planInfoButtonContainerView.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    func doAuth() {
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
        }
        
        let reqInfo = URLManager.doAuth()
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            :
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.user_id = json["userId"].stringValue
                self.email = json["email"].stringValue
                if json["last4Digits"].exists() && json["exp_date"].exists() {
                    self.isCardExist = true
                    self.txtLast4digits.text = json["last4Digits"].stringValue
                    self.paymentType = "token"
                }else {
                    self.isCardExist = false
                    self.switchMethod.selectedSegmentIndex = 1
                    self.paymentType = "card"
                }
            }
        }
    }
    func initDropDown() {
        dataPlanDropDown = DropDown()
        dataPlanDropDown.dataSource = [String]()
        dataPlanDropDown.anchorView = btnPlan
        dataPlanDropDown.backgroundColor = UIColor.groupTableViewBackground
        dataPlanDropDown.bottomOffset = CGPoint(x: 0, y:(dataPlanDropDown.anchorView?.plainView.bounds.height)!)
        dataPlanDropDown.direction = .bottom
        dataPlanDropDown.selectionAction = { (index: Int, title: String) in
            self.txtDataPlan.text = title
            self.selectedPlanIndex = index
            let wifi_text = self.txtWifiPlan.text ?? ""
            self.wifi_amount = (wifi_text.split(separator: "$").count > 1) ? Double(wifi_text.split(separator: "$")[1]) as! Double : 0.0
            self.tracking_amount = (title.split(separator: "$").count > 1) ? Double(title.split(separator: "$")[1]) as! Double : 0.0
            self.total_amount = self.wifi_amount + self.tracking_amount
            if self.total_amount == 0.0 {
                self.btn_activate.titleString = "ACTIVATE"
            }else {
                self.btn_activate.titleString = "ACTIVATE $" + String(self.total_amount)
            }
        }
        
        wifiPlanDropDown = DropDown()
        wifiPlanDropDown.dataSource = [String]()
        wifiPlanDropDown.anchorView = btn_wifi_plan
        wifiPlanDropDown.backgroundColor = UIColor.groupTableViewBackground
        wifiPlanDropDown.bottomOffset = CGPoint(x: 0, y:(wifiPlanDropDown.anchorView?.plainView.bounds.height)!)
        wifiPlanDropDown.direction = .bottom
        wifiPlanDropDown.selectionAction = { (index: Int, title: String) in
            self.txtWifiPlan.text = title
            self.selectedWifiPlanIndex = index
            let tracking_text = self.txtDataPlan.text ?? ""
            self.tracking_amount = (tracking_text.split(separator: "$").count > 1) ? Double(tracking_text.split(separator: "$")[1]) as! Double : 0.0
            self.wifi_amount = (title.split(separator: "$").count > 1) ? Double(title.split(separator: "$")[1]) as! Double : 0.0
            self.total_amount = self.wifi_amount + self.tracking_amount
            if self.total_amount == 0.0 {
                self.btn_activate.titleString = "ACTIVATE"
            }else {
                self.btn_activate.titleString = "ACTIVATE $" + String(self.total_amount)
            }
        }
        
        categoryDropDown = DropDown()
        categoryDropDown.dataSource = ["SUV", "Crossover", "Sedan", "Truck", "Hatchback", "Convertible", "Bus", "Semi-truck", "Box-truck", "Cargo-Van"]
        categoryDropDown.anchorView = btnCategory
        categoryDropDown.backgroundColor = UIColor.groupTableViewBackground
        categoryDropDown.bottomOffset = CGPoint(x: 0, y:(categoryDropDown.anchorView?.plainView.bounds.height)!)
        categoryDropDown.direction = .bottom
        categoryDropDown.selectionAction = { (index: Int, title: String) in
            self.txtCategory.text = title
            
        }
        self.txtCategory.text = categoryDropDown.dataSource.first
        
        autoRenewDropDown = DropDown()
        autoRenewDropDown.dataSource = ["Auto Renew".localized(), "No Auto Renew".localized()]
        autoRenewDropDown.anchorView = btnAutoRenew
        autoRenewDropDown.backgroundColor = UIColor.groupTableViewBackground
        autoRenewDropDown.bottomOffset = CGPoint(x: 0, y:(autoRenewDropDown.anchorView?.plainView.bounds.height)!)
        autoRenewDropDown.direction = .bottom
        autoRenewDropDown.selectionAction = { (index: Int, title: String) in
            self.txtAutoRenew.text = title
        }
        self.txtAutoRenew.text = autoRenewDropDown.dataSource.first
        
        coutriesDropDown = DropDown()
        coutriesDropDown.dataSource = countryList
        coutriesDropDown.anchorView = btnCountry
        coutriesDropDown.backgroundColor = UIColor.groupTableViewBackground
        coutriesDropDown.bottomOffset = CGPoint(x: 0, y:(coutriesDropDown.anchorView?.plainView.bounds.height)!)
        coutriesDropDown.direction = .bottom
        coutriesDropDown.selectionAction = { (index: Int, title: String) in
            self.txtCardCountry.text = title
        }
        self.txtCardCountry.text = coutriesDropDown.dataSource.first
    }
    
    @IBAction func onActivate(_ sender: Any) {
        //self.dismiss(animated: true, completion: nil)
        var trackerId:String = txtTrackerId.text ?? ""
        let driverName = txtDriverName.text ?? "driver"
        let card_holder_name = txtCardName.text ?? ""
        var cardNumber = txtCardNumber.text ?? ""
        let cardExpiry = txtCardExpiry.text ?? ""
        var cardCVV = txtCVCode.text ?? ""
        let cardStreet = txtCardStreet.text ?? ""
        let cardCity = txtCardCity.text ?? ""
        let cardState = txtCardState.text ?? ""
        let cardZip = txtCardZip.text ?? ""
        
        if cardExpiry.count != 4 {
            
            SweetAlert().showAlert("", subTitle: "expiration date format is wrong. Use mmyy. For example, if expiration date is December 2030, use 1230".localized(), style: AlertStyle.error)
            return
        }
        
        if trackerId  == "" {
            SweetAlert().showAlert("", subTitle: "please enter tracker ID".localized(), style: AlertStyle.error)
            return
        }
        
        if self.txtDataPlan.text  == "" {
            SweetAlert().showAlert("", subTitle: "please select Data Plan".localized(), style: AlertStyle.error)
            return
        }
        
       
        let regex = try! NSRegularExpression(pattern: "/(^\\s+|\\s+$)/", options: .caseInsensitive)
        let range = NSMakeRange(0, trackerId.count)
        trackerId = regex.stringByReplacingMatches(in: trackerId, options: [], range: range, withTemplate: "").uppercased()
        trackerId = trackerId.replacingOccurrences(of: " ", with: "")
        
        let regexCard = try! NSRegularExpression(pattern: "/\\s+/g", options: .caseInsensitive)
        let rangeNumber = NSMakeRange(0, cardNumber.count)
        let rangeCVV = NSMakeRange(0, cardCVV.count)
        cardNumber = regexCard.stringByReplacingMatches(in: cardNumber, options: [], range: rangeNumber, withTemplate: "").replacingOccurrences(of: " ", with: "")
        cardCVV = regexCard.stringByReplacingMatches(in: cardCVV, options: [], range: rangeCVV, withTemplate: "").replacingOccurrences(of: " ", with: "")
        if cardNumber  == "" && paymentType == "card" {
            SweetAlert().showAlert("", subTitle: "Please input card number".localized(), style: AlertStyle.error)
            return
        }
        let plateNumber = txtPlateNumber.text ?? trackerId
        let sendHtml = "Your tracking plan is " + self.txtDataPlan.text! + " Your wifi plan is " +  self.txtWifiPlan.text! + " Your total payment is $" + String(self.total_amount);
        
        var paymentItmes: [JSON] = []
        paymentItmes.append(JSON([
            "renew": txtAutoRenew.text == "Auto Renew".localized(),
            "trackPlan": txtDataPlan.text,
            "service": true,
            "trackerId": trackerId]
        ))
                        
        paymentItmes.append(JSON([
            "renew": txtAutoRenew.text == "Auto Renew".localized(),
            "service": true,
            "textPlan": txtWifiPlan.text,
            "trackerId": trackerId]
        ))
        
        self.view.endEditing(true)
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        let activateTrackerFormItem = ActivateTrackerFormModel(trackerId, plateNumber, driverName, card_holder_name, cardNumber, cardExpiry, cardCVV)
        activateTrackerFormItem.category = txtCategory.text ?? ""
        activateTrackerFormItem.isAutoRenew = txtAutoRenew.text == "Auto Renew".localized()
        activateTrackerFormItem.cardStreet = cardStreet
        activateTrackerFormItem.cardCity = cardCity
        activateTrackerFormItem.cardState = cardState
        activateTrackerFormItem.cardZip = cardZip
        activateTrackerFormItem.cardCountry = txtCardCountry.text ?? ""
        let reqInfo = URLManager.ordersPayment()
        var parameters: Parameters = [:]
        if paymentType == "Token" {
            parameters = [
                "paymentType": "token",
                "tractionType": "purchase",
                "currency_code": "USD",
                "productService": "service",
                "email": self.email,
                "auth": self.user_id,
                "items": JSON(paymentItmes).rawString() ?? "",
                "amount": self.total_amount,
                "sendHtml": sendHtml,
                "card_cvv": cardCVV
            ]
        }else {
            parameters = [
                "paymentType": "card",
                "tractionType": "purchase",
                "card_holder_name": card_holder_name,
                "card_holder_address": cardStreet,
                "card_holder_city": cardCity,
                "card_holder_state": cardState,
                "card_holder_zip": cardZip,
                "card_holder_country": txtCardCountry.text,
                "card_number": cardNumber,
                "card_expiry": cardExpiry,
                "productService": "service",
                "email": self.email,
                "auth": self.user_id,
                "items": JSON(paymentItmes).rawString() ?? "",
                "amount": self.total_amount,
                "sendHtml": sendHtml,
                "card_cvv": cardCVV
            ]
        }
        let headers: HTTPHeaders = [
            :
//         "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            if(code == 200) {
                self.registerTracker(self.user_id,self.email, activateTrackerFormItem)
            } else {
                SweetAlert().showAlert("", subTitle: "Declined Wrong expiration date or wrong cvv number".localized(), style: AlertStyle.error)
            }
        }
    }
    
    func generateToken(_ userId: String, _ email: String, _ activateTrackerFormItem: ActivateTrackerFormModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.generateToken()
        
        let parameters: Parameters = [
            "auth" : userId,
            "card_cvv" : activateTrackerFormItem.cvCode,
            "card_expiry" : activateTrackerFormItem.cardExpiry,
            "card_number" : activateTrackerFormItem.cardNumber,
            "card_holder_name" : activateTrackerFormItem.cardName,
            "card_holder_address": activateTrackerFormItem.cardStreet,
            "card_holder_city": activateTrackerFormItem.cardCity,
            "card_holder_state": activateTrackerFormItem.cardState,
            "card_holder_zip": activateTrackerFormItem.cardZip,
            "card_holder_country": activateTrackerFormItem.cardCountry
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
         //   self.registerTracker(userId,email,activateTrackerFormItem)
            
            let code = dataResponse.response!.statusCode

            let json = JSON.init(parseJSON: dataResponse.value!)

            if(code == 200) {
                if json["error"] == JSON.null || json["error"] == ""{
                    self.registerTracker(userId,email,activateTrackerFormItem)
                }
                else {
                    self.view.makeToast(json["error"].stringValue)
                }
            } else {
                self.view.makeToast(json["error"].stringValue)
//                self.view.makeToast("Credit card information wrong")
            }
            
        }

    }
    
    func registerTracker(_ userId: String, _ email: String, _ activateTrackerFormItem: ActivateTrackerFormModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.trackerRegister()
        
        var trackerPlan = ""
        
        if self.selectedPlanIndex < self.planKeys.count {
            trackerPlan = self.planKeys[self.selectedPlanIndex]
        }
        
        let parameters: Parameters = [
            "spectrumId": activateTrackerFormItem.spectrumId,
            "userId": userId,
            "email": email,
            "plan": trackerPlan,
            "category": activateTrackerFormItem.category,
            "autoRenew": activateTrackerFormItem.isAutoRenew
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print("register\(dataResponse)")
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let _trackerId = json["_id"].stringValue
                self.modify(userId, _trackerId, activateTrackerFormItem)

                //self.doFinalRegisterTrackerWork(userId, _trackerId, activateTrackerFormItem)
            } else {
                self.view.makeToast(json["message"].stringValue)
//                self.view.makeToast("failed to register tracker")
            }
            
        }
    }
    func modify(_ userId: String, _ trackerId: String, _ activateTrackerFormItem: ActivateTrackerFormModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.modify()
        
        let parameters: Parameters = [
            "id": trackerId,
            "driverName": activateTrackerFormItem.driverName,
            "category": activateTrackerFormItem.category,
            "operation": "createNew",
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
           print("modify\(dataResponse)")
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.doFinalRegisterTrackerWork(userId, trackerId, activateTrackerFormItem)
            } else {
                self.view.makeToast(json["error"].stringValue)
//                self.view.makeToast("Update failed!!!")
            }
            
        }
    }
    func doFinalRegisterTrackerWork(_ userId: String, _ trackerId: String, _ activateTrackerFormItem: ActivateTrackerFormModel) {
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        
        let reqInfo = URLManager.createAssets()
        let spectrumId : String = activateTrackerFormItem.spectrumId
        var name = activateTrackerFormItem.plateNumber
        if name == "" {
            name = spectrumId
        }
        var driverName = activateTrackerFormItem.driverName
        if driverName == "" {
            driverName = spectrumId
        }
        let parameters: Parameters = [
            "name": name,
            "trackerId": trackerId,
            "spectrumId": activateTrackerFormItem.spectrumId,
            "userId": userId,
            "driverName": driverName
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            self.hideLoader()
            
            print("final\(dataResponse)")
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            let code = dataResponse.response!.statusCode
            
            if(code == 201) {
                let alertVC = UIAlertController(title: "Congratulations!".localized(), message: "Your device is activated.".localized(), preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default) { _ in
                    MainContainerViewController.instance.onMonitor(self)
                }
                alertVC.addAction(action)
                
//                if let tracker = self.selectedTracker, tracker.hotspot == 1 {
//                    let htmlString = """
//                        <br/>
//                        <div style="width:calc(100% );  background-size:100%;float:left;  padding: 0px 10px 0px 10px; overflow:auto;">
//                        <ul>
//                        <li>Congratulations! Your device is activated. </li>
//                        <li>Your device has WiFi hotspot. <b> WiFi name starts with SMFI and password is 314159265.</b>  Write down your password. </li>
//                        <li>You can connect up to 8 devices to the hotspot. Download speed is between 5 M/s and 25 M/s. </li>
//                        <li>You must purchase LTE data under Subscription to activate WiFi. WiFi does not show without LTE data. </li>
//                        <li>WiFi requires vehicle battery. When engine is off WiFi is off.  </li>
//                        <li>WiFi will disappear when LTE data is used up. </li>
//                        <li>Contact us to receive 1 G of LTE data for free (new user only). </li>
//                        <li>You can go back to Monitor page now. </li>
//                        </ul>
//                        </div>
//                    """
                    let htmlString = """
                        <br/>
                        <div style="width:calc(100% );  background-size:100%;float:left;  padding: 0px 10px 0px 10px; overflow:auto;">
                        <ol>
                        <li> If your device has WiFi, your device WiFi name starts with SMFI</li>
                        <li> WiFi password is <b>314159265</b></li>
                        <li> WiFi name will not show without a WiFi plan.</li>
                        <li> You must order WiFi plan under Subscription to activate WiFi.</li>
                        <li> When engine is off WiFi is off.</li>
                        </ol>
                        </div>
                    """
                    
                    let attributedString = htmlString.htmlAttributedString(color: .black)
                    alertVC.setValue(attributedString, forKey: "attributedMessage")
//                }
                
                self.present(alertVC, animated: true, completion: nil)
                
//                let appearance = SCLAlertView.SCLAppearance(showCloseButton: false, showCircularIcon: true)
//                let alertView = SCLAlertView(appearance: appearance)
//                alertView.addButton("Done", action: {
////                    self.dismiss(animated: true, completion: nil)
//                    MainContainerViewController.instance.onMonitor(self)
//                })
//                alertView.showSuccess("Congratulations!",subTitle: "Your tracker is now activated. Please wait for 5 minutes for the tracker to start. If it does not show on the map, unplug the tracker form the OBD port and then plug it back go reset the device. Contact contact@spectrumtracking.com for assistance.",animationStyle:.topToBottom)
            } else {
                self.view.makeToast(json["error"].stringValue)
//                self.view.makeToast("asset creation failed")
            }
            
        }
    }
    
    @IBAction func planInfoButtonTapped(_ sender: Any) {
        guard self.selectedPlanIndex < self.planList.count, self.selectedPlanIndex < self.planKeys.count else { return }
        let plan = self.planList[self.selectedPlanIndex]
        let selectedPlan  = self.planKeys[self.selectedPlanIndex]
        let values = plan[selectedPlan] ?? []
        
        if values.count < 2 {
            return
        }
        
        var result = ""

        for i in 1..<values.count {
            result += "\(i). \(values[i])\n"
        }
        
        if result == "" {
            return
        }
        
        let alertController = UIAlertController(title: self.txtDataPlan.text, message: "\n\(result)", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(OKAction)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.left
        
        let messageText = NSMutableAttributedString(
            string: "\n\(result)",
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0)
            ]
        )
        
        alertController.setValue(messageText, forKey: "attributedMessage")
        self.present(alertController, animated: true, completion: nil)
    }
}
