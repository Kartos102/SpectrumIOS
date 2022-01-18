//
//  MonitorViewController.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Mapbox
import MapboxGeocoder
import SwiftyUserDefaults
import MapKit
import CoreLocation
import SCLAlertView
import AudioToolbox
import TwilioChatClient

class AddressAnnotation: MGLPointAnnotation {
    var displayFlag: Bool = false
}

//let MapboxAccessToken = "pk.eyJ1Ijoid29vbGVlMTA2IiwiYSI6ImNqbzNjdWRwbTBxcjEzcHFuOWwxdGs5NXIifQ.ZDt6AmvMcsM3SeT5zy8GBg"
let MapboxAccessToken = "sk.eyJ1IjoieW9uZ3NoZW5nbGlhbiIsImEiOiJjam93dmx0aGoyMXkzM3BybnYzY2MzcjRoIn0.FjG6XWvZuM14iwHTZENTDQ"

class MonitorViewController: ViewControllerWaitingResult, UIScrollViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    static var instance: MonitorViewController!
    static func getNewInstance() -> UIViewController {
        if instance == nil {
            let storyboardName = "Main"
            let viewControllerIdentifier = "MonitorViewController"
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier) as! MonitorViewController
            return vc
        } else {
            return instance
        }
    }
    
    var parentVC: UIViewController?
    
    @IBAction func onLandmarkCancel(_ sender: Any) {
        UIView.animate(withDuration: 0.2, animations: {
            self.landmarkDialog.alpha = 0
            
        }) { (value) in
            self.landmarkDialog.isHidden = true
            self.view.endEditing(true)
        }
    }
    @IBAction func onSaveLandmark(_ sender: Any) {
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!")
            return
        }
        let name = txtLandmarkName.text ?? ""
        let type = txtlandmarkType.text ?? ""
        let lat = txtLandmarkLat.text ?? ""
        let lon = txtLandmarkLon.text ?? ""
        if name == "" {
            self.view.makeToast("Please input landmark name")
        }
        self.onLandmarkCancel(self)
        let landmark = LandmarkModel(name,type,lat,lon)
        Global.shared.landmarkList.append(landmark)
        var landmarks:[[String:String]] = []
        for i in 0..<Global.shared.landmarkList.count {
            let landmark = Global.shared.landmarkList[i]
            landmarks.append(["name":landmark.name,"type":landmark.type,"lat":landmark.lat,"lng":landmark.lng])
        }
        
        self.view.endEditing(true)
        
        let reqInfo = URLManager.addLandmark()
        var request = URLRequest(url: URL(string: "https://api.spectrumtracking.com/v1/users/landmark")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Global.shared.csrfToken, forHTTPHeaderField: "X-CSRFToken")
        request.httpBody = try! JSONSerialization.data(withJSONObject: landmarks)
        
        
        
        let _request = Alamofire.request(request)
        
        _request.responseString { dataResponse in
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.view.makeToast("you have successfully add landmark")
                self.showLandmarks()
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    @IBOutlet weak var txtLandmarkLat: CustomTextField!
    @IBOutlet weak var txtLandmarkLon: CustomTextField!
    @IBAction func onLandmarkType(_ sender: Any) {
        self.landmark_TypeDropDown.show()
    }
    @IBOutlet weak var txtlandmarkType: UILabel!
    @IBOutlet weak var txtLandmarkName: CustomTextField!
    @IBOutlet var mapViewFrameView: UIView!
    @IBOutlet var velocityTableView: VelocityTableView!
    @IBOutlet var bottomTableHC: NSLayoutConstraint!
    @IBOutlet var indicator: UIActivityIndicatorView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var zoom_Slider: VSSlider!
    @IBOutlet var velocityTableHC: NSLayoutConstraint!
    @IBOutlet var rateView: UIView!
    @IBOutlet var update_txtDriverName: UITextField!
    @IBOutlet var update_txtVehicleName: UITextField!
    @IBOutlet var bottomTableView: UIView!
    @IBOutlet var table_handler: UIImageView!
    @IBOutlet var update_txtColor: UITextField!
    @IBOutlet var velocityTableHeader: UIView!
    @IBOutlet var update_dialog: UIView!
    @IBOutlet var replayRouteView: UIView!
    @IBOutlet var velocityView: UIView!
    @IBOutlet weak var unreadCountLabel: UILabel!
    @IBOutlet weak var acceptRejectChatInvitationContainerView: UIView!
    @IBOutlet weak var chatInvitationDescLabel: UILabel!
    @IBOutlet var assetMultiSelectTableView: AssetMultiSelectMoniterTableView! {
        didSet {
            assetMultiSelectTableView.parentVC = self
        }
    }
    
    @IBOutlet weak var landmarkDialog: UIView!
    @IBOutlet weak var toolsButtonContainerView: UIView!
    
    @IBAction func onBtnLandmark(_ sender: Any) {
        
        SweetAlert().showAlert("Info", subTitle: "long press the screen to add a landmark", style: AlertStyle.success)
    }
    var stopLoading: Bool = false
    var firstAppearFlag: Bool = true
    var dialog_flag: Bool = false
    var uploadAssetId: String!
    var uploadTrackerId: String!
    var mapView: MGLMapView!
    
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    var trackerList: [TrackerModel] = []
    var selectedTrackers: [TrackerModel] = []
    
    var carAnnotations: [MGLPointAnnotation]!
    var normalAnnotations:[MGLPointAnnotation]!
    var landmarkAnnotations:[MGLPointAnnotation]!
    var polyLines: [MGLPolyline]!
    var update_trackerId: String!
    var update_assetId: String!
    var mapStyle: Bool! = false
    
    var userAnnotation: MGLPointAnnotation!
    var showUserLocationFlag: Bool! = false {
        didSet {
            if showUserLocationFlag {
                showCarsOnMap(shouldRecenter: true, shouldCenterToCurrentLocation: true)
            }
        }
    }
    var currentUserLocation: CLLocationCoordinate2D? = nil {
        didSet {
            guard userAnnotation != nil else { return }
            
            if let location = currentUserLocation {
                userAnnotation.coordinate = location
            } else {
                mapView.removeAnnotation(userAnnotation)
            }
        }
    }
    
    var carImage = UIImage(named: "locationcirclesmall")!
    var pinImage = UIImage(named: "pin")!
    var homeImage = UIImage(named: "landmark_home")!
    var officeImage = UIImage(named: "landmark_office")!
    var mallImage = UIImage(named: "landmark_mall")!
    var schoolImage = UIImage(named: "landmark_school")!
    var warehouseImage = UIImage(named: "landmark_warehouse")!
//    var userImage: UIImage! = UIImage(named: "user_icon")
    var userImage = UIImage(named: "ic_marker_blue")!
    var defaultZoom = 15.0
    let update_ColorDropDown = DropDown()
    let landmark_TypeDropDown = DropDown()
    var chatInvitationChannel: TCHChannel? = nil
    
    var isLoadingAllDrivers = false
    var stop_task : DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MonitorViewController.instance = self
        
        initMapView()
        carAnnotations = [MGLPointAnnotation]()
        polyLines = [MGLPolyline]()
        normalAnnotations = [MGLPointAnnotation]()
        landmarkAnnotations = [MGLPointAnnotation]()
        trackerList = [TrackerModel]()
        selectedTrackers = [TrackerModel]()
        
        Global.shared.AllTrackerList.removeAll()
        
        if Global.shared.app_user == nil {
            getUserInfo()
        } else {
            loadAllDrivers()
        }
        
        let phoneTrackingFlag = Defaults[.phoneTracking] ?? false
        
        locationManager2 = CLLocationManager()
        locationManager2.delegate = geofencingManager
        locationManager2.disallowDeferredLocationUpdates()
        locationManager2.allowsBackgroundLocationUpdates = true
        locationManager2.pausesLocationUpdatesAutomatically = false
        locationManager2.requestAlwaysAuthorization()
        
        NotificationCenter.default.addObserver(self, selector: #selector(locationChanged(_:)), name: NSNotification.Name("NotificationCurrentLocationChanged"), object: nil)
        
        if phoneTrackingFlag {
            locationManager2.startUpdatingLocation()
        }
        
        self.assetMultiSelectTableView.isScrollEnabled = false
        self.scrollView.panGestureRecognizer.delaysTouchesBegan = true
        self.scrollView.panGestureRecognizer.addTarget(self, action: #selector (self.panHandle (_:)))
        self.scrollView.delegate = self
       
        let gesture1 = UITapGestureRecognizer(target: self, action:  #selector (self.someAction1 (_:)))
        gesture1.cancelsTouchesInView = false
        self.assetMultiSelectTableView.addGestureRecognizer(gesture1)
        
        update_ColorDropDown.anchorView = self.update_txtColor
        update_ColorDropDown.dataSource = ["RED", "ORANGE", "WHITE", "GREY", "BLACK", "SILVER", "BLUE", "GREEN"]
        update_ColorDropDown.selectionAction = { index, item in
            self.update_txtColor.text = item
        }
        update_ColorDropDown.width = update_ColorDropDown.anchorView!.plainView.bounds.width
        update_ColorDropDown.bottomOffset = CGPoint(x: 0, y: update_ColorDropDown.anchorView!.plainView.bounds.height + 4)
        update_ColorDropDown.topOffset = CGPoint(x: 0, y: -(update_ColorDropDown.anchorView!.plainView.bounds.height + 4))
        
        landmark_TypeDropDown.anchorView = self.txtlandmarkType
        landmark_TypeDropDown.dataSource = ["Home", "Office", "Warehouse", "School", "Mall"]
        landmark_TypeDropDown.selectionAction = { index, item in
            self.txtlandmarkType.text = item
        }
        landmark_TypeDropDown.width = landmark_TypeDropDown.anchorView!.plainView.bounds.width
        landmark_TypeDropDown.bottomOffset = CGPoint(x: 0, y: landmark_TypeDropDown.anchorView!.plainView.bounds.height)
        landmark_TypeDropDown.topOffset = CGPoint(x: 0, y: -(landmark_TypeDropDown.anchorView!.plainView.bounds.height))
        self.txtlandmarkType.text = "Home"
        table_handler.image = table_handler.image?.withRenderingMode(.alwaysTemplate)
        table_handler.tintColor = UIColor.gray
        print("start")
        setStopUpload()
        
        unreadCountLabel.layer.cornerRadius = 8
        unreadCountLabel.layer.borderColor = UIColor.white.cgColor
        unreadCountLabel.layer.borderWidth = 1.0
        
        
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
                if json["landmarks"].exists() {
                    let landmarks = json["landmarks"].arrayValue
                    Global.shared.landmarkList.removeAll()
                    for i in 0..<landmarks.count {
                        let landmark = landmarks[i]
                        if landmark["lat"].exists() {
                        Global.shared.landmarkList.append( LandmarkModel(landmark["name"].stringValue,landmark["type"].stringValue,landmark["lat"].stringValue,landmark["lng"].stringValue))
                        }
                    }
                    self.showLandmarks()
                }
            }
        }
    }
    func showLandmarks() {
        mapView.removeAnnotations(landmarkAnnotations)
        landmarkAnnotations.removeAll()
        for i in 0..<Global.shared.landmarkList.count {
            let landmark = Global.shared.landmarkList[i]
            let landmark_annotation = MGLPointAnnotation()
            landmark_annotation.title = landmark.type
            landmark_annotation.coordinate = CLLocationCoordinate2D(latitude: Double(landmark.lat)!,
                                                                    longitude: Double(landmark.lng)!)
            mapView.addAnnotation(landmark_annotation)
            landmarkAnnotations.append(landmark_annotation)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopLoading = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        geofencingManager.notifyServerFrequency = Defaults[.uploadDelay] ?? 30
        
        for tracker in self.trackerList {
            tracker.isSelected = Global.shared.selectedTrackerIds.contains(tracker._id)
        }
        
        if stopLoading {
            stopLoading = false
            print("restart")
            loadAllDrivers()
        }
        
        self.updateUnreadCount()
        self.checkChatInvitation()
        self.doAuth()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initMapView() {
        self.mapView = MGLMapView(frame: mapViewFrameView.bounds)
        
        mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.maximumZoomLevel = 30
        mapView.attributionButton.isHidden = true
        mapView.contentInset = UIEdgeInsets(top:60,left:0,bottom:0,right:0)
        mapView.updateConstraints()
        mapView.zoomLevel = defaultZoom
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 38.2534189, longitude: -85.7551944)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapSingleTap(sender:)))
        let longTap = UILongPressGestureRecognizer (target: self, action: #selector(handleMapLongTap(sender:)))
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
        mapView.addGestureRecognizer(longTap)
        self.mapViewFrameView.addSubview(mapView)
        mapView.delegate = self
        geocoder = Geocoder(accessToken: MapboxAccessToken)
    }
    
    @IBAction func showUserLocation(_ sender: UIButton) {
        showUserLocationFlag = !showUserLocationFlag
        if !showUserLocationFlag {
            if userAnnotation != nil {
                mapView.removeAnnotation(userAnnotation)
            }
        }
        else {
            if userAnnotation == nil {
                userAnnotation = MGLPointAnnotation()
                userAnnotation.title = "user"
                if let location = currentUserLocation {
                    userAnnotation.coordinate = location
                    mapView.addAnnotation(userAnnotation)
                }
            } else {
                mapView.addAnnotation(userAnnotation)
            }
        }
    }
    
    @IBAction func onUpdateVehicle(_ sender: Any) {
        if(self.update_txtDriverName.text == "") {
            self.view.makeToast("please enter driver name")
            return
        }
        
        if(self.update_txtVehicleName.text == "") {
            self.view.makeToast("please enter vehicle name")
            return
        }
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!")
            return
            // do some tasks..
        }
        
        self.view.endEditing(true)
        
        let reqInfo = URLManager.modifyTracker()
        let parameters: Parameters = [
            "id": String(self.update_trackerId),
            "plateNumber": self.update_txtVehicleName.text ?? "",
            "driverName": self.update_txtDriverName.text ?? "",
            "color": self.update_txtColor.text ?? ""
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
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.view.makeToast("update success")
                
                if let index = self.trackerList.firstIndex(where: { $0._id == self.update_trackerId }), index >= 0 {
                    self.trackerList[index].plateNumber = self.update_txtVehicleName.text ?? ""
                    self.trackerList[index].driverName = self.update_txtDriverName.text ?? ""
                    self.trackerList[index].color = self.update_txtColor.text ?? ""
                    self.assetMultiSelectTableView.reloadData()
                }
                
                self.onUpdateCancel(self)
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
            
        }
    }
    
    @IBAction func onUpdateCancel(_ sender: Any) {
        UIView.animate(withDuration: 0.2, animations: {
            self.update_dialog.alpha = 0
            
        }) { (value) in
            self.update_dialog.isHidden = true
            self.view.endEditing(true)
        }
    }
    
    @IBAction func actionVShow(_ sender: UIButton) {
        self.velocityTableView.isHidden = !self.velocityTableView.isHidden
        self.velocityTableHeader.isHidden = !self.velocityTableHeader.isHidden
        if self.velocityTableView.isHidden {
//            sender.setImage(UIImage(named: "btn_tableshow"),for:.normal)
            sender.setTitle("SHOW INFO", for: .normal)
        }
        else {
            sender.setTitle("HIDE INFO", for: .normal)
//            sender.setImage(UIImage(named: "btn_tablehide"),for:.normal)
        }
    }
    
    @IBAction func onUpdateColorShow(_ sender: Any) {
        self.update_ColorDropDown.show()
    }
    
    @IBAction func zoomChanged(_ sender: Any) {
        mapView.zoomLevel = Double(zoom_Slider.value)
        self.scrollView.isScrollEnabled = true
    }
    	
    @IBAction func onReferAction(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/refer.html") else {return}
        UIApplication.shared.open(url)
    }
    
    @IBAction func onRateAction(_ sender: Any) {
        guard let url = URL(string: "https://www.amazon.com/review/review-your-purchases/?asin=B07BV4HBST") else {return}
        UIApplication.shared.open(url)
    }
    
    @IBAction func onFeedbackAction(_ sender: Any) {
        guard let url = URL(string: "https://spectrumtracking.com/feedback.html") else {return}
        UIApplication.shared.open(url)
    }
    
    @IBAction func changeMapStyle(_ sender: Any) {
        if(mapStyle) {
            mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
            let pCamera = mapView.camera
            pCamera.pitch = 45.0
            mapView.setCamera(pCamera, animated: false)
           // btn_style.setImage(UIImage(named: "mapstyle_satellite"),for:.normal)
        }
        else
        {
            mapView.styleURL = MGLStyle.satelliteStreetsStyleURL
            let pCamera = mapView.camera
            pCamera.pitch = 0.0
            mapView.setCamera(pCamera, animated: false)
           // btn_style.setImage(UIImage(named: "mapstyle_street"),for:.normal)
        }
        mapStyle = !mapStyle
    }
    
    @IBAction func geofenceButtonTapped(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditGeofenceVC") as! EditGeofenceVC
        
        vc.tracker = self.selectedTrackers.first
        vc.defaultCenter = mapView.camera.centerCoordinate
        vc.defaultZoom = mapView.zoomLevel
        
        MainContainerViewController.instance.showOverlay(vc: vc)
    }
    
    @IBAction func toolsButtonTapped(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ToolsVC") as! ToolsVC
        
        MainContainerViewController.instance.showOverlay(vc: vc)
    }
    
    @objc func panHandle(_ gestureRecognizer:UIPanGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.zoom_Slider)
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            if touchLocation.y >= 0 && touchLocation.x >= 0{
                self.scrollView.isScrollEnabled = false
            }
            else {
                self.scrollView.isScrollEnabled = true
            }
        }
    }
    
    @objc func someAction1(_ sender:UITapGestureRecognizer){
        self.scrollView.isScrollEnabled = true
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.mapView.frame.origin.y = scrollView.contentOffset.y
    }
    
    @objc func handleMapSingleTap(sender: UITapGestureRecognizer) throws {
        print("single")
    }
    
    @objc func handleMapLongTap(sender: UITapGestureRecognizer) throws {
        let location = sender.location(in: self.mapView)
        print("click!!!")
//        if self.normalAnnotations?.count != nil{
//            if let existingAnnotations = self.normalAnnotations {
//                mapView.removeAnnotations(existingAnnotations)
//            }
//            self.normalAnnotations.removeAll()
//        }
        let annotationCoordinate = mapView.convert(location, toCoordinateFrom: mapView)
//        let addressAnnotation = AddressAnnotation()
//        addressAnnotation.coordinate = annotationCoordinate
//        geocodingDataTask?.cancel()
//        let options = ReverseGeocodeOptions(coordinate: annotationCoordinate)
//        geocodingDataTask = geocoder.geocode(options) {(placemarks, attribution, error) in
//            if let error = error {
//                NSLog("%@", error)
//            } else if let placemarks = placemarks, !placemarks.isEmpty {
//                addressAnnotation.title  = placemarks[0].qualifiedName
//            } else {
//                addressAnnotation.title  = "No results"
//            }
//        }
//        addressAnnotation.subtitle = "\(annotationCoordinate.latitude), \(annotationCoordinate.longitude)"
//        normalAnnotations.append(addressAnnotation)
//        mapView.addAnnotation(addressAnnotation)
        self.txtLandmarkLat.text = annotationCoordinate.latitude.toString()
        self.txtLandmarkLon.text = annotationCoordinate.longitude.toString()
        self.landmarkDialog.isHidden = false
        self.landmarkDialog.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
            self.landmarkDialog.alpha = 1
        })
    }
   
    @objc func loadAllDrivers() {
        guard !self.isLoadingAllDrivers else { return }
        
        self.view.endEditing(true)
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!")
            
            let DELAY: Double! = 15.0
            DispatchQueue.main.asyncAfter(deadline: .now() + DELAY) {
                self.loadAllDrivers()
            }
            
            return
        }
        
        self.selectedTrackers.removeAll()
        
        let reqInfo = URLManager.getAllTrackersWeb()
        let parameters: Parameters = [:]
        let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]

        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)

        self.isLoadingAllDrivers = true
        
        request.responseString { dataResponse in
            self.isLoadingAllDrivers = false

            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.indicator.alpha = 1
                self.loadAllDrivers()
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)

            if(code == 200) {
                let items = json["items"]
                let newTrackerList = items.arrayValue.map({ TrackerModel.parseJSON($0) })
                let isPhoneTracking = Defaults[.phoneTracking] ?? false
                
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
                    
                    if tracker.userId != "", tracker.userId != Global.shared.app_user["_id"].stringValue {
                        /// same as acceptSharedTracker() function in android
                        let index = Global.shared.sharedTrackerList.firstIndex(where: { $0._id == tracker._id }) ?? -1
                        if index < 0 {
                            Global.shared.sharedTrackerList.append(tracker)
                        }
                        
                        let _sharedDeviceList = Global.shared.app_user["sharedDeviceList"].arrayValue
                        var flag = ""
                        for _sharedTracker in _sharedDeviceList {
                            if _sharedTracker["reportId"].stringValue == tracker.reportingId {
                                flag = _sharedTracker["flag"].stringValue
                                break
                            }
                        }
                        if flag == "0" {
                            if !self.dialog_flag {
                                self.showAddSharedTrackerDialog(tracker)
                            }
                        } else if flag == "1" {
                            self.addDevice(tracker, shouldUpdateBottomList: true)
                        }
                    }
                    else {
                        self.addDevice(tracker, shouldUpdateBottomList: false)
                    }
                }
                
                var selected_flag = false
                Global.shared.selectedTrackerIds.removeAll()
                
                for tracker in self.trackerList {
                    if tracker.isSelected {
                        selected_flag = true
                        self.selectedTrackers.append(tracker)
                        Global.shared.selectedTrackerIds.append(tracker._id)
                    }
                }
                
                if !selected_flag && self.trackerList.count > 0 && self.firstAppearFlag {
                    self.trackerList[0].isSelected = true
                    self.selectedTrackers.append(self.trackerList[0])
                    Global.shared.selectedTrackerIds.append(self.trackerList[0]._id)
                    self.addTrackPoints(tracker: self.trackerList[0])
                    self.showCarsOnMap(shouldRecenter: true)
                } else {
                    self.showCarsOnMap(shouldRecenter: false)
                }
                
                if self.firstAppearFlag {
                    MainContainerViewController.instance.hideMenuView(self)
                }
                
                Global.shared.AllTrackerList = self.trackerList
                self.firstAppearFlag = false
                self.onAllTrackersLoaded()
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
                self.indicator.alpha = 0
            }
        }
    }
    
    func showAddSharedTrackerDialog(_ tracker: TrackerModel) {
        self.dialog_flag = true
        
        let reqInfo = URLManager.users_id(tracker.userId)
        let parameters: Parameters = [:]
        let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]
        
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
                let appearance = SCLAlertView.SCLAppearance(showCloseButton:false, showCircularIcon: true)
                let alertView = SCLAlertView(appearance: appearance)
                alertView.addButton("Yes") {
                    alertView.closeLeft()
                    self.setShareFlag(tracker.reportingId,"1")
                    self.addDevice(tracker, shouldUpdateBottomList: true)
                    self.dialog_flag = false
                }
                alertView.addButton("No") {
                    alertView.closeLeft()
                    self.setShareFlag(tracker.reportingId,"-1")
                    self.dialog_flag = false
                }
                alertView.showInfo(tracker.plateNumber,
                                   subTitle: json["firstName"].stringValue + " " + json["lastName"].stringValue + " wants to share this vehicle information with you. Do you want show this vehicle?",
                                   colorStyle: 0xec9d20,
                                   animationStyle: .topToBottom)
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
                self.view.makeToast("server connect error")
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
    
    func getUserInfo() {
        let reqInfo = URLManager.getUserInfo()
        let parameters: Parameters = [:]
        let headers: HTTPHeaders = [:]
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
                Global.shared.app_user = json
                if self.trackerList.isEmpty {
                    self.loadAllDrivers()
                }
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    func addDevice(_ tracker: TrackerModel, shouldUpdateBottomList: Bool) {
        let index = self.trackerList.firstIndex(where: { $0._id == tracker._id }) ?? -1
        
        if Global.shared.selectedTrackerIds.contains(tracker._id) {
            tracker.isSelected = true
        } else {
            tracker.isSelected = false
        }
        
        if index >= 0, index < self.trackerList.count {
            self.trackerList[index] = tracker
            self.addTrackPoints(tracker: tracker)
        } else {
            self.trackerList.append(tracker)
        }
    }
    
    func getAlarmStatus(trackerId : String) {
        let reqInfo = URLManager.alarm(trackerId)
        let parameters: Parameters = [:]
        let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString {
            dataResponse in

            if(dataResponse.data == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let data : AlarmModel = AlarmModel.parseJSON(json)
                Defaults[.alertSound] = data.soundAlarmStatus
                Defaults[.vibration] = data.vibrationAlarmStatus
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    func addTrackPoints(tracker: TrackerModel) {
        guard tracker.isSelected else { return }
        
        let driverName = tracker.driverName
        let alert = tracker.lastAlert
        
        if(!Global.shared.alertArray.keys.contains(driverName) || Global.shared.alertArray[driverName] != alert)
        {
            if alert != "no alert", alert != "", alert != "undefined", alert.count > 11 {
                let alert_datetime_str = alert.substring(from: alert.count - 11, to: alert.count)
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                let alert_datetime = dateFormatter.date(from: "\(Date().year().toString())/\(alert_datetime_str):00")

                if let lastAlertTime = alert_datetime, Date().date(plusDay: -1) < lastAlertTime {
                    getAlarmStatus(trackerId: tracker._id)
                    let appearance = SCLAlertView.SCLAppearance(showCircularIcon: true)
                    let alertView = SCLAlertView(appearance: appearance)
                    alertView.showInfo(driverName, subTitle: alert, colorStyle:0xec9d20, animationStyle: .topToBottom)
                    
                    if Defaults[.alertSound] == nil || Defaults[.alertSound]! {
                        AudioServicesPlayAlertSound(1312)//1328
                    }
                    if Defaults[.vibration] == nil || Defaults[.vibration]! {
                        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    Global.shared.alertArray[driverName] = tracker.lastAlert
                }
            }
        }
    }
    
    func onAllTrackersLoaded() {
        setBottomPanelData()
        setVelocityData()
//        showCarsOnMap(shouldRecenter: false)
        
        if stopLoading {
            return
        }
        
        let DELAY: Double! = 5.0
        DispatchQueue.main.asyncAfter(deadline: .now() + DELAY) {
            self.loadAllDrivers()
        }
    }
    
    func setVelocityData() {
//        self.velocityTableView.setData(trackerList)
        self.velocityTableView.setData(selectedTrackers)
        self.velocityTableView.reloadData()
        let max_height = self.view.bounds.height * 0.8 - 70
        if max_height > self.velocityTableView.getHeight() {
            self.velocityTableHC.constant = self.velocityTableView.getHeight()
        }
        else {
            self.velocityTableHC.constant = max_height
        }
    }
    
    func setBottomPanelData() {
        self.assetMultiSelectTableView.setData(trackerList)
        self.assetMultiSelectTableView.reloadData()
        self.indicator.alpha = 0
        self.bottomTableHC.constant = self.assetMultiSelectTableView.getHeight()
        
        self.bottomTableView.layer.borderColor = UIColor.gray.cgColor
        self.bottomTableView.layer.borderWidth = 0.5
        self.bottomTableView.layer.cornerRadius = 20.0
        self.bottomTableView.backgroundColor = UIColor(hexInt: 0xFDE5F3)
        self.bottomTableView.layer.masksToBounds = true
    }
    
//    func showCarsOnMap(shouldShowAll: Bool = false, shouldZoomDefault: Bool = false) {
    func showCarsOnMap(shouldRecenter: Bool, shouldCenterToCurrentLocation: Bool = false) {
        var containMarkerCount = 0
        
        let currentMapBounds = mapView.visibleCoordinateBounds
        let currentMapBoundsRect = MKMapRect(x: currentMapBounds.sw.latitude, y: currentMapBounds.sw.longitude, width: currentMapBounds.ne.latitude - currentMapBounds.sw.latitude, height: currentMapBounds.ne.longitude - currentMapBounds.sw.longitude)
        
        for tracker in trackerList {
            let latitude = tracker.lat
            let longitude = tracker.lng
            
            if currentMapBoundsRect.contains(MKMapPoint(x: latitude, y: longitude)) {
                containMarkerCount += 1
            }
        }
        
        if showUserLocationFlag && userAnnotation != nil {
            let latitude = userAnnotation.coordinate.latitude
            let longitude = userAnnotation.coordinate.longitude
            
            if currentMapBoundsRect.contains(MKMapPoint(x: latitude, y: longitude)) {
                containMarkerCount += 1
            }
        }
        
        if containMarkerCount > 0, !shouldRecenter {
            return
        }
        
        if let _annotations = self.carAnnotations, _annotations.count > 0 {
            mapView.removeAnnotations(_annotations)
            self.carAnnotations?.removeAll()
        }
        
        if let _polyLines = self.polyLines, _polyLines.count > 0 {
            mapView.removeAnnotations(_polyLines)
            self.polyLines.removeAll()
        }
        
        var coordinates = [CLLocationCoordinate2D]()
        var angle = 0.0
        for tracker in trackerList {
            guard tracker.isSelected else { continue }
            
            let latitude = tracker.lat
            let longitude = tracker.lng
         
            if latitude >= 90 || latitude <= -90 || longitude >= 180 || longitude <= -180 {
                continue
            }
         
            let annotation = MGLPointAnnotation()
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            var points = [CLLocationCoordinate2D]()
            points.append(coordinate)
            
            if abs(tracker.lat1) < 90, abs(tracker.lng1) < 180 {
                points.append(CLLocationCoordinate2D(latitude: tracker.lat1, longitude: tracker.lng1))
            }
            if abs(tracker.lat2) < 90, abs(tracker.lng2) < 180 {
                points.append(CLLocationCoordinate2D(latitude: tracker.lat2, longitude: tracker.lng2))
            }
            
            annotation.coordinate = coordinate
            annotation.title = "vehicle"
            annotation.subtitle = ""
            
            if tracker.accStatus != 0 {
                let pointline = MGLPolyline(coordinates: points, count: UInt(points.count))
                pointline.title = "pointLine"
                //mapView.addAnnotation(pointline)
                angle = self.getAngle(tracker.lng1, tracker.lat1, tracker.lng2, tracker.lat2)
                self.polyLines.append(pointline)
            }
            
            self.scrollView.isScrollEnabled = true
            mapView.addAnnotation(annotation)
            self.carAnnotations.append(annotation)
        
            coordinates.append(coordinate)
        }
        
        if showUserLocationFlag && userAnnotation != nil {
            coordinates.append(userAnnotation.coordinate)
        }
        
        if shouldRecenter, shouldCenterToCurrentLocation, showUserLocationFlag, userAnnotation != nil {
            coordinates = [userAnnotation.coordinate]
        }
        
        if(coordinates.count == 0) {
            return
        }
        
        zoom_Slider.value = Float(mapView.zoomLevel)
        
        mapView.camera = mapView.cameraThatFitsCoordinateBounds(MGLPolygon(coordinates: coordinates, count: UInt(coordinates.count)).overlayBounds, edgePadding: UIEdgeInsets(top: 140, left: 50, bottom: 140, right: 50))
        let pCamera = mapView.camera
        pCamera.pitch = 0.0
//        if !mapStyle {
//            pCamera.pitch = 45.0
//        }
        pCamera.heading = 0
        
        mapView.setCamera(pCamera, animated: false)
        
        if coordinates.count == 1 {
            print("MapView Zoom Leve: \(mapView.zoomLevel)")

            if shouldRecenter {
                let zoomLevel = max(defaultZoom, Double(zoom_Slider.value))
                mapView.zoomLevel = zoomLevel
                zoom_Slider.value = Float(zoomLevel)
            } else {
                mapView.zoomLevel = Double(zoom_Slider.value)
            }
        } else {
            let zoomLevel = min(15.5, mapView.zoomLevel)
            mapView.zoomLevel = zoomLevel
            zoom_Slider.value = Float(zoomLevel)
        }
    }
    
    func showUserLocationToCenter() {
        if userAnnotation != nil {
            mapView.camera = mapView.cameraThatFitsCoordinateBounds(MGLPolygon(coordinates: [userAnnotation!.coordinate], count: 1).overlayBounds, edgePadding: UIEdgeInsets(top: 140, left: 50, bottom: 70, right: 50))
            let pCamera = mapView.camera
            pCamera.pitch = 0.0
            if !mapStyle {
                pCamera.pitch = 45.0
            }
            mapView.setCamera(pCamera, animated: false)
            mapView.zoomLevel = 15.5
            zoom_Slider.value = 15.5
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage]  as? UIImage {
            let upload_image = image.resizeImage(targetSize: CGSize(width:200.0, height:200.0))
            let imgData = upload_image.jpegData(compressionQuality: 0.2)!
            
            let parameters = ["filename": self.uploadAssetId, "state": "1"] //Optional for extra parameter
            
            Alamofire.upload(multipartFormData: { multipartFormData in
                multipartFormData.append(imgData, withName: "file",fileName: "file.jpg", mimeType: "image/jpg")
                for (key, value) in parameters {
                    multipartFormData.append(value!.data(using: String.Encoding.utf8)!, withName: key)
                } //Optional for extra parameters
            },
                             to:"https://api.spectrumtracking.com/v1/trackers/imageUpload")
            { (result) in
                switch result {
                case .success(let upload, _, _):
                    
                    upload.uploadProgress(closure: { (progress) in
                        print("Upload Progress: \(progress.fractionCompleted)")
                    })
                    
                    upload.responseJSON { response in
                        print(response.result.value ?? "")
                        self.setPhotoUploadStatus(self.uploadTrackerId)
                    }
                    
                case .failure(let encodingError):
                    print(encodingError)
                }
            }
        }
        else {
            
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func setStopUpload() {
        stop_task = DispatchWorkItem{
            let reqInfo = URLManager.postUserLocation()
            let current_time = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-M-d HH:mm:ss"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let str_utc_time = dateFormatter.string(from: current_time)
            
            let parameters: Parameters = [
                "reportingId": Defaults[.username] ?? "", // Global.shared.app_user["email"].stringValue,
                "dateTime":str_utc_time,
                "lat":Global.shared.userLocation?.latitude,
                "lng":Global.shared.userLocation?.longitude,
                "ACCStatus":0,
                "speedInMph":0,
                "trackerModel": "phone",
                "lastAlert":""
                
            ]
            let headers: HTTPHeaders = [
                "X-SpectrumTracking-TrackerEndpointKey":"33bedd43-209c-4025-b157-d7c6df1211e3"
            ]
            let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
            
            request.responseString { dataResponse in
                if(dataResponse.response == nil || dataResponse.value == nil) {
                    //self.view.makeToast("server connect error")
                    return
                }
                print(parameters)
                let code = dataResponse.response!.statusCode
                
                let json = JSON.init(parseJSON: dataResponse.value!)
                
                if(code == 201) {
                    
                    
                } else {
                    print(json)
                    let error = ErrorModel.parseJSON(json)
                    //self.view.makeToast(error.message)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 90.0, execute:(self.stop_task)!)
    }
    
    func setPhotoUploadStatus(_ trackerId: String) {
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
        }
       
        let reqInfo = URLManager.modifyTracker()
        
        let parameters: Parameters = [
            "id": trackerId,
            "photoStatus": true
        ]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        self.showLoader()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.view.makeToast("Upload Success".localized())
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    override func setResult(_ result: Any, from id: String, sender: Any? = nil) {
        if id == "AssetMultiSelectTableViewCell-selectedItem" {
            let row = (result as! (Int, Bool)).0
            let isSelected = (result as! (Int, Bool)).1
            
            if trackerList.count <= row {
                return
            }
            
            self.trackerList[row].isSelected = isSelected
            
            self.selectedTrackers.removeAll()
            Global.shared.selectedTrackerIds.removeAll()
            
            for tracker in self.trackerList {
                if tracker.isSelected {
                    self.selectedTrackers.append(tracker)
                    Global.shared.selectedTrackerIds.append(tracker._id)
                }
            }
            
            self.setBottomPanelData()
            self.showCarsOnMap(shouldRecenter: true)
        }
        else if id == "AssetMultiSelectTableViewCell-replay" {
            let row = (result as! (Int, Bool)).0
            
            let controller = ReplayViewController.getNewInstance()
            addChild(controller)
            controller.willMove(toParent: self)
            controller.view.frame = self.replayRouteView.bounds
            self.replayRouteView.addSubview(controller.view)
            controller.didMove(toParent: self)
            self.replayRouteView.isHidden = false
            // self.performSegue(withIdentifier: "segReplay", sender: self)
        }
        else if id == "photoUpload" {
            let row = (result as! (Int, Bool)).0
            self.uploadAssetId = self.trackerList[row].assetId
            self.uploadTrackerId = self.trackerList[row]._id
            let selectAlert: UIAlertController = UIAlertController(title: "Upload a Image".localized(), message: "Choose a filetype to upload...", preferredStyle: .actionSheet)
            
            let cancelActionButton = UIAlertAction(title: "Cancel".localized(), style: .cancel) { _ in
                print("Cancel")
            }
            selectAlert.addAction(cancelActionButton)
            
            let saveActionButton = UIAlertAction(title: "Camera".localized(), style: .default)
            { _ in
                
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.allowsEditing = false
                    imagePicker.sourceType = UIImagePickerController.SourceType.camera
                    self.present(imagePicker, animated: true)
                }
                else {
                    self.view.makeToast("Your device can't use camera.".localized())
                }
            }
            selectAlert.addAction(saveActionButton)
            
            let deleteActionButton = UIAlertAction(title: "Phone Library".localized(), style: .default)
            { _ in
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.allowsEditing = false
                imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                self.present(imagePicker, animated: true)
            }
            selectAlert.addAction(deleteActionButton)
            
            if let popoverController = selectAlert.popoverPresentationController {
                popoverController.sourceView = sender as? UIView
                popoverController.sourceRect = (sender as? UIView)?.bounds ?? .zero
            }
            
            self.present(selectAlert, animated: true, completion: nil)
        }
        else if id == "dotOption" {
            let row = (result as! (Int, Bool)).0
            
            let selectAlert: UIAlertController = UIAlertController(title: "Options".localized(), message: "Please Select".localized(), preferredStyle: .actionSheet)
            let cancelActionButton = UIAlertAction(title: "Cancel".localized(), style: .cancel) { _ in
                print("Cancel")
            }
            selectAlert.addAction(cancelActionButton)
            
            let saveActionButton = UIAlertAction(title: "Edit Vehicle Info".localized(), style: .default)
            { _ in
                let row = (result as! (Int, Bool)).0
                self.update_trackerId = self.trackerList[row]._id
                self.update_assetId = self.trackerList[row].assetId
                self.update_txtDriverName.text = self.trackerList[row].driverName
                self.update_txtVehicleName.text = self.trackerList[row].plateNumber
                self.update_txtColor.text = self.trackerList[row].color
                self.view.endEditing(true)
                self.update_dialog.isHidden = false
                self.update_dialog.alpha = 0
                UIView.animate(withDuration: 0.2, animations: {
                    self.update_dialog.alpha = 1
                })
            }
            selectAlert.addAction(saveActionButton)
            
            let deleteActionButton = UIAlertAction(title: "Get There".localized(), style: .default)
            { _ in
                let row = (result as! (Int, Bool)).0
                if let location = self.currentUserLocation {
                    let user_lat:String = "\(location.latitude)"
                    let user_lng:String = "\(location.longitude)"
                    let tracker_lat:String = String(self.trackerList[row].lat)
                    let tracker_lng:String = String(self.trackerList[row].lng)
                    guard let url = URL(string: "https://www.google.com/maps/dir/\(user_lat),\(user_lng)/\(tracker_lat),\(tracker_lng)/data=!3m1!4b1!4m2!4m1!3e0") else {return}
                    UIApplication.shared.open(url)
                }
                else {
                    self.view.makeToast("Can't get your location.".localized())
                }
            }
            selectAlert.addAction(deleteActionButton)
            
            let shareLocationActionButton = UIAlertAction(title: "Share Location".localized(), style: .default) { _ in
                let controller = ShareTrackerViewController.getNewInstance()
                MainContainerViewController.instance.setPage(controller: controller)
            }
            selectAlert.addAction(shareLocationActionButton)
            
            let chatActionButton = UIAlertAction(title: "Chatting".localized(), style: .default) { _ in
                self.gotoChatRoom(partnerId: self.trackerList[row].spectrumId)
            }
            
            if trackerList[row].spectrumId != Global.shared.username && trackerList[row].trackerModel.lowercased() == "phone" {
                selectAlert.addAction(chatActionButton)
            }
            
            if let popoverController = selectAlert.popoverPresentationController {
                popoverController.sourceView = sender as? UIView
                popoverController.sourceRect = (sender as? UIView)?.bounds ?? .zero
            }
            
            self.present(selectAlert, animated: true, completion: nil)
        }
    }
    
    override func setTableViewHeight(_ value: CGFloat) {
        if(value > view.bounds.height * 0.9){
            self.mapViewFrameView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: 0)
        }
        else{
            self.mapViewFrameView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: view.bounds.height * 0.9 - value)
        }
        self.assetMultiSelectTableView.frame = CGRect(x: 0, y: view.bounds.height * 0.9 - value, width: self.view.bounds.size.width, height: view.bounds.height * 0.1 + value)
    }
    
    @objc func locationChanged(_ sender: Any) {
        self.currentUserLocation = Global.shared.userLocation
        print("Current Location: \(self.currentUserLocation?.latitude ?? 0) - \(self.currentUserLocation?.longitude ?? 0)")
    }
    
    func updateUnreadCount() {
        if MainContainerViewController.instance.totalUnreadCount == 0 {
            unreadCountLabel.isHidden = true
        } else {
            unreadCountLabel.isHidden = false
            unreadCountLabel.text = "\(MainContainerViewController.instance.totalUnreadCount)"
        }
    }
    
    @IBAction func chatButtonTapped(_ sender: Any) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatRoomListVC") as! ChatRoomListVC
        MainContainerViewController.instance.showOverlay(vc: vc)
    }
    
    @IBAction func onAcceptChatInvitation(_ sender: Any) {
        self.chatInvitationChannel?.join(completion: { _ in
            let partnerId = ChannelManager.sharedManager.getChannelName(partnerId: self.chatInvitationChannel?.uniqueName ?? "")
            guard partnerId != "" else { return }
            
            self.acceptRejectChatInvitationContainerView.isHidden = true
            self.chatInvitationChannel = nil
            
            self.gotoChatRoom(partnerId: partnerId)
        })
    }
    
    @IBAction func onRejectChatInvitation(_ sender: Any) {
        self.chatInvitationChannel?.declineInvitation(completion: { _ in
            self.acceptRejectChatInvitationContainerView.isHidden = true
            self.chatInvitationChannel = nil
        })
    }
    
    func gotoChatRoom(partnerId: String) {
        let channelName = ChannelManager.sharedManager.getChannelName(partnerId: partnerId)
        let channel = ChannelManager.sharedManager.getPrivateChannelBy(name: channelName)
        
        if let _channel = channel, _channel.status == .joined {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatRoomVC") as! ChatRoomVC
            vc.channelName = channelName
            MainContainerViewController.instance.showOverlay(vc: vc)
        } else {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatInviteDialogVC") as! ChatInviteDialogVC
            vc.modalPresentationStyle = .overCurrentContext
            vc.inviteHandler = { email in
                self.inviteToChat(email: email)
            }
            self.present(vc, animated: false)
        }
    }
    
    func inviteToChat(email: String) {
        let channelName = ChannelManager.sharedManager.getChannelName(partnerId: email)
        
        let reqInfo = URLManager.inviteJoinChat()
        let parameters: Parameters = ["email": email]
        let headers: HTTPHeaders = ["X-CSRFToken": Global.shared.csrfToken]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)

        request.responseString { dataResponse in

            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("Weak cell phone signal is detected".localized())
                return
            }
            //print(dataResponse)
            let code = dataResponse.response!.statusCode

            let json = JSON.init(parseJSON: dataResponse.value!)

            if(code == 200) {
                ChannelManager.sharedManager.joinOrCreatePrivateChannelWith(name: channelName, partnerId: email)
                self.view.makeToast("Successfully invited to join chat".localized())
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
                self.indicator.alpha = 0
            }
        }
    }
    
    func checkChatInvitation() {
        self.acceptRejectChatInvitationContainerView.isHidden = true
        self.chatInvitationChannel = nil
        
        for channel in ChannelManager.sharedManager.privateChannels {
            if channel.status == .invited {
                self.chatInvitationChannel = channel
                
                channel.members?.members(completion: { (_, paginator) in
                    if let member = paginator?.items().first {
                        self.chatInvitationDescLabel.text = "\(member.identity ?? "") " + "invited you to the chat.".localized()
                    }
                })
                self.acceptRejectChatInvitationContainerView.isHidden = false
                
                break
            }
        }
    }
    
    func getAngle(_ lng1:Double, _ lat1:Double, _ lng2:Double, _ lat2:Double) -> Double{
        let lat1Rad = self.deg2rad(lat1)
        let lat2Rad = self.deg2rad(lat2)
        let deltaLonRad = self.deg2rad(lng2 - lng1)
        let y = sin(deltaLonRad) * cos(lat2Rad)
        let x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(deltaLonRad)
        let bearing = (self.rad2deg(atan2(y,x)) + 360).truncatingRemainder(dividingBy: 360.0)
        return bearing
    }
    
    func deg2rad(_ number:Double) -> Double {
        return number * .pi / 180
    }
    
    func rad2deg(_ number:Double) -> Double {
        return number * 180 / .pi
    }
}

// MGLMapViewDelegate delegate
extension MonitorViewController: MGLMapViewDelegate {
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if let castAnnotation = annotation as? AddressAnnotation {
            if (!castAnnotation.displayFlag) {
                print("no")
                return nil
            }
        }
        print(annotation.title)
        var annotationImage:MGLAnnotationImage!
        if(annotation.title == "track") {
            annotationImage = MGLAnnotationImage(image: pinImage, reuseIdentifier: "pin")
        }
        else if annotation.title == "user" {
            annotationImage = MGLAnnotationImage(image: userImage.scaleImageToFitSize(size: CGSize(width: 70, height: 70)), reuseIdentifier: "user_icon")
        }
        else if annotation.title == "Home" {
            annotationImage = MGLAnnotationImage(image: homeImage.scaleImageToFitSize(size: CGSize(width: 50, height: 50)), reuseIdentifier: "landmark_home")
        }
        else if annotation.title == "Office" {
            annotationImage = MGLAnnotationImage(image: officeImage.scaleImageToFitSize(size: CGSize(width: 50, height: 50)), reuseIdentifier: "landmark_office")
        }
        else if annotation.title == "Mall" {
            annotationImage = MGLAnnotationImage(image: mallImage.scaleImageToFitSize(size: CGSize(width: 50, height: 50)), reuseIdentifier: "landmark_mall")
        }
        else if annotation.title == "School" {
            annotationImage = MGLAnnotationImage(image: schoolImage.scaleImageToFitSize(size: CGSize(width: 50, height: 50)), reuseIdentifier: "landmark_school")
        }
        else if annotation.title == "Warehouse" {
            annotationImage = MGLAnnotationImage(image: warehouseImage.scaleImageToFitSize(size: CGSize(width: 50, height: 50)), reuseIdentifier: "landmark_warehouse")
        }
        else if annotation.title == "vehicle" {
            return nil
        }
        else {
            annotationImage = MGLAnnotationImage(image: carImage, reuseIdentifier: "car-image")
        }
        return annotationImage
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        if annotation.title != "vehicle" {
            return nil
        }
        // Assign a reuse identifier to be used by both of the annotation views, taking advantage of their similarities.
        let reuseIdentifier = "reusableDotView"
        // For better performance, always try to reuse existing annotations.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        // If there’s no reusable annotation view available, initialize a new one.
        if annotationView == nil {
            annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
        }
        
        annotationView?.frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
        annotationView?.layer.borderWidth = 2.5
        //            annotationView?.layer.borderColor = UIColor.white.cgColor
        let label = UILabel()
        var accStatus = 0
        var speed = 0.0
        for tracker in selectedTrackers {
            let latitude = tracker.lat
            let longitude = tracker.lng
            if (annotation.coordinate.latitude == latitude && annotation.coordinate.longitude == longitude){
                label.text = tracker.driverName as String
                accStatus = tracker.accStatus
                let metricScale = Global.getDistanceUnit() == "miles" ? 1 : 1.60934
                speed = tracker.speedInMph * metricScale
                if accStatus != 0 && speed != 0 {
                    annotationView?.layer.borderColor = UIColor(red: 0, green: 200, blue: 83).cgColor
                }
                else if accStatus != 0 && speed == 0 {
                    speed = 0
                    annotationView?.layer.borderColor = UIColor(red: 186, green: 69, blue: 240).cgColor
                }
                else {
                    speed = 0
                    annotationView?.layer.borderColor = UIColor(red: 244, green: 31, blue: 27).cgColor
                }
                annotationView?.backgroundColor = Global.annotationFillColor(color: tracker.color)
            }
        }
        
        if let text = label.text, text.count > 5 {
            label.text = label.text?.substring(from: 0, to: 5)
        }
        if accStatus != 0 && speed != 0 {
            label.text = label.text! + "\n" + String(format: "%.1f",speed)
            label.numberOfLines = 2
        }
        label.font = UIFont.boldSystemFont(ofSize: 11.5)
        label.textAlignment = .center
        label.textColor = UIColor.black
        let strokeTextAttributes = [
            NSAttributedString.Key.strokeColor : UIColor.white,
            NSAttributedString.Key.strokeWidth : -4.0,
            NSAttributedString.Key.foregroundColor : UIColor.black,
            NSAttributedString.Key.font : UIFont.boldSystemFont(ofSize: 11.5)]
            as [NSAttributedString.Key : Any]
        label.attributedText = NSMutableAttributedString(string: label.text ?? "", attributes: strokeTextAttributes)
        label.frame = CGRect(x: 3, y: 4, width: 40, height: 40)
        annotationView?.addSubview(label)
        
        return annotationView
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    func mapView(_ mapView: MGLMapView, calloutViewFor annotation: MGLAnnotation) -> MGLCalloutView? {
        print("callout")
        if let castAnnotation = annotation as? AddressAnnotation {
            if (!castAnnotation.displayFlag) {
                return nil
            }
        }
        let label_address = ""
        var label_drivername = ""
        var label_driverPhoneNumber = ""
        for tracker in selectedTrackers {
            let latitude = tracker.lat
            let longitude = tracker.lng
            if (annotation.coordinate.latitude == latitude && annotation.coordinate.longitude == longitude){
                label_drivername = tracker.driverName
                label_driverPhoneNumber = tracker.driverPhoneNumber
            }
        }
        let label_position = "\(annotation.coordinate.latitude), \(annotation.coordinate.longitude)"
        mapView.centerCoordinate = annotation.coordinate
        let customAnnotation = MyCustomAnnotation(coordinate: annotation.coordinate, title:  label_drivername , subtitle: label_address ?? "no Address", description: label_position ?? "",
                                                  phoneNumber: label_driverPhoneNumber )
        return MyCustomCalloutView(annotation: customAnnotation)
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return UIColor(hexInt: 0xF96F00)
    }
}
class MyCustomAnnotation: NSObject, MGLAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var position: String?
    var phoneNumber: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, description: String,phoneNumber: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.position = description
        self.phoneNumber = phoneNumber
    }
}
class MyCustomCalloutView: UIView, MGLCalloutView {
    var geocoder: Geocoder!
    var geocodingDataTask: URLSessionDataTask?
    
    var representedObject: MGLAnnotation
    let dismissesAutomatically: Bool = false
    let isAnchoredToAnnotation: Bool = true
    
    
    override var center: CGPoint {
        set {
            var newCenter = newValue
            newCenter.y = newCenter.y - bounds.midY
            super.center = newCenter
        }
        get {
            return super.center
        }
    }
    // Required views but unused for now, they can just relax
    lazy var leftAccessoryView = UIView()
    lazy var rightAccessoryView = UIView()
    
    weak var delegate: MGLCalloutViewDelegate?
    
    //MARK: Subviews -
    let titleLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: 100, height: 20))
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.black
        return label
    }()
    
    let subtitleLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 50, width: UIScreen.main.bounds.width-60, height: 20))
        label.font = UIFont.systemFont(ofSize: 14.0)
        return label
    }()
    
    let positionLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 70, width: UIScreen.main.bounds.width-60, height: 20))
        label.font = UIFont.systemFont(ofSize: 14.0)
        return label
    }()
    
    let phoneLabel:UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: 30, width: UIScreen.main.bounds.width-60, height: 20))
        label.font = UIFont.systemFont(ofSize: 14.0)
        return label
    }()
    
    required init(annotation: MyCustomAnnotation) {
        self.representedObject = annotation
        geocoder = Geocoder(accessToken: MapboxAccessToken)
        super.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: UIScreen.main.bounds.width * 0.75, height: 100.0)))
        self.titleLabel.text = self.representedObject.title ?? ""
        geocodingDataTask?.cancel()
        let options = ReverseGeocodeOptions(coordinate: annotation.coordinate)
        geocodingDataTask = geocoder.geocode(options) { [weak self] (placemarks, attribution, error) in
            
            if let error = error {
                print("%@", error)
            } else if let placemarks = placemarks, !placemarks.isEmpty {
                self?.subtitleLabel.text  = "\(placemarks[0].qualifiedName as! String)"
                self?.setup()
            }
        }
        self.positionLabel.text = annotation.position ?? ""
        self.phoneLabel.text = annotation.phoneNumber ?? ""
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        // setup this view's properties
        self.backgroundColor = UIColor.white
        self.frame = CGRect(origin: CGPoint(x: 20, y: UIScreen.main.bounds.height * 0.5 - 210), size: CGSize(width: UIScreen.main.bounds.width-40, height: 100.0))
        // And their Subviews
        self.addSubview(titleLabel)
        self.addSubview(subtitleLabel)
        self.addSubview(positionLabel)
        self.addSubview(phoneLabel)
        
    }
    
    func presentCallout(from rect: CGRect, in view: UIView, constrainedTo constrainedRect: CGRect, animated: Bool) {
        //Always, Slightly above center
        self.center = view.center.applying(CGAffineTransform(translationX: 0, y: -self.frame.height))
        view.addSubview(self)
    }
    
    func dismissCallout(animated: Bool) {
        if (superview != nil) {
            if animated {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    self?.alpha = 0
                    }, completion: { [weak self] _ in
                        self?.removeFromSuperview()
                })
            } else {
                removeFromSuperview()
            }
        }
    }
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        let r = CGFloat(red) / 255.0;
        let g = CGFloat(green) / 255.0;
        let b = CGFloat(blue) / 255.0;
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
