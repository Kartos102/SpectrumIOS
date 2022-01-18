import UIKit
import Alamofire
import SwiftyJSON


class UpdateDriverInfoViewController: ViewControllerWaitingResult {
    
    var assetList = [AssetModel]()
    var trackers = [AssetModel: TrackerModel]()
    
    @IBOutlet var tableView: UpdateDriverInfoTableView! {
        didSet {
            self.tableView.parentVC = self
        }
    }
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "UpdateDriverInfoViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        loadTable()
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func loadTable() {
        
        assetList.removeAll()
        trackers.removeAll()
        
        self.view.endEditing(true)
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!")
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
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                let items = json["items"]
                var trackerIds = [String]()
                for i in 0..<items.count {
                    self.assetList.append(AssetModel.parseJSON(items[i]))
                    trackerIds.append(AssetModel.parseJSON(items[i]).trackerId)
                }
                self.getAllTrackers(trackerIds)
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
        
    }
    func getAllTrackers(_ assetIds : [String]) {
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
                self.view.makeToast("server connect error")
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
                var tempAssetList = [AssetModel]()
                for newTracker in newTrackerList {
                    for asset in self.assetList {
                        if(newTracker._id == asset.trackerId) {
                            self.trackers[asset] = newTracker
                            tempAssetList.append(asset)
                        }
                    }
                }
                self.assetList = tempAssetList
                self.onTrackersAllLoaded()
            } else {
                
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    
    func onTrackersAllLoaded() {
        self.tableView.setData(assetList, trackers: trackers)
        self.tableView.reloadData()
    }
    
    override func setResult(_ result: Any, from id: String, sender: Any? = nil) {
        if(id == "UpdateDriverInfoTableView-updateDriverItem") {
            let item = result as! (String, String, String, String, String, String, String)
            self.updateDriver(item.0, item.1, item.2, item.3, item.4, item.5, item.6)
        }
    }
    
    func updateDriver(_ trackerId: String, _ driverName: String, _ driverPhone: String, _ plateNumber: String, _ assetId: String, _ color: String, _ autoRenew: String) {
        self.view.endEditing(true)
        
        if(driverName == "") {
            self.view.makeToast("please enter driver name")
            return
        }
//        if(driverPhone == "") {
//            self.view.makeToast("please enter driver phone")
//            return
//        }
        if(plateNumber == "") {
            self.view.makeToast("please enter vehicle name")
            return
        }
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!")
            return
            // do some tasks..
        }
        
//        let reqInfo = URLManager.updateAsset(assetId)
        let reqInfo = URLManager.modifyTracker()
        
        let parameters: Parameters = [
            "id": trackerId,
//            "name": vehicleName,
            "plateNumber": plateNumber,
            "driverName": driverName,
            "driverPhoneNumber": driverPhone,
            "autoRenew": autoRenew,
            "color": color
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
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                self.view.makeToast("update success".localized())
                
                self.loadTable()
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
        
    }
    

}
