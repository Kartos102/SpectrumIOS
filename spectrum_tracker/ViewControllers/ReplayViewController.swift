import UIKit
import Alamofire
import SwiftyJSON
import Mapbox
import MapKit
import MapboxGeocoder
import Charts
import SwiftyUserDefaults

class CustomAnnotation: MGLPointAnnotation {
    var heading: CGFloat! = 0
}


class ReplayViewController: ViewControllerWaitingResult , UIScrollViewDelegate,UITableViewDelegate{
   
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "ReplayViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    @IBOutlet var replayTripLogTableView: UITableView!
    @IBOutlet var info_table: UIStackView!
    @IBOutlet var label_topSpeed: UILabel!
    @IBOutlet var routeControlView: UIView!
    @IBOutlet var btn_prevDay: UIButton!
    @IBOutlet var btn_backwardR: UIButton!
    @IBOutlet var btn_playR: UIButton!
    @IBOutlet var label_totalStops: UILabel!
    @IBOutlet var btn_forwardR: UIButton!
    @IBOutlet var topStackView: UIStackView!
    @IBOutlet var btn_nextDay: UIButton!
    @IBOutlet var label_dateFromTO: UILabel!
    @IBOutlet var zoom_Slider: VSSlider!
    @IBOutlet var mapViewWrapper: UIView!
    @IBOutlet var slider: UISlider!
    @IBOutlet var labelSpeed: UILabel!
    @IBOutlet var btn_style: UIButton!
    @IBOutlet var allScrollView: UIScrollView!
    @IBOutlet var labelGageDate: UILabel!
    @IBOutlet var speedIndicator: UIImageView!
    @IBOutlet var topViewHC: NSLayoutConstraint!
    @IBOutlet var topView: UIView!
    @IBOutlet var bottomTableView: UIView!
    @IBOutlet var bottomView: UIStackView!
    @IBOutlet var bottomTableHC: NSLayoutConstraint!
    @IBOutlet var bottomHC: NSLayoutConstraint!
    @IBOutlet var table_handler: UIImageView!
    @IBOutlet var btn_menu: UIButton!
    @IBOutlet var replayTripLogTableHeight: NSLayoutConstraint!
    @IBOutlet var assetSingleSelectTableView: AssetSingleSelectTableView! {
        didSet {
            assetSingleSelectTableView.parentVC = self
        }
    }
    
    var mapView: MGLMapView!
    var mapStyle: Bool = false
    var replayStartDate: Date = Date()
    var replayEndDate: Date = Date()
    var trackerList: [TrackerModel] = []
    var selectedTracker: TrackerModel? = nil
    var points: [CLLocationCoordinate2D] = []
    var displayPoints: [CLLocationCoordinate2D] = []
    var speed_Array: [Double] = []
    var distance_Array: [Double] = []
    var dateTime_Array: [Date] = []
    var partHeader_Array: [String] = []
    var speeding_Array: [Int] = []
    var onOffEvent_Array: [Int] = []
    var accAlarm_Array: [Int] = []
//    var accOffAlarm_Array: [Int]!
//    var accOnAlarm_Array: [Int]!
    var harshAcce_Array: [Int] = []
    var harshDece_Array: [Int] = []
    var idling_Array: [Int] = []
    var plugOut_Array: [Int] = []
    var pointIndex_Array: [Int] = []    /// start or end point index of each route
    var velocityState_Array: [Bool] = []
    var addressArray: [String] = []
    var geoMarkerIndex: Int! = 0
    var startImage: UIImage = UIImage(named: "start")!
    var finishImage: UIImage = UIImage(named: "finish")!
    var speedingImage: UIImage = UIImage(named: "driverspeeding")!
    var harshacceImage: UIImage = UIImage(named: "replay_harshacce")!
    var harshdeceImage: UIImage = UIImage(named: "replay_desse")!
    var idlingImage: UIImage = UIImage(named: "replay_idling")!
    var stopImage: UIImage = UIImage(named: "stop")!
    var animatingTimer: Timer? = nil
    var geoAnnotation: CustomAnnotation? = nil
    var selectRouteIndex: Int = -1
    var total_stops: Int = 0
    var harsh_acce: Int = 0
    var harsh_dece: Int = 0
    var total_speeding: Int = 0
    var top_speed: Double = 0.0
    fileprivate var replayTripLogTableViewDataSource = TripLogTableViewDataSource()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.allScrollView.panGestureRecognizer.delaysTouchesBegan = true
        self.replayTripLogTableView.delegate = self
        self.replayTripLogTableView.dataSource = replayTripLogTableViewDataSource
        self.replayTripLogTableView.rowHeight = UITableView.automaticDimension
       // self.replayTripLogTableView.estimatedRowHeight = 270.0
        self.replayTripLogTableView.separatorStyle = .none
        
