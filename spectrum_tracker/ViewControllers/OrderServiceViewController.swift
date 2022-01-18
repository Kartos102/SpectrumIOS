import UIKit
import Alamofire
import SwiftyJSON
import WebKit

class OrderServiceViewController: ViewControllerWaitingResult {
    
    @IBOutlet var tableView: OrderServiceTableView! {
        didSet {
            self.tableView.parentVC = self
        }
    }
    
    @IBOutlet var labelServicePlanSum: UILabel!
    @IBOutlet var labelLteDataSum: UILabel!
    @IBOutlet var labelDataSum: UILabel!
    @IBOutlet var tableHC: NSLayoutConstraint!

//    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var webView: UIWebView!
    
    var trackersList: [TrackerModel] = []
    var planList: [String] = []
    var ltePlanList: [[String: String]] = []
    var trackerPlanList: [[String: String]] = []
    var trackerIntPlanList: [[String: String]] = []
    var phonePlanList: [[String: String]] = []
    var planDetailList: [String: [String]] = [:]
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "OrderServiceViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getCheckOutPlans()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        let descString =
            """
            <ul style="line-height: 2; color: #505050">
                <li><i class='fas fa-arrow-alt-circle-right' style="color:#47a447"></i> Both a WiFi plan and a Tracking plan are required to use the OBD hotspot</li>
                <li><i class='fas fa-arrow-alt-circle-right' style="color:#47a447"></i> You can order WiFi plan at any time </li>
                <li><i class='fas fa-arrow-alt-circle-right' style="color:#47a447"></i> WiFi data is valid for a month from the date of purchase </li>
                <li><i class='fas fa-arrow-alt-circle-right' style="color:#47a447"></i> Unused WiFi data will not rollover</li>
                <li><i class='fas fa-arrow-alt-circle-right' style="color:#47a447"></i> When you use all purchased WiFi data the WiFi name will not show </li>
                <li><i class='fas fa-arrow-alt-circle-right' style="color:#47a447"></i> WiFi will not show when engine is off </li>
                <li><i class='fas fa-arrow-alt-circle-right' style="color:#47a447"></i> By default WiFi plan is not auto renewed. Contact us if you want to have an auto renewed WiFi plan </li>
            </ul>
            """
        webView.loadHTMLString(descString, baseURL: nil)
        webView.scrollView.bounces = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func onTrackersAllLoaded() {
        showTable()
    }
    
    func getCheckOutPlans() {
        let reqInfo = URLManager.getCheckOutPlans()
        
        let parameters: Parameters = [:]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: nil, encoding: JSONEncoding.default , headers: headers)
        
