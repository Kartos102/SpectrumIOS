import UIKit
import Alamofire
import SwiftyJSON
import Mapbox
import MapKit
import SwiftyUserDefaults
class ReportsViewController: ViewControllerWaitingResult,UIScrollViewDelegate,UITableViewDelegate {
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "ReportsViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    @IBOutlet var assetSingleSelectTableViewHC: NSLayoutConstraint!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var reportTableView: UITableView!
    @IBOutlet var weekStackView: UIStackView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var topView: UIView!
    @IBOutlet var bottomTableView: UIView!
    @IBOutlet var btn_next_week: UIButton!
    @IBOutlet var table_handler: UIImageView!
    @IBOutlet var date_from_to_label: UILabel!
    @IBOutlet var assetSingleSelectTableView: AssetSingleSelectTableView! {
        didSet {
            assetSingleSelectTableView.parentVC = self
        }
    }
    
    @IBOutlet weak var txtExpirationDate: UILabel!
    @IBOutlet weak var txtLastAlert: UILabel!
    @IBOutlet weak var txtLastStop: UILabel!
    @IBOutlet weak var txtLastStart: UILabel!
    @IBOutlet weak var txtOilChange: UILabel!
    @IBOutlet weak var txtYearFuel: UILabel!
    @IBOutlet weak var txtBattery: UILabel!
    @IBOutlet weak var txtMaxSpeed: UILabel!
    @IBOutlet weak var txtYearTrip: UILabel!
    @IBOutlet weak var txtMonthTrip: UILabel!
    var week_index = 0
    var replayStartDate: Date = Date()
    var replayEndDate: Date = Date()
    var trackerList: [TrackerModel] = []
    var selectedTracker: TrackerModel? = nil
    var eventList: [ReportEventModel] = []
    var tripLogList: [TripLogModel] = []
    
    fileprivate var reportTableViewDataSource = ReportTableViewDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.panGestureRecognizer.delaysTouchesBegan = true
        self.scrollView.delegate = self
        self.reportTableView.delegate = self
        self.reportTableView.dataSource = reportTableViewDataSource
        self.reportTableView.rowHeight = UITableView.automaticDimension
        self.reportTableView.estimatedRowHeight = 270.0
        self.reportTableView.separatorStyle = .none
        
        table_handler.image = table_handler.image?.withRenderingMode(.alwaysTemplate)
        table_handler.tintColor = UIColor.gray
        
        initUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.scrollView {
            self.topView.frame.origin.y = scrollView.contentOffset.y
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.replayStartDate = Date()
        var weekday = self.replayStartDate.weekDay()
        if weekday == 1 { weekday += 7 }
        self.replayEndDate = self.replayStartDate.date(plusDay: 1)
        self.replayStartDate = self.replayStartDate.date(plusDay: weekday * -1 + 2)
        self.date_from_to_label.text = "This Week".localized()
        self.btn_next_week.isHidden = true
        
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
            
            setSelectedTracker(tracker: selectedTracker, shouldLoadReplay: true)
        } else {
            loadAllDrivers()
        }
    }
    
    func initUI() {
        self.bottomTableView.layer.borderColor = UIColor.gray.cgColor
        self.bottomTableView.layer.borderWidth = 0.5
        self.bottomTableView.layer.cornerRadius = 20.0
        self.bottomTableView.backgroundColor = UIColor(hexInt: 0xFDE5F3)
        self.bottomTableView.layer.masksToBounds = true
    }
    
    func setBottomTableData() {
        self.assetSingleSelectTableView.setData(self.trackerList)
        self.assetSingleSelectTableView.reloadData()
        self.assetSingleSelectTableViewHC.constant = self.assetSingleSelectTableView.getHeight()
    }
   
    @IBAction func onPrevDay(_ sender: Any) {//prev_week
        self.week_index -= 1
        if self.week_index < 0 {self.btn_next_week.isHidden = false}
        self.replayStartDate = self.replayStartDate.date(plusDay: -7)
        self.replayEndDate =  self.replayStartDate.date(plusDay: 6)
        self.date_from_to_label.text = self.replayStartDate.toString("MMM dd") + " - " + self.replayEndDate.toString("MMM dd")
        //self.labelStartDate.text = self.replayStartDate.toString("yyyy/MM/dd")
        //self.labelEndDate.text = self.replayEndDate.toString("yyyy/MM/dd")
        loadEvents()
    }
    
    @IBAction func onNextDay(_ sender: Any) {//next_week
        self.week_index += 1
        if self.week_index >= 0 {
            self.btn_next_week.isHidden = true
            self.replayStartDate = Date()
            var weekday = self.replayStartDate.weekDay()
            if weekday == 1 { weekday += 7 }
            self.replayEndDate = self.replayStartDate.date(plusDay: 1)
            self.replayStartDate = self.replayStartDate.date(plusDay: weekday * -1 + 2)
            self.date_from_to_label.text = "This Week".localized()
        }
        else {
            self.replayStartDate = self.replayStartDate.date(plusDay: 7)
            self.replayEndDate =  self.replayEndDate.date(plusDay: 7)
            self.date_from_to_label.text = self.replayStartDate.toString("MMM dd") + " - " + self.replayEndDate.toString("MMM dd")
        }
        loadEvents()
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
                
                self.setSelectedTracker(tracker: self.selectedTracker, shouldLoadReplay: true)
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
        
        let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
        
        request.responseString { dataResponse in
            self.hideLoader()
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            //print(dataResponse)
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.eventList = json.arrayValue.map({ ReportEventModel.parseJSON($0) })
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
            self.loadTripLogs(reportId: reportId)
        }
    }
    
    func loadTripLogs(reportId: String) {
        
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
        
        let reqInfo = URLManager.trip_log_summary()
        let metricScale = Global.getDistanceUnit() == "miles" ? 1 : 1.60934
        let volumeMetricScale = Global.getDistanceUnit() == "miles" ? 1 : 3.78541
        let parameters: Parameters = [
            "reportingId": reportId,
            "startDate": startTimeString,
            "endDate": endTimeString,
            "metricScale": metricScale,
            "volumeMetricScale": volumeMetricScale
        ]
        
        let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
        
        request.responseString { dataResponse in
            self.hideLoader()
            
            print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            //print(dataResponse)
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.showSummaryResult(json)
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    func showSummaryResult(_ object: JSON) {
        let tripLogTable = object["tripLogTable"].arrayValue
        let tracker = object["tracker"]
        if tripLogTable.count == 0 {
            SweetAlert().showAlert("Info", subTitle: "No trip. Change to another day", style: AlertStyle.error)
        }
        var mileage_list: [ReportChartModel] = []
        var maxSpeed_list: [ReportChartModel] = []
        var fuel_list: [ReportChartModel] = []
        var stop_list: [ReportChartModel] = []
        var acce_list: [ReportChartModel] = []
        var dece_list: [ReportChartModel] = []
        var speeding_list: [ReportChartModel] = []
        var idling_list: [ReportChartModel] = []
        var week_status: [Bool] = [false,false,false,false,false,false,false]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        for i in 0..<tripLogTable.count {
            let _triplog = tripLogTable[i]
            let date = dateFormatter.date(from:_triplog[0].stringValue)!
            maxSpeed_list.append(ReportChartModel(date: date,value: _triplog[8].doubleValue))
            acce_list.append(ReportChartModel(date: date,value: _triplog[5].doubleValue))
            dece_list.append(ReportChartModel(date: date,value: _triplog[6].doubleValue))
            speeding_list.append(ReportChartModel(date: date,value: _triplog[4].doubleValue))
            stop_list.append(ReportChartModel(date: date,value: _triplog[3].doubleValue))
            fuel_list.append(ReportChartModel(date: date,value: _triplog[2].doubleValue))
            idling_list.append(ReportChartModel(date: date,value: _triplog[7].doubleValue))
            mileage_list.append(ReportChartModel(date: date,value: _triplog[1].doubleValue))
        }
        reportTableViewDataSource.dataClear()
        reportTableViewDataSource.insertData(ReportModel(title: "Distance".localized(),value: String(format: "%.0f",object["totalMileage"].doubleValue),chartValue: mileage_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Max Speed".localized(),value: String(format: "%.0f",object["maxSpeed"].doubleValue),chartValue: maxSpeed_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Total Fuel".localized(),value: String(format: "%.2f",object["totalFuel"].doubleValue),chartValue: fuel_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Total Stops".localized(),value: String(object["totalTrips"].intValue),chartValue: stop_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Rapid Accel".localized(),value: String(object["hardAcceNum"].intValue),chartValue: acce_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Hard Braking".localized(),value: String(object["hardDeceNum"].intValue),chartValue: dece_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Speeding".localized(),value: String(object["speedingNum"].intValue),chartValue: speeding_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "High RPM".localized(),value: String(object["highRPMNum"].intValue),chartValue: [],eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Low Battery".localized(),value: String(object["lowBatteryNum"].intValue),chartValue: [],eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "High Coolant".localized(),value: String(object["coolantTempHighNum"].intValue),chartValue: [],eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Idling".localized(),value: String(object["idleEngineNum"].intValue),chartValue: idling_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Device Removal".localized(),value: String(getEventSize("device removal")),chartValue: [],eventValue: []))
        
        reportTableView.reloadData()
        self.indicator.isHidden = true
        let metricScale = Global.getDistanceUnit() == "miles" ? 1 : 1.60934
        txtMaxSpeed.text = String(format: "%.0f",tracker["maxSpeed"].doubleValue * metricScale)
        txtYearFuel.text = String(format: "%.1f",tracker["yearFuel"].doubleValue * metricScale)
        txtOilChange.text = String(format: "%.1f",tracker["oilChangeMileage"].doubleValue * metricScale)
    }
    func getEventSize(_ title: String) -> Int{
        var count:Int = 0
        for i in 0..<self.eventList.count {
            if self.eventList[i].alarm == title {
                count += 1
            }
        }
        return count
    }
    func showReportTrip() {
        var maxSpeed:Double! = 0
        var harshDeceNum:Int! = 0
        var harshAcceNum:Int! = 0
        var speedingNum:Int! = 0
        var totalTrips:Int! = 0
        var idleNum:Int! = 0
        var totalFuel:Double! = 0
        var totalMileages:Double! = 0
        var mileage_list: [ReportChartModel] = []
        var maxSpeed_list: [ReportChartModel] = []
        var fuel_list: [ReportChartModel] = []
        var stop_list: [ReportChartModel] = []
        var acce_list: [ReportChartModel] = []
        var dece_list: [ReportChartModel] = []
        var speeding_list: [ReportChartModel] = []
        var idling_list: [ReportChartModel] = []
        var week_status: [Bool] = [false,false,false,false,false,false,false]
        
        for i in 0..<tripLogList.count {
            let device = tripLogList[i]
            let week_day = device.dateTime.weekDay()-1
            let metricScale = Global.getDistanceUnit() == "miles" ? 1 : 1.60934
            let volumeMetricScale = Global.getDistanceUnit() == "miles" ? 1 : 3.78541
            
            if !week_status[week_day] {
                mileage_list.append(ReportChartModel(date: device.dateTime,value: device.mileage * metricScale))
                maxSpeed_list.append(ReportChartModel(date: device.dateTime,value: device.maxSpeed * metricScale))
                fuel_list.append(ReportChartModel(date: device.dateTime,value: device.fuel * volumeMetricScale))
                stop_list.append(ReportChartModel(date: device.dateTime,value: Double(device.stops)))
                acce_list.append(ReportChartModel(date: device.dateTime,value: Double(device.harshAcce)))
                dece_list.append(ReportChartModel(date: device.dateTime,value: Double(device.harshDece)))
                speeding_list.append(ReportChartModel(date: device.dateTime,value: Double(device.speeding)))
                idling_list.append(ReportChartModel(date: device.dateTime,value: Double(device.idle)))
                
                maxSpeed = max(maxSpeed,device.maxSpeed * metricScale)
                harshDeceNum = harshDeceNum + device.harshDece
                harshAcceNum = harshAcceNum + device.harshAcce
                speedingNum = speedingNum + device.speeding
                totalTrips = totalTrips + device.stops
                idleNum = idleNum + device.idle
                totalFuel = totalFuel + device.fuel * volumeMetricScale
                totalMileages = totalMileages + device.mileage * metricScale
                week_status[week_day] = true
            }
        }
        totalTrips = totalTrips <= 0 ? 0 : totalTrips
        
        reportTableViewDataSource.dataClear()
        reportTableViewDataSource.insertData(ReportModel(title: "Distance".localized(),value: String(format: "%.2f",totalMileages),chartValue: mileage_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Max Speed".localized(),value: String(format: "%.2f",maxSpeed),chartValue: maxSpeed_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Total Fuel".localized(),value: String(format: "%.2f",totalFuel),chartValue: fuel_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Total Stops".localized(),value: String(totalTrips),chartValue: stop_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Rapid Accel".localized(),value: String(harshAcceNum),chartValue: acce_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Hard Braking".localized(),value: String(harshDeceNum),chartValue: dece_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Speeding".localized(),value: String(speedingNum),chartValue: speeding_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Idling".localized(),value: String(idleNum),chartValue: idling_list,eventValue: []))
        reportTableViewDataSource.insertData(ReportModel(title: "Main Events".localized(),value: String(self.eventList.count),chartValue: [],eventValue: self.eventList))
        
        reportTableView.reloadData()
        self.indicator.isHidden = true
        
    }
    
    
    override func setResult(_ result: Any, from id: String, sender: Any? = nil) {
        if id == "AssetSingleSelectTableViewCell-selectedItem" {
            let tracker = result as? TrackerModel
            setSelectedTracker(tracker: tracker, shouldLoadReplay: true)
        }
    }
    
    func setSelectedTracker(tracker: TrackerModel?, shouldLoadReplay: Bool) {
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
        
        if shouldLoadReplay {
            loadEvents()
        }
        let metricScale = Global.getDistanceUnit() == "miles" ? 1 : 1.60934
        txtMonthTrip.text = String(format:"%.1f",_tracker.monthMile)
        txtYearTrip.text = String(format:"%.1f",_tracker.yearMile)
        txtYearFuel.text = String(format:"%.2f",_tracker.yearFuel * metricScale)
        txtBattery.text = String(format:"%.2f",_tracker.voltage)
        txtOilChange.text = String(format:"%.2f",_tracker.oilChangeMileage * metricScale)
        if _tracker.lastACCOntime != nil {
            txtLastStart.text = _tracker.lastACCOntime?.toString("MM/dd hh:mm a")
        }
        else {
            txtLastStart.text = "N/A"
        }
        if _tracker.lastACCOfftime != nil {
            txtLastStop.text = _tracker.lastACCOfftime?.toString("MM/dd hh:mm a")
        }
        else {
            txtLastStop.text = "N/A"
        }
        txtLastAlert.text = String(_tracker.lastAlert)
        if _tracker.expirationDate != nil {
            txtExpirationDate.text = _tracker.expirationDate?.toString("MM/dd/YYYY")
        }
    }
}

extension ReportsViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ReportTableViewCell
        
        cell.state = .expanded
        reportTableViewDataSource.addExpandedIndexPath(indexPath)
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! ReportTableViewCell
        
        cell.state = .collapsed
        reportTableViewDataSource.removeExpandedIndexPath(indexPath)
        
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}