        table_handler.image = table_handler.image?.withRenderingMode(.alwaysTemplate)
        table_handler.tintColor = UIColor.gray
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        initUI()
        initMapView()
        
        points = [CLLocationCoordinate2D]()
        
        self.replayStartDate = Date()
        self.replayEndDate =  self.replayStartDate.date(plusDay: 1)
        self.label_dateFromTO.text = self.replayStartDate.toString("MM/dd")
        self.topViewHC.constant = self.view.bounds.height - 46 - 42 - 55
        self.btn_nextDay.isEnabled = true
        
        trackerList.removeAll()
        selectedTracker = nil
        
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
        self.bottomTableView.layer.masksToBounds = false
        
        self.replayTripLogTableHeight.constant = 0
        self.topViewHC.constant = self.view.bounds.height - 46 - 42 - 55
        self.btn_forwardR.isEnabled = false
        self.btn_playR.isEnabled = false
        self.slider.isHidden = true
        self.label_topSpeed.text = String(0)
        self.label_totalStops.text = String(0)
        
        self.allScrollView.delegate = self
    }
    
    func initMapView() {
        self.mapView = MGLMapView(frame: mapViewWrapper.bounds)
        mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.attributionButton.isHidden = true
        self.mapViewWrapper.addSubview(mapView)
        mapView.delegate = self
        mapView.zoomLevel = 15.0
        mapView.logoView.isHidden = true
        
        if Global.shared.userLocation != nil {
            mapView.centerCoordinate = Global.shared.userLocation
        }
        else {
            mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 38.2534189, longitude: -85.7551944)
        }
        mapView.allowsRotating = false
    }
    
    func setBottomTableData() {
        self.assetSingleSelectTableView.setData(self.trackerList)
        self.assetSingleSelectTableView.reloadData()
        self.bottomTableHC.constant = self.assetSingleSelectTableView.getHeight()
    }
    
    @IBAction func changeMapStyle(_ sender: Any) {
        if(mapStyle)
        {
            mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
        }
        else
        {
            mapView.styleURL = MGLStyle.satelliteStreetsStyleURL
        }
        mapStyle = !mapStyle
    }
    
    @IBAction func actionPrevDay(_ sender: Any) {
        self.replayStartDate = self.replayStartDate.date(plusDay: -1)
        self.replayEndDate =  self.replayEndDate.date(plusDay: -1)
        self.label_dateFromTO.text = self.replayStartDate.toString("MM/dd")
        self.btn_nextDay.isEnabled = true
        self.loadReplay(self)
    }
    
    @IBAction func actionNextDay(_ sender: Any) {
        self.replayStartDate = self.replayStartDate.date(plusDay: 1)
        self.replayEndDate =  self.replayEndDate.date(plusDay: 1)
        self.label_dateFromTO.text = self.replayStartDate.toString("MM/dd")
        print(replayEndDate.toString("MM.dd"))
        print("today:\(Date().toString("MM.dd"))")
        if replayStartDate.toString("MM.dd") == Date().toString("MM.dd") {
            self.btn_nextDay.isEnabled = false
        }
        self.loadReplay(self)
    }
    
    @IBAction func onShowMenu(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func zoom_Change(_ sender: Any) {
        mapView.zoomLevel = Double(zoom_Slider.value);
    }
    
    
    @IBAction func onBackwardAction(_ sender: Any) {
        selectRouteIndex = selectRouteIndex - 1
        if selectRouteIndex < 0 {
            return
        }
        if selectRouteIndex < onOffEvent_Array.count - 1 {
            self.btn_forwardR.isEnabled = true
        }
        if selectRouteIndex == 0 {
            self.btn_backwardR.isEnabled = false
        }
        let indexPath:IndexPath = IndexPath(row:selectRouteIndex, section:0)
        self.replayTripLogTableView.scrollToRow(at: indexPath, at: .top, animated: true)
        drawPath(routeIndex: selectRouteIndex)
        geoMarkerIndex = onOffEvent_Array[selectRouteIndex]
        slider.value = Float(geoMarkerIndex)
        self.btn_playR.setImage(UIImage(named: "ic_play"), for: .normal)
        self.animatingTimer = nil
    }
    
    @IBAction func onForwardAction(_ sender: Any) {
        selectRouteIndex = selectRouteIndex + 1
        if selectRouteIndex == onOffEvent_Array.count - 1 {
            self.btn_forwardR.isEnabled = false
        }
        if selectRouteIndex > 0 {
            self.btn_backwardR.isEnabled = true
        }
        let indexPath:IndexPath = IndexPath(row:selectRouteIndex, section:0)
        let rows = self.replayTripLogTableView.numberOfRows(inSection: 0)
        
        if selectRouteIndex < rows {
            self.replayTripLogTableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        
        self.info_table.isHidden = true
        self.topViewHC.constant = self.view.bounds.height - 42 - 55 - 73
        drawPath(routeIndex: selectRouteIndex)
        geoMarkerIndex = onOffEvent_Array[selectRouteIndex]
        slider.value = Float(geoMarkerIndex)
        self.btn_playR.setImage(UIImage(named: "ic_play"), for: .normal)
        self.animatingTimer = nil
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == allScrollView {
               self.topStackView.frame.origin.y = allScrollView.contentOffset.y
        }
    }
    
    func checkVerticle() {
        let v_lat = Double((self.geoAnnotation?.coordinate.latitude)!);
        let v_lon = Double((self.geoAnnotation?.coordinate.longitude)!);
        let s_top = Double(mapView.visibleCoordinateBounds.ne.latitude);
        let s_bottom = Double(mapView.visibleCoordinateBounds.sw.latitude);
        let s_left = Double(mapView.visibleCoordinateBounds.sw.longitude);
        let s_right = Double(mapView.visibleCoordinateBounds.ne.longitude);
        if(v_lat > s_top || v_lat < s_bottom || v_lon < s_left || v_lon > s_right)
        {
            let zoomlevel = mapView.zoomLevel
            mapView.centerCoordinate = (self.geoAnnotation?.coordinate)!;
            mapView.zoomLevel = zoomlevel
            mapView.removeAnnotation(geoAnnotation!)
            mapView.addAnnotation(geoAnnotation!)
        }
    }
    
    func loadAllDrivers() {
        self.view.endEditing(true)
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
//            self.view.makeToast("Weak cell phone signal is detected!".localized())
            SweetAlert().showAlert("", subTitle: "Weak cell phone signal is detected!", style: AlertStyle.error)
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
//                self.view.makeToast(error.message)
                SweetAlert().showAlert("", subTitle: error.message, style: AlertStyle.error)
            }
        }
    }
    
    @IBAction func loadReplay(_ sender: Any) {
        self.btn_forwardR.isEnabled = true
        self.btn_backwardR.isEnabled = false
        self.allScrollView.contentOffset.y = 0
        if self.info_table.isHidden {
            self.info_table.isHidden = false
            self.topViewHC.constant = self.topViewHC.constant - 46
        }
        self.slider.setValue(0.0, animated: true)
        
        self.selectRouteIndex = -1
        
        if selectedTracker == nil {
            self.view.makeToast("please select vehicle".localized())
            loadAllDrivers()
            return
        }
        
        let startTime = replayStartDate.getJustDay()
        let endTime = replayEndDate.getJustDay()
        
        self.label_dateFromTO.text = self.replayStartDate.toString("MM/dd")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        
        let startTimeString = dateFormatter.string(from: startTime) + ".000Z"
        let endTimeString = dateFormatter.string(from: endTime) + ".000Z"
        
        let reqInfo = URLManager.tripInfo()
        
        let parameters: Parameters = [
            "reportingId": selectedTracker?.reportingId ?? "",
            "startDate": startTimeString,
            "endDate": endTimeString,
            "tripDuration": "true",
            "alertReport": "true",
            "stateMileage": "true",
            "pinbypinReport": "true"
        ]
        
        
        let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
        
        request.responseString { dataResponse in
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.hideLoader()
                self.view.makeToast("server connect error".localized())
                return
            }
            
            if let annotiations = self.mapView.annotations {
                self.mapView.removeAnnotations(annotiations)
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            self.total_speeding = 0
            self.harsh_acce = 0
            self.harsh_dece = 0
            self.top_speed = 0
            self.total_stops = 0
            self.points = [CLLocationCoordinate2D]()
            self.speed_Array = [Double]()
            self.distance_Array = [Double]()
            self.onOffEvent_Array = [Int]()
            self.dateTime_Array = [Date]()
            self.speeding_Array = [Int]()
            self.accAlarm_Array = [Int]()
            self.pointIndex_Array = [Int]()
            self.velocityState_Array = [Bool]()
            self.harshAcce_Array = [Int]()
            self.harshDece_Array = [Int]()
            self.idling_Array = [Int]()
            self.plugOut_Array = [Int]()
            
            if(code == 200) {
                self.speed_Array = json["speed_Array"].arrayValue.map({ $0.doubleValue })
                self.speeding_Array = json["speeding_Array"].arrayValue.map({ $0.intValue })
                self.accAlarm_Array = json["accAlarm_Array"].arrayValue.map({ $0.intValue })
                self.dateTime_Array = json["dateTime_Array"].arrayValue.map({ $0.stringValue.toDate("yyyy-MM-dd'T'HH:mm:ss.SSSZ") ?? Date() })
                self.distance_Array = json["distance_Array"].arrayValue.map({ $0.doubleValue })
                self.harshDece_Array = json["harshDece_Array"].arrayValue.map({ $0.intValue })
                self.harshAcce_Array = json["harshAcce_Array"].arrayValue.map({ $0.intValue})
                self.idling_Array = json["idling_Array"].arrayValue.map({ $0.intValue })
                self.onOffEvent_Array = json["onOffEvent"].arrayValue.map({ $0.intValue })
                self.addressArray = json["addressArray"].arrayValue.map({ $0.stringValue })
                
                let latArray = json["lat_Array"].arrayValue.map({ $0.doubleValue })
                let lngArray = json["lng_Array"].arrayValue.map({ $0.doubleValue })
                let rpm_Array = json["RPM_Array"].arrayValue.map({ $0.intValue })
                
                for i in 0..<latArray.count {
                    let lat = latArray[i]
                    let lng = lngArray[i]
                    let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                    self.points.append(coord)
                }
            } else {
                let error = ErrorModel.parseJSON(json)
                print(error.message)
//                self.view.makeToast(error.message)
                SweetAlert().showAlert("Info", subTitle: error.message, style: AlertStyle.error)
            }
            
            /// below code is same as `animation_response()` function in android
            if self.points.count != 0 {
                self.btn_forwardR.isEnabled = true
                self.btn_playR.isEnabled = true
                self.slider.isHidden = false
                self.replayTripLogTableViewDataSource.dataClear()
                self.replayTripLogTableView.reloadData()
                self.drawPath()
                self.displayTrip()
            } else {
                self.replayTripLogTableHeight.constant = 0
                self.topViewHC.constant = self.view.bounds.height - 46 - 42 - 55
                
                
                self.btn_forwardR.isEnabled = false
                self.btn_playR.isEnabled = false
                self.slider.isHidden = true
                self.label_topSpeed.text = String(0)
                self.label_totalStops.text = String(0)
                self.replayTripLogTableViewDataSource.dataClear()
                self.replayTripLogTableView.reloadData()
            }
            
            self.hideLoader()
        }
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
            self.loadReplay(self)
        }
    }
    
    func drawPath(routeIndex: Int = -1) {
        var startIndex = 0
        var endIndex = self.points.count - 1
        
        if routeIndex >= 0 {
            startIndex = onOffEvent_Array[routeIndex]
            endIndex = (routeIndex != onOffEvent_Array.count - 1) ? onOffEvent_Array[routeIndex + 1] : accAlarm_Array.count - 1
        }
        
        print(startIndex)
        print(endIndex)
        
        self.total_speeding = 0
        self.harsh_acce = 0
        self.harsh_dece = 0
        self.top_speed = 0
        
        var displayPoints: [CLLocationCoordinate2D] = []
        var speedPoints: [CLLocationCoordinate2D] = []
        
        var prev_speedState = -1
        var speedState = 0
        let metricScale = Global.getDistanceUnit() == "miles" ? 1 : 1.60934
        
        if let annotiations = self.mapView.annotations {
            self.mapView.removeAnnotations(annotiations)
        }
        
        for index in startIndex...endIndex {
            let point = points[index]
            let currentTime = dateTime_Array[index].toString("MM/dd/yyyy hh:mm:ss a")
            
            if point.latitude == 0.0, point.longitude == 0.0 {
                continue
            }
            
            if top_speed < speed_Array[index] {
                self.top_speed = speed_Array[index]
            }
            
            speedState = getSpeedState(speed: speed_Array[index])
            if prev_speedState == -1 {
                prev_speedState = getSpeedState(speed: speed_Array[index])
            }
            
            if( speedState == prev_speedState) {
                speedPoints.append(point)
                prev_speedState = speedState
            } else {
                speedPoints.append(point)
                let speedline = MGLPolyline(coordinates: speedPoints, count: UInt(speedPoints.count))
                switch prev_speedState {
                case 0:
                    speedline.title = "45"
                    break;
                case 1:
                    speedline.title = "60"
                    break;
                case 2:
                    speedline.title = "80"
                    break;
                case 3:
                    speedline.title = "over"
                    break
                default:
                    speedline.title = "60"
                }
                
                mapView.addAnnotation(speedline)
                speedPoints.removeAll()
                speedPoints.append(point)
                prev_speedState = speedState
            }
            
            displayPoints.append(point)
            
            if (speeding_Array.count > index + 1 && speeding_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = point
                annotation.title = "speeding".localized()
                mapView.addAnnotation(annotation)
                self.total_speeding += 1
            }
            if (harshAcce_Array.count > index + 1 && harshAcce_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = point
                annotation.title = "harshAcce".localized()
                mapView.addAnnotation(annotation)
                self.harsh_acce += 1
            }
            if (harshDece_Array.count > index + 1 && harshDece_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = point
                annotation.title = "harshDece".localized()
                mapView.addAnnotation(annotation)
                self.harsh_dece += 1
            }
            if (idling_Array.count > index + 1 && idling_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = point
                annotation.title = "idling".localized()
                mapView.addAnnotation(annotation)
            }
            if ((accAlarm_Array.count > index + 1) && accAlarm_Array[index] == -1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = point
                annotation.title = "stop at \(currentTime)"
                annotation.subtitle = String(selectRouteIndex+1)
                mapView.addAnnotation(annotation)
                self.total_stops += 1
            }
            if ((accAlarm_Array.count > index + 1) && accAlarm_Array[index] == 1) {
                let annotation = MGLPointAnnotation()
                annotation.coordinate = point
                annotation.title = "start".localized()
                annotation.subtitle = String(selectRouteIndex+1)
                mapView.addAnnotation(annotation)
            }
        }
        
        self.displayPoints = displayPoints
        
        let speedline = MGLPolyline(coordinates: speedPoints, count: UInt(speedPoints.count))
        switch prev_speedState {
        case 0:
            speedline.title = "45"
            break;
        case 1:
            speedline.title = "60"
            break;
        case 2:
            speedline.title = "80"
            break;
        case 3:
            speedline.title = "over"
            break
        default:
            speedline.title = "60"
        }
        self.mapView.addAnnotation(speedline)
        
        let line = MGLPolyline(coordinates: displayPoints, count: UInt(displayPoints.count))
        mapView.camera = mapView.cameraThatFitsCoordinateBounds(line.overlayBounds, edgePadding: UIEdgeInsets(top: 90, left: 60, bottom: 90, right: 60))
        if mapView.zoomLevel > 15 {
            mapView.zoomLevel = 15
        }
        
        let _ = {
            self.geoAnnotation = CustomAnnotation()
            if let point = displayPoints.first {
                self.geoAnnotation?.coordinate = point
                self.geoAnnotation?.title = "geo".localized()
            }
            
            mapView.addAnnotation(self.geoAnnotation!)
        }()
        
        self.label_topSpeed.text = String(format: "%.1f",self.top_speed * metricScale)
        if selectRouteIndex >= 0, selectRouteIndex < velocityState_Array.count, !velocityState_Array[selectRouteIndex] {
            self.label_topSpeed.text = "0"
        }
        if routeIndex == -1 {
            geoMarkerIndex = 0
            
            zoom_Slider.value = Float(mapView.zoomLevel)
            slider.minimumValue = 0
            slider.maximumValue = Float(displayPoints.count - 1)
            slider.setValue(0.0, animated: true)
        }
    }
    
    func displayTrip() {
        let metricScale = Global.getDistanceUnit() == "miles" ? 1 : 1.60934
        let distUnit = metricScale == 1 ? " miles" : " km"
        
        var eventNum = 0
                
        for index in 0..<onOffEvent_Array.count {
            var distance = 0.0
            var tripStartIndex = onOffEvent_Array[index]
            var tripEndIndex = (index != onOffEvent_Array.count - 1) ? onOffEvent_Array[index + 1] : accAlarm_Array.count - 1
            print(tripStartIndex,tripEndIndex)
            if tripStartIndex == tripEndIndex {
                break
            }
            // get maxSpeed of the trip segment.
            var maxSpeed = 0.0
            for i in tripStartIndex..<tripEndIndex+1 {
                maxSpeed = max(maxSpeed, speed_Array[i])
            }
            let timeStart = dateTime_Array[tripStartIndex]
            let timeStartShort = timeStart.toString("hh:mm a")
            let timeEnd = dateTime_Array[tripEndIndex]
            var timeEndShort = timeEnd.toString("hh:mm a")
            var durationString: String? = nil
            
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.year,.month,.day,.hour,.minute]
            formatter.unitsStyle = .full
            durationString = formatter.string(from: timeStart, to: timeEnd) ?? ""
                
            if durationString == "0 minutes" {
                durationString = ""
            }
            if tripEndIndex < distance_Array.count {
                distance = distance_Array[tripEndIndex] - distance_Array[tripStartIndex]
            } else {
                distance = 0.0
            }
            
            var timeRange = timeStartShort
            if timeEndShort != "" {
                timeRange += " - " + timeEndShort
            }
            
            if accAlarm_Array[tripStartIndex] == 1, let _duration = durationString {
                let distanceString = String(format: "%.2f", distance * metricScale)
                
                let maxSpeedString = String(format: "%.1f", maxSpeed)
                
                if eventNum < addressArray.count {
                    replayTripLogTableViewDataSource.insertData(ReplayTripLogModel(header: timeRange, range: "Travel " + distanceString + distUnit + " " + _duration, detail: addressArray[eventNum], state: 0, maxSpeed: maxSpeedString))
                } else {
                    replayTripLogTableViewDataSource.insertData(ReplayTripLogModel(header: timeRange, range: "Travel " + distanceString + distUnit + " " + _duration, detail: "unknown", state: 0, maxSpeed: maxSpeedString))
                }
                eventNum += 1
            } else if accAlarm_Array[tripStartIndex] == -1, let _duration = durationString {
                if eventNum < addressArray.count {
                    replayTripLogTableViewDataSource.insertData(ReplayTripLogModel(header: timeRange, range: "Stop " + _duration, detail: addressArray[eventNum], state: 1, maxSpeed: "0.0"))
                } else {
                    replayTripLogTableViewDataSource.insertData(ReplayTripLogModel(header: timeRange, range: "Stop " + _duration, detail: "unknown", state: 1, maxSpeed: "0.0"))
                }
                
                eventNum += 1
            }
            
            if idling_Array[tripStartIndex] == 1 {
                eventNum += 1
            }
            
            /// For divide into Route
            if index < accAlarm_Array.count - 1 {
                if accAlarm_Array[index] == -1 {
                    pointIndex_Array.append(index)
                    velocityState_Array.append(false)
                } else if accAlarm_Array[index] == 1 {
                    pointIndex_Array.append(index)
                    velocityState_Array.append(true)
                }
            }
        }
        
        self.replayTripLogTableView.reloadData()
        if replayTripLogTableViewDataSource.count() != 0 {
            self.btn_forwardR.isEnabled = true
            self.replayTripLogTableHeight.constant = 100
            self.topViewHC.constant = self.view.bounds.height - 46 - 42 - 55 - 100
            
            let indexPath:IndexPath = IndexPath(row:0, section:0)
            self.replayTripLogTableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        else {
            self.btn_forwardR.isEnabled = false
            self.replayTripLogTableHeight.constant = 0
            self.topViewHC.constant = self.view.bounds.height - 46 - 42 - 55
        }
        
        
        
        self.label_totalStops.text = String(self.total_stops)
        self.label_topSpeed.text = String(format: "%.1f",self.top_speed * metricScale)
        
        routeControlView.isHidden = false
    }
    
    func getSpeedState(speed: Double) -> Int{
        if (speed <= 45) {
            return 0
        }
        else if (speed <= 60) {
            return 1
        }
        else if (speed <= 80) {
            return 2
        } else {
            return 3
        }
    }
    
    func startAnimation() {
        if animatingTimer != nil {
            animatingTimer!.invalidate()
        }
        
        animatingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            if (self.geoMarkerIndex >= self.displayPoints.count && self.selectRouteIndex == -1) || (self.selectRouteIndex != -1 && self.geoMarkerIndex >= self.displayPoints.count + self.onOffEvent_Array[self.selectRouteIndex]){
                timer.invalidate()
                print("end")
                self.btn_playR.setImage(UIImage(named: "ic_play"), for: .normal)
                self.animatingTimer = nil
                return
            }
            
            self.showReplayPointOfIndex()
            self.geoMarkerIndex = self.geoMarkerIndex + 1
        })
        
    }
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }
    
    func getBearingBetweenTwoPoints1(point1 : CLLocationCoordinate2D, point2 : CLLocationCoordinate2D) -> CGFloat {
        
        let lat1 = degreesToRadians(degrees: point1.latitude)
        let lon1 = degreesToRadians(degrees: point1.longitude)
        
        let lat2 = degreesToRadians(degrees: point2.latitude)
        let lon2 = degreesToRadians(degrees: point2.longitude)
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return CGFloat(radiansBearing)
    }
    
    func showReplayPointOfIndex() {
        if (self.geoMarkerIndex >= self.displayPoints.count && selectRouteIndex == -1) || (selectRouteIndex != -1 && self.geoMarkerIndex >= self.displayPoints.count + onOffEvent_Array[selectRouteIndex]) {
            if animatingTimer != nil {
                animatingTimer!.invalidate()
            }
            self.btn_playR.setImage(UIImage(named: "ic_play"), for: .normal)
        }
        if geoMarkerIndex >= speed_Array.count {
            return
        }
        var speed = min(speed_Array[geoMarkerIndex], 160)
        var dateString = dateTime_Array[geoMarkerIndex]
//        if selectRouteIndex != -1 {
//            speed = min(speed_Array[geoMarkerIndex], 160)
//            dateString = dateTime_Array[geoMarkerIndex]
//        }
        print("ani",displayPoints.count,geoMarkerIndex)
        var point_index = geoMarkerIndex
        if selectRouteIndex != -1 {
            point_index = geoMarkerIndex-onOffEvent_Array[selectRouteIndex]
        }
        if geoAnnotation != nil {
            self.mapView.removeAnnotation(geoAnnotation!)
            
            self.geoAnnotation = CustomAnnotation()
            self.geoAnnotation!.coordinate = self.displayPoints[point_index!]
            self.geoAnnotation!.title = "geo"
            self.geoAnnotation!.heading = getBearingBetweenTwoPoints1(point1: self.displayPoints[point_index!], point2: self.displayPoints[(point_index! + 1) % self.displayPoints.count])
            
            mapView.addAnnotation(self.geoAnnotation!)
        }
        self.setSpeed(Int(speed))
        self.labelGageDate.text = dateString.toString("MM/dd HH:mm")
        
        slider.value = Float(geoMarkerIndex)
        checkVerticle();
    }
    
    func setSpeed(_ speed: Int) {
        let angle = CGFloat.pi / 5 * 8 * CGFloat(speed) / 160
        let tr = CGAffineTransform(rotationAngle: angle)
        print(speed,tr)
        labelSpeed.text = speed.toString()
        speedIndicator.transform = tr
    }
    
    @IBAction func onBtnPlayPause(_ sender: Any) {
        if animatingTimer == nil {
            self.btn_playR.setImage(UIImage(named: "ic_pause"), for: .normal)
            startAnimation()
        } else {
//            self.mapView.maximumZoomLevel = 30
            animatingTimer!.invalidate()
            animatingTimer = nil
            self.btn_playR.setImage(UIImage(named: "ic_play"), for: .normal)
        }
    }
    
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        let progressChangedValue = Int(slider.value)
        self.geoMarkerIndex = progressChangedValue
        if selectRouteIndex != -1 && self.geoMarkerIndex < onOffEvent_Array[selectRouteIndex] {
            self.geoMarkerIndex = onOffEvent_Array[selectRouteIndex]
        }
        self.showReplayPointOfIndex()
    }
}


