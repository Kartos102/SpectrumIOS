
import UIKit
import Alamofire
import SwiftyJSON

class FamilyViewController: ViewControllerWaitingResult {
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "FamilyViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    @IBOutlet var labelNoData: UILabel!
    @IBOutlet var familyTableView: FamilyTableView! {
        didSet {
            self.familyTableView.parentVC = self
        }
    }
    var familyList = [FamilyModel]()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadFamilyList()
    }
    
    func loadFamilyList() {
        self.familyList.removeAll()
        let _sharedDeviceList = Global.shared.app_user["sharedDeviceList"].arrayValue
        for _sharedTracker in _sharedDeviceList {
            let _familyModel = FamilyModel()
            _familyModel.reportId = _sharedTracker["reportId"].stringValue
            _familyModel.flag = _sharedTracker["flag"].stringValue
            var trackerModel: TrackerModel!
            for _tracker in Global.shared.sharedTrackerList {
                if _tracker.reportingId == _sharedTracker["reportId"].stringValue {
                    trackerModel = _tracker
                    break
                }
            }
            if trackerModel != nil {
                _familyModel.name = trackerModel.plateNumber + "(" + trackerModel.driverName + ")"
                self.familyList.append(_familyModel)
            }
        }
        if self.familyList.count == 0 {
            self.labelNoData.isHidden = false
        }
        else {
            self.labelNoData.isHidden = true
        }
        self.familyTableView.setData(self.familyList)
        self.familyTableView.reloadData()
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func setResult(_ result: Any, from id: String, sender: Any? = nil) {
        let reportId = (result as! (String, Bool)).0
        let switchStatus = (result as! (String, Bool)).1
        print(switchStatus)
        var flag = "-1"
        if switchStatus {
            flag = "1"
        }
        self.setShareFlag(reportId,flag)
    }
    func getUserInfo() {
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
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    func setShareFlag(_ reportId: String, _ value: String){
        let reqInfo = URLManager.setShareFlag()
        
        let parameters: Parameters = [
            "reportId" : reportId,
            "flag" : value
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
                self.getUserInfo()
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
}
