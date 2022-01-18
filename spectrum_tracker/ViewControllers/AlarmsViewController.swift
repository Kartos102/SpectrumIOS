import UIKit
import Alamofire
import SwiftyJSON
import Mapbox
import MapKit
import SwiftyUserDefaults

class AlarmsViewController: ViewControllerWaitingResult,UIScrollViewDelegate {
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "AlarmsViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    @IBOutlet var assetSingleSelectTableViewHC: NSLayoutConstraint!
    @IBOutlet var reportEventView: UIStackView!
    @IBOutlet var dateSelect: UISegmentedControl!
    @IBOutlet var datePickerWrapperView: UIView!
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var topView: UIView!
    @IBOutlet var table_handler: UIImageView!
    @IBOutlet var bottomTableView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var btn_next_day: UIButton!
    @IBOutlet var start_date: UILabel!
    @IBOutlet var assetSingleSelectTableView: AssetSingleSelectTableView! {
        didSet {
            assetSingleSelectTableView.parentVC = self
        }
    }
    @IBOutlet var reportEventTableView: ReportEventTableView! {
        didSet {
            reportEventTableView.parentVC = self
        }
    }
    
    var day_index: Int = 0
    var replayStartDate: Date!
    var replayEndDate: Date!
    var trackerList: [TrackerModel] = []
    var selectedTracker: TrackerModel? = nil
    var eventList: [ReportEventModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.panGestureRecognizer.delaysTouchesBegan = true
        self.scrollView.delegate = self
        table_handler.image = table_handler.image?.withRenderingMode(.alwaysTemplate)
        table_handler.tintColor = UIColor.gray
        
        initUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hideDatePicker()
        
        self.replayStartDate = Date()
        self.replayEndDate = self.replayStartDate.date(plusDay: 1)
        self.start_date.text = self.replayStartDate.toString("MMM dd")
        
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
    }
    
    func initUI() {
        self.bottomTableView.layer.borderColor = UIColor.gray.cgColor
        self.bottomTableView.layer.borderWidth = 0.5
        self.bottomTableView.layer.cornerRadius = 20.0
        self.bottomTableView.backgroundColor = UIColor(hexInt: 0xFDE5F3)
        self.bottomTableView.layer.masksToBounds = false
    }
    
    @IBAction func selectDate(_ sender: Any) {
        if(dateSelect.selectedSegmentIndex == 0) {
            datePicker.setDate(replayStartDate, animated: true)
        }
        else {
            datePicker.setDate(replayEndDate, animated: true)
        }
    }
    
    @IBAction func onPrevDay(_ sender: Any) {
        self.day_index -= 1
        self.btn_next_day.isHidden = false
        self.replayStartDate = self.replayStartDate.date(plusDay: -1)
        self.replayEndDate =  self.replayEndDate.date(plusDay: -1)
        self.start_date.text = self.replayStartDate.toString("MMM dd")
       
        loadEvents()
    }
    @IBAction func onNextDay(_ sender: Any) {
        self.day_index += 1
        if day_index >= 0 {self.btn_next_day.isHidden = true}
        self.replayStartDate = self.replayStartDate.date(plusDay: 1)
        self.replayEndDate =  self.replayEndDate.date(plusDay: 1)
        self.start_date.text = self.replayStartDate.toString("MMM dd")
        
        loadEvents()
    }
    
    func showDatePicker() {
        if self.datePickerWrapperView.isHidden {
            self.datePickerWrapperView.alpha = 0
            self.datePickerWrapperView.isHidden = false
            UIView.animate(withDuration: 0.2, animations: {
                self.datePickerWrapperView.alpha = 1
            })
        }
    }
    
    func hideDatePicker() {
        if datePickerWrapperView.isHidden == false {
            UIView.animate(withDuration: 0.2, animations: {
                self.datePickerWrapperView.alpha = 0
                
            }) { (value) in
                self.datePickerWrapperView.isHidden = true
            }
        }
    }
    
    func setBottomTableData() {
        self.assetSingleSelectTableView.setData(self.trackerList)
        self.assetSingleSelectTableView.reloadData()
        self.assetSingleSelectTableViewHC.constant = self.assetSingleSelectTableView.getHeight()
    }
    
    func loadAllDrivers() {
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
    
    func loadEvents() {
        guard let selectedTracker = self.selectedTracker else { return }
        
        let reportId = selectedTracker.reportingId
        
        let startTime = replayStartDate.setTime()
        let endTime = replayEndDate.setTime()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M-d HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        
        let startTimeString = dateFormatter.string(from: startTime) + ".000Z"
        let endTimeString = dateFormatter.string(from: endTime) + ".000Z"
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.event_logs(reportId)
        
        let parameters: Parameters = [
            "startDate": startTimeString,
            "endDate": endTimeString
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
        
        request.responseString { dataResponse in
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            //print(dataResponse)
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                
                self.eventList = [ReportEventModel]()
                
                for i in 0..<json.count {
                    self.eventList.append(ReportEventModel.parseJSON(json[i]))
                }
                
                if self.eventList.count != 0 {
                    self.reportEventTableView.setData(self.eventList)
                    self.reportEventTableView.reloadData()
                    self.reportEventView.isHidden = false
                } else {
                    self.view.makeToast("No Alarm. Change to another day.".localized())
                }
                
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    @IBAction func onBtnStartDate(_ sender: Any) {
        datePicker.setDate(replayStartDate, animated: false)
        dateSelect.selectedSegmentIndex = 0
        showDatePicker()
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
        loadEvents()
    }
}

extension AlarmsViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.topView.frame.origin.y = scrollView.contentOffset.y
    }
}