// MGLMapViewDelegate delegate
extension ReplayViewController: MGLMapViewDelegate {
    func mapView(mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return UIColor.black
    }
    
    // Use the default marker. See also: our view annotation or custom marker examples.
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if( annotation.title == "45") {
            return UIColor(hexInt: 0xF96F00)
        }
        else if ( annotation.title == "60")
        {
            return .blue
        }
        else if ( annotation.title == "80")
        {
            return .green
        }
        else if ( annotation.title == "over")
        {
            return .red
        }
        return UIColor(red: 0.0, green: 0.0, blue: 0.502, alpha: 1.0)
    }
    
    func mapView(_ mapView: MGLMapView, didAdd annotationViews: [MGLAnnotationView])
    {
        
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView?
    {
        let title = annotation.title ?? ""
        if title == "geo" {
            let annotation = annotation as! CustomAnnotation
            let kk = MGLAnnotationView.init(annotation: annotation, reuseIdentifier: "pos")
            kk.frame = CGRect.init(x: 0, y: 0, width: 45, height: 45)
            kk.layer.cornerRadius = (kk.frame.size.width) / 2
            kk.layer.borderWidth = 2.0
            kk.layer.borderColor = Global.annotationBorderColor(color: self.selectedTracker?.color ?? "").cgColor
            kk.backgroundColor = Global.annotationFillColor(color: self.selectedTracker?.color ?? "")
            let label = UILabel()
            label.text = self.selectedTracker?.driverName ?? ""
            if let text = label.text, text.count > 5 {
                label.text = label.text?.substring(from: 0, to: 5)
            }
            label.font = UIFont(name: "Symbol", size: 11.0)
            label.textAlignment = .center
            label.font = UIFont.boldSystemFont(ofSize: 11.0)
            if kk.backgroundColor == .white {
                label.textColor = UIColor.black
            } else {
                label.textColor = UIColor.white
            }
            label.frame = CGRect(x: 3, y: 4, width: 40, height: 40)
            kk.addSubview(label)
//            let iv = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 40, height: 40))
//            let rotation = annotation.heading!
//            var geoImage: UIImage! = UIImage(named: "cartoprightsmall")
//            geoImage = geoImage.image(withRotation: 3.141592/2.0 - rotation)
//            iv.image = geoImage
//            kk.addSubview(iv)
            return kk
        }
        else if title?.range(of: "stop") != nil && annotation.subtitle != "all route"{
            let reuseIdentifier = title
            // For better performance, always try to reuse existing annotations.
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier ?? "stop")
            // If there’s no reusable annotation view available, initialize a new one.
            if annotationView == nil {
                annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
                
                let iv = UIImageView.init(frame: CGRect.init(x: 0, y: 8, width: 20 , height: 20))
                iv.image = stopImage.scaleImageToFitSize(size: CGSize(width:20,height:20))
                annotationView?.addSubview(iv)
                
                let view = UIView()
                view.frame = CGRect(x: 12, y: 0, width: 16, height: 16)
                view.layer.cornerRadius = (view.frame.size.width) / 2
                view.layer.borderWidth = 1.0
                view.layer.borderColor = UIColor.white.cgColor
                view.backgroundColor = UIColor.red
                
                let label = UILabel()
                label.text = annotation.subtitle ?? "?"
                label.font = UIFont.boldSystemFont(ofSize: 9.5)
                label.textAlignment = .center
                label.textColor = UIColor.white
                label.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
                view.addSubview(label)
                
                //annotationView?.addSubview(view)
            }
            return annotationView
        }
        else if title?.range(of: "start") != nil && annotation.subtitle != "all route"{
            let reuseIdentifier = title
            // For better performance, always try to reuse existing annotations.
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier ?? "start")
            // If there’s no reusable annotation view available, initialize a new one.
            if annotationView == nil {
                annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 28, height: 28)
                
                let iv = UIImageView.init(frame: CGRect.init(x: 0, y: 8, width: 20 , height: 20))
                iv.image = startImage.scaleImageToFitSize(size: CGSize(width:20,height:20))
                annotationView?.addSubview(iv)
                
                let view = UIView()
                view.frame = CGRect(x: 12, y: 0, width: 16, height: 16)
                view.layer.cornerRadius = (view.frame.size.width) / 2
                view.layer.borderWidth = 1.0
                view.layer.borderColor = UIColor.white.cgColor
                view.backgroundColor = UIColor(hexInt: 0x63cf0d)
                
                let label = UILabel()
                label.text = annotation.subtitle ?? "?"
                label.font = UIFont.boldSystemFont(ofSize: 9.5)
                label.textAlignment = .center
                label.textColor = UIColor.white
                label.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
                view.addSubview(label)
                
                //annotationView?.addSubview(view)
            }
            return annotationView
        }
        return nil;
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation)
    {
        
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        
        let title = annotation.title ?? ""
        if title == "speeding" {
            return MGLAnnotationImage(image: speedingImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "speedingimage")
        } else if title == "harshAcce" {
            return MGLAnnotationImage(image: harshacceImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "harshacceicon")
        } else if title == "harshDece" {
            return MGLAnnotationImage(image: harshdeceImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "harshdeceicon")
        } else if title == "idling" {
            return MGLAnnotationImage(image: idlingImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "idlingicon")
        }
        else if title == "arrow" {
            let annotation = annotation as! CustomAnnotation
            let rotation = annotation.heading!
            var geoImage: UIImage! = UIImage(named: "greenarrow")
            geoImage = geoImage.image(withRotation: 3.141592/2.0 - rotation)
            let reuseIdentifier = "arrow-\(annotation.coordinate.longitude)"
            
            return MGLAnnotationImage(image: geoImage, reuseIdentifier: reuseIdentifier)
        }
        else if title?.range(of: "start") != nil && annotation.subtitle == "all route" {
            return MGLAnnotationImage(image: startImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "starticon")
        }
        else if title?.range(of: "stop") != nil && annotation.subtitle == "all route" {
            return MGLAnnotationImage(image: stopImage.scaleImageToFitSize(size: CGSize(width:25,height:25)), reuseIdentifier: "stopicon")
        }
        else
        {
            return nil
        }
    }
    
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        let title = annotation.title ?? ""
        if title?.range(of: "stop") != nil {
            return true
        }
        else {
            return false
        }
    }
}