        request.responseString { dataResponse in
            if(dataResponse.data == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let items = json["items"]
                let plans = json["plans"]
                
                var newTrackerList = [TrackerModel]()
                for i in 0..<items.count {
                    newTrackerList.append(TrackerModel.parseJSON(items[i]))
                }
                self.trackersList = newTrackerList
                
                self.planList = plans["allPlans"].arrayValue.map({ $0.stringValue })
                self.ltePlanList = plans["LTEPlanArray"].arrayValue.map({ $0.dictionaryObject as? [String: String] ?? [:] })
                self.trackerPlanList = plans["trackerPlanArray"].arrayValue.map({ $0.dictionaryObject as? [String: String] ?? [:] })
                self.trackerIntPlanList = plans["trackerIntPlanArray"].arrayValue.map({ $0.dictionaryObject as? [String: String] ?? [:] })
                self.phonePlanList = plans["phonePlanArray"].arrayValue.map({ $0.dictionaryObject as? [String: String] ?? [:] })
                self.planDetailList = plans["planDetails"].arrayValue.first?.dictionaryObject as? [String: [String]] ?? [:]
                
                self.onTrackersAllLoaded()
            } else {
                
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    func showTable() {
        var items = [OrderServiceModel]()
        
        for tracker in self.trackersList {
            let item = OrderServiceModel()
            
            item.name = tracker.driverName
            item.trackerId = tracker._id != "" ? tracker._id : tracker.assetId
            
            item.servicePlanList = [ServicePlanModel]()
            item.lteDataList = [LTEDataModel]()
            
            if tracker.trackerModel == "PHONE" {
                for plan in self.phonePlanList {
                    let keys = plan.keys.map({ String($0) })
                    if keys.count > 0 {
                        let key = keys[0]
                        let planValue = plan[key] ?? ""
                        item.servicePlanList.append(ServicePlanModel(planValue, getPriceFromPlanString(planValue), self.planDetailList[key] ?? []))
                    }
                }
            } else if tracker.country != "", tracker.country != "United States", tracker.country != "US" {
                for plan in self.trackerIntPlanList {
                    let keys = plan.keys.map({ String($0) })
                    if keys.count > 0 {
                        let key = keys[0]
                        let planValue = plan[key] ?? ""
                        item.servicePlanList.append(ServicePlanModel(planValue, getPriceFromPlanString(planValue), self.planDetailList[key] ?? []))
                    }
                }
            } else {
                for plan in self.trackerPlanList {
                    let keys = plan.keys.map({ String($0) })
                    if keys.count > 0 {
                        let key = keys[0]
                        let planValue = plan[key] ?? ""
                        item.servicePlanList.append(ServicePlanModel(planValue, getPriceFromPlanString(planValue), self.planDetailList[key] ?? []))
                    }
                }
            }
            
            if tracker.hotspot == 1 {
                for plan in self.ltePlanList {
                    let keys = plan.keys.map({ String($0) })
                    if keys.count > 0 {
                        let key = keys[0]
                        let planValue = plan[key] ?? ""
                        item.lteDataList.append(LTEDataModel(planValue, getPriceFromPlanString(planValue)))
                    }
                }
            } else {
                item.lteDataList.append(LTEDataModel("No Text: $0.00", 0.0))
            }
            
            item.selectedServicePlanId = 0
            if (tracker.dataPlan != "") {
                for i in 0..<item.servicePlanList.count {
                    if tracker.dataPlan == item.servicePlanList[i].servicePlan {
                        item.selectedServicePlanId = i
                    }
                }
            }
            item.selectedLTEDataId = 0
            if (tracker.LTEData != "") {
                for i in 0..<item.lteDataList.count {
                    if tracker.LTEData == item.lteDataList[i].lteData {
                        item.selectedLTEDataId = i
                    }
                }
            }
            
            let expDate = tracker.expirationDate
            
            item.servicePlanEnabled = true
            item.lteDataEnabled = true
            item.expirationDate = (expDate ?? Date()).toString("yyyy-MM-dd")
            item.autoReview = true
            items.append(item)
        }
        
        self.tableView.setData(items)
        self.tableView.reloadData()
        self.tableHC.constant = self.tableView.getHeight()
        self.updateBottomPrices()
    }
    
    
    override func setResult(_ result: Any, from id: String, sender: Any? = nil) {
        if(id == "OrderServiceTableViewCell-need2UpdateBottomPrices") {
            self.updateBottomPrices()
        }
    }
    
    func updateDriver(_ driverName: String, _ driverPhone: String, _ vehicleName: String, _ assetId: String) {
        if(driverName == "") {
            self.view.makeToast("please enter driver name".localized())
            return
        }
        if(driverPhone == "") {
            self.view.makeToast("please enter driver phone".localized())
            return
        }
        if(vehicleName == "") {
            self.view.makeToast("please enter vehicle name".localized())
            return
        }
        
        self.view.endEditing(true)
        
        let reqInfo = URLManager.updateAsset(assetId)
        
        let parameters: Parameters = [
            "name": vehicleName,
            "driverName": driverName,
            "driverPhoneNumber": driverPhone
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
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
                self.view.makeToast("update success".localized())
                self.getCheckOutPlans()
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
        
    }
    
    func updateBottomPrices() {
        var sum1: Double! = 0
        var sum2: Double! = 0
        
        for item in self.tableView.tableData {
            sum1 = sum1 + item.servicePlanList[item.selectedServicePlanId].price
            sum2 = sum2 + item.lteDataList[item.selectedLTEDataId].price
        }
        
        labelServicePlanSum.text = "$" + sum1.priceString()
        labelLteDataSum.text = "$" + sum2.priceString()
        labelDataSum.text = "$" + (sum1 + sum2).priceString()
    }
    
    @IBAction func onProceedToCheckOut(_ sender: Any) {
        let checkoutVC = CheckoutViewController.getNewInstance() as! CheckoutViewController
        checkoutVC.initData.orderServiceItemList = self.tableView.tableData
        checkoutVC.initData.from = "OrderServiceViewController"
        checkoutVC.paymentCompleteHandler = {
            MainContainerViewController.instance.onMonitor(self)
        }
//
//        //self.slideMenuController()?.changeMainViewController(checkoutVC, close: true)
//        self.present(checkoutVC, animated: true, completion: nil)
        MainContainerViewController.instance.hideOverlay()
        MainContainerViewController.instance.topbar_view.backgroundColor = UIColor.white
        MainContainerViewController.instance.setPage(controller: checkoutVC)
    }
    
    @IBAction func detailsButtonTapped(_ sender: Any) {
        let url = URL(string: "https://spectrumtracking.com/pricing.html")!
        webView.scalesPageToFit = true
        webView.loadRequest(URLRequest(url: url))
    }
    
    func getPriceFromPlanString(_ string: String) -> Double {
        if let index = string.lastIndex(of: "$") {
            let priceString = String(string.suffix(from: string.index(after: index)))
            return Double(priceString) ?? 0.0
        }
        
        return 0.0
    }
}
