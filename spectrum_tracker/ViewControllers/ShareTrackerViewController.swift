//
//  ShareTrackerViewController.swift
//  spectrum_tracker
//
//  Created by Admin on 11/12/19.
//  Copyright © 2019 JO. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ShareTrackerViewController: ViewControllerWaitingResult {
    @IBOutlet var shareTrackerTableView: ShareTrackerTableView! {
        didSet {
            self.shareTrackerTableView.parentVC = self
        }
    }
    @IBOutlet var sharedUserTableView: SharedUserTableView! {
        didSet {
            self.sharedUserTableView.parentVC = self
        }
    }
    
    @IBOutlet var sharedUserTableViewHeight: NSLayoutConstraint!
    @IBOutlet var labelNotSharedUserHC: NSLayoutConstraint!
    @IBOutlet var backView: UIView!
    @IBOutlet var sharedUserListDialogView: CardView!
    
    var isGettingSharedusers = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func onBackViewAction(_ sender: Any) {
        self.backView.isHidden = true
        self.sharedUserListDialogView.isHidden = true
    }
    @IBAction func onSelectAll(_ sender: Any) {
        var label = ""
        for sharedUserModel in self.sharedUserList {
            label += sharedUserModel.email + ","
        }
        if label == "" {
            label = "Select Users"
        }else {
            label = String(label.dropLast())
        }
        self.shareList[self.selected_index].labelSharedUser = label
        self.shareTrackerTableView.setData(self.shareList)
        self.shareTrackerTableView.reloadData()
        self.backView.isHidden = true
        self.sharedUserListDialogView.isHidden = true
    }
    @IBAction func onOkAction(_ sender: Any) {
        var label = ""
        for sharedUserModel in self.sharedUserList {
            if sharedUserModel.checked {
                label += sharedUserModel.email + ","
            }
        }
        if label == "" {
            label = "Select Users"
        }else {
            label = String(label.dropLast())
        }
        self.shareList[self.selected_index].labelSharedUser = label
        self.shareTrackerTableView.setData(self.shareList)
        self.shareTrackerTableView.reloadData()
        self.backView.isHidden = true
        self.sharedUserListDialogView.isHidden = true
    }
    var shareList = [ShareModel]()
    var sharedUserList = [SharedUserModel]()
    var selected_index = -1
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "ShareTrackerViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    override func viewWillAppear(_ animated: Bool) {
        loadTable()
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func loadTable() {
        
        shareList.removeAll()
        
        self.view.endEditing(true)
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.assets()
        
        let parameters: Parameters = [
            :
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
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
                var assetIds = [String]()
                for i in 0..<items.count {
                   
                    assetIds.append(AssetModel.parseJSON(items[i]).trackerId)
                }
                self.getAllTrackers(assetIds)
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
        
    }
    func getAllTrackers(_ assetIds : [String]) {
        self.shareList.removeAll()
        let reqInfo = URLManager.getAllTrackers()
        
        let parameters: Parameters = [
            "tracker_ids" : assetIds
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
                let items = json["items"]
                var newTrackerList = [TrackerModel]()
                for i in 0..<items.count {
                    newTrackerList.append(TrackerModel.parseJSON(items[i]))
                }
                for newTracker in newTrackerList {
                    let _shareModel = ShareModel()
                    _shareModel.plateNumber = newTracker.plateNumber
                    _shareModel.labelSharedUser = "Select Users"
                    _shareModel.reportId = newTracker.reportingId
                    self.shareList.append(_shareModel)
                }
               
                self.onTrackersAllLoaded()
            } else {
                
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    func onTrackersAllLoaded() {
        self.shareTrackerTableView.setData(self.shareList)
        self.shareTrackerTableView.reloadData()
    }
    func getShareUsers(_ reportId : String){
        guard !isGettingSharedusers else { return }
        
        isGettingSharedusers = true
        
        self.sharedUserList.removeAll()
        let reqInfo = URLManager.getShareUsers()
        
        let parameters: Parameters = [
            "reportId" : reportId
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
                let items = json["items"]
                for i in 0..<items.count {
                    let _sharedUserModel = SharedUserModel()
                    _sharedUserModel.email = items[i]["email"].stringValue
                    _sharedUserModel.checked = false
                    if self.shareList[self.selected_index].labelSharedUser.contains(items[i]["email"].stringValue) {
                        _sharedUserModel.checked = true
                    }
                    if _sharedUserModel.email != "" {
                        self.sharedUserList.append(_sharedUserModel)
                    }
                }
                self.sharedUserTableView.setData(self.sharedUserList)
                self.sharedUserTableView.reloadData()
                let max_height = self.view.bounds.height * 0.9
                if max_height > self.sharedUserTableView.getHeight() {
                    self.sharedUserTableViewHeight.constant = self.sharedUserTableView.getHeight()
                }
                else {
                    self.sharedUserTableViewHeight.constant = max_height
                }
                if self.sharedUserList.count == 0 {
                    self.labelNotSharedUserHC.constant = 30
                    self.sharedUserTableViewHeight.constant = 0
                }
                else {
                    self.labelNotSharedUserHC.constant = 0
                }
                self.backView.isHidden = false
                self.sharedUserListDialogView.isHidden = false
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
            self.isGettingSharedusers = false
        }
    }
    func shareTracker(_ reportId : String, _ email : String) {
        let reqInfo = URLManager.shareTracker()
        
        let parameters: Parameters = [
            "reportId" : reportId,
            "email" : email,
            "flag" : "0"
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
                if json["result"].boolValue {
                    self.view.makeToast("Success".localized())
                    self.loadTable()
                }
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    func unShareTracker(_ reportId : String, _ userList : [String]) {
        let reqInfo = URLManager.unShareTracker()
        
        let parameters: Parameters = [
            "reportId" : reportId,
            "email" : userList
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
                self.view.makeToast("Success".localized())
                self.loadTable()
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    override func setResult(_ result: Any, from id: String, sender: Any? = nil) {
        if(id == "onShowSharedUserDialog") {
            let reportId = (result as! (String, Int)).0
            self.selected_index = (result as! (String, Int)).1
            self.getShareUsers(reportId)
        }else if(id == "SharedUserTableViewCell-selectedItem") {
            let row = (result as! (Int, Bool)).0
            let isSelected = (result as! (Int, Bool)).1
            self.sharedUserList[row].checked = isSelected
        }else if(id == "onShareAction") {
            let reportId = (result as! (String, String)).0
            let email = (result as! (String, String)).1
            self.shareTracker(reportId,email)
        }else if(id == "onUnShareAction") {
            let reportId = (result as! (String, String)).0
            let userListStr = (result as! (String, String)).1
            let userList = userListStr.split(separator: ",")
            var userEmailList = [String]()
            for user in userList {
                userEmailList.append(String(user))
            }
            self.unShareTracker(reportId,userEmailList)
        }
    }
}
