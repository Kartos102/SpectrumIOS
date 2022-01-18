//
//  GeofenceViewController.swift
//  spectrum_tracker
//
//  Created by Robin on 2018/09/28.
//  Copyright © 2018 Robin. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Mapbox
import MapKit
import CoreLocation

// MGLPointAnnotation subclass
class MyCustomPointAnnotation: MGLPointAnnotation {
    var willUseImage: Bool = false
    var carImage: Bool = false
}

class GeofenceViewController: ViewControllerWaitingResult,UIScrollViewDelegate {
    
    @IBOutlet var zoom_Slider: VSSlider!
    @IBOutlet weak var label_comment: UILabel!
    @IBAction func zoom_Change(_ sender: Any) {
        mapView.zoomLevel = Double(zoom_Slider.value)
        self.scrollView.isScrollEnabled = true
    }
    @IBOutlet var btn_style: UIButton!
    @IBAction func changeMapStyle(_ sender: Any) {
        if(mapStyle)
        {
            mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
            label_comment.textColor = Color.black
        }
        else
        {
            mapView.styleURL = MGLStyle.satelliteStreetsStyleURL
            label_comment.textColor = Color.white
        }
        mapStyle = !mapStyle
    }
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var overlayView: UIView!
    @IBOutlet var mapViewFrameView: UIView!

    @IBOutlet var tableViewHC: NSLayoutConstraint!
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    @IBOutlet var topView: UIView!
    @IBOutlet var assetMultiSelectTableView: AssetMultiSelectTableView! {
        didSet {
            assetMultiSelectTableView.parentVC = self
        }
    }
    
    var stopLoading: Bool! = false
    var mapStyle: Bool! = false
    var mapView: MGLMapView!
    var Circle: Bool = true
    var assetList: [AssetModel]!
    var firstLoadFlag:Bool = true
    var selectedAssets: [AssetModel]!
    var trackers: [AssetModel: TrackerModel]!
    var carAnnotations: [MGLPointAnnotation]!
    var selectAnnotations:[MGLPointAnnotation]!
    var firstPos : CGPoint!
    var secondPos : CGPoint!
    var radius: Double = 0
    var distance: Double = 0;
    var circleAnnotation: MyCustomPointAnnotation!
    var circlePolygon: MGLPolyline!
    var annotationCoordinate: CLLocationCoordinate2D!
    var firstCoordinate: CLLocationCoordinate2D!
    var tempCoordinate: CLLocationCoordinate2D!
    
    static var instance: UIViewController!
    
    static func getNewInstance() -> UIViewController {
        if instance == nil {
            let storyboardName = "Main"
            let viewControllerIdentifier = "GeofenceViewController"
            
            let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
            return vc
        } else {
            return instance
        }
    }
    
    var circleImage: UIImage! = UIImage(named: "circle")
    var carImage: UIImage! = UIImage(named: "locationcirclesmall")
    var defaultZoom = 15.0
    var defaultPtZoom = 15.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        carAnnotations = [MGLPointAnnotation]()
        selectAnnotations = [MGLPointAnnotation]()
        self.scrollView.panGestureRecognizer.delaysTouchesBegan = true
        self.scrollView.delegate = self
        self.scrollView.panGestureRecognizer.addTarget(self, action: #selector (self.panHandle (_:)))
        
        GeofenceViewController.instance = self
    }
    
    @objc func panHandle(_ gestureRecognizer:UIPanGestureRecognizer) {
        let touchLocation = gestureRecognizer.location(in: self.zoom_Slider)
        print(touchLocation)
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            if touchLocation.y >= 0 && touchLocation.x >= 0{
                self.scrollView.isScrollEnabled = false
            }
            else {
                self.scrollView.isScrollEnabled = true
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // self.topView.frame.size.height = self.view.bounds.height * 0.77 - scrollView.contentOffset.y
        self.topView.frame.origin.y = scrollView.contentOffset.y
        //self.label_comment.frame.origin.y = scrollView.contentOffset.y
        //self.mapView.frame.size.height = self.view.bounds.height * 0.9 - scrollView.contentOffset.y
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopLoading = true
        
        print("============================")
    }

    override func viewWillAppear(_ animated: Bool) {
        initMapView()
        loadAllDrivers()
        //commented by Robin hideOptions()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        radius = 0
        let touch = touches.first as! UITouch
        firstPos = touch.location(in: overlayView)
        firstCoordinate = mapView.convert(firstPos, toCoordinateFrom: mapView)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first as! UITouch
        let currentPoint = touch.location(in: overlayView)
        let transX = Double(currentPoint.x - firstPos.x)
        let transY = Double(currentPoint.y - firstPos.y)
        
        radius =  sqrt(transX * transX + transY * transY)
        tempCoordinate = mapView.convert(currentPoint, toCoordinateFrom: mapView)
        let firstLocation = CLLocation(latitude: self.firstCoordinate.latitude,longitude: self.firstCoordinate.longitude)
        let tempLocation = CLLocation(latitude: tempCoordinate.latitude,longitude: tempCoordinate.longitude)
        distance = firstLocation.distance(from: tempLocation) / 1000
        self.Circle = true
        if circlePolygon != nil {
            mapView.removeAnnotation(circlePolygon)
        }
        
        polygonCircleForCoordinate(coordinate: annotationCoordinate,withMeterRadius: distance)
    }
    func polygonCircleForCoordinate(coordinate: CLLocationCoordinate2D, withMeterRadius: Double) {
        let degreesBetweenPoints = 8.0
        //45 sides
        let numberOfPoints = floor(360.0 / degreesBetweenPoints)
        let distRadians: Double = withMeterRadius / 6371.0
        // earth radius in meters
        let centerLatRadians: Double = coordinate.latitude * Double.pi / 180
        let centerLonRadians: Double = coordinate.longitude * Double.pi / 180
        var coordinates = [CLLocationCoordinate2D]()
        //array to hold all the points
        for index in 0 ..< Int(numberOfPoints) {
            let degrees: Double = Double(index) * Double(degreesBetweenPoints)
            let degreeRadians: Double = degrees * Double.pi / 180
            let pointLatRadians: Double = asin(sin(centerLatRadians) * cos(distRadians) + cos(centerLatRadians) * sin(distRadians) * cos(degreeRadians))
            let pointLonRadians: Double = centerLonRadians + atan2(sin(degreeRadians) * sin(distRadians) * cos(centerLatRadians), cos(distRadians) - sin(centerLatRadians) * sin(pointLatRadians))
            let pointLat: Double = pointLatRadians * 180 / Double.pi
            let pointLon: Double = pointLonRadians * 180 / Double.pi
            let point: CLLocationCoordinate2D = CLLocationCoordinate2DMake(pointLat, pointLon)
            coordinates.append(point)
        }
        coordinates.append(coordinates.first!)
        circlePolygon = MGLPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
        self.mapView.addAnnotation(circlePolygon)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        overlayView.isHidden = true
        self.scrollView.isUserInteractionEnabled = true
        saveGeofence(position: annotationCoordinate, _distance: self.distance)
    }
    func initMapView() {
        self.mapView = MGLMapView(frame: mapViewFrameView.bounds)
        mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.attributionButton.isHidden = true
        mapView.maximumZoomLevel = 20
        
        mapView.zoomLevel = 9
        if Global.shared.userLocation != nil {
            mapView.centerCoordinate = Global.shared.userLocation
        }
        else {
            mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 38.2534189, longitude: -85.7551944)
        }
        
        /*by robin*/
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        mapView.addGestureRecognizer(singleTap)
        self.mapViewFrameView.addSubview(mapView)
        overlayView.isHidden = true
        /*=============*/

        mapView.delegate = self
    }
    
    @objc func handleMapTap(sender: UITapGestureRecognizer) throws {
        let location = sender.location(in: self.mapView)
        if self.selectAnnotations?.count != nil{
            if let existingAnnotations = self.selectAnnotations {
                mapView.removeAnnotations(existingAnnotations)
            }
            self.selectAnnotations.removeAll()
        }
        
        annotationCoordinate = mapView.convert(location, toCoordinateFrom: mapView)
        //print(annotationCoordinate.latitude)
        let selectAnnotation = MyCustomPointAnnotation()
        selectAnnotation.coordinate = annotationCoordinate
        selectAnnotation.willUseImage = true
        mapView.addAnnotation(selectAnnotation)
        self.selectAnnotations.append(selectAnnotation)
        overlayView.isHidden = false
        self.scrollView.isUserInteractionEnabled = false
    }
    
    func saveGeofence(position: CLLocationCoordinate2D, _distance: Double){
        for asset in assetList{
            if asset.isSelected == true {
                print(_distance)
                let reqInfo = URLManager.setGeofence()
                let parameters: Parameters = [
                    "latGeo": position.latitude,
                    "lngGeo": position.longitude,
                    "radiusGeo": _distance * 3280.84,
//                    "trackerId": asset._id as String,
                    "assetId": asset.assetId,
                    "plateNumber": asset.name,
                    "driverName": asset.driverName
                ]
                let headers: HTTPHeaders = [
                    "X-CSRFToken": Global.shared.csrfToken
                ]
        
                
        
                let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
                
                request.responseString {
                    dataResponse in
                    
                    if(dataResponse.response == nil || dataResponse.value == nil) {
                        self.view.makeToast("server connect error")
                        return
                    }
                    
                    let code = dataResponse.response!.statusCode
                    let json = JSON.init(parseJSON: dataResponse.value!)
                    
                    if(code == 200) {
                        print(position.latitude)
                        let selectAnnotation = MyCustomPointAnnotation()
                        selectAnnotation.coordinate = CLLocationCoordinate2D(latitude: position.latitude-_distance/160, longitude: position.longitude)
                        selectAnnotation.willUseImage = true
                        self.mapView.addAnnotation(selectAnnotation)
                        self.selectAnnotations.append(selectAnnotation)
                        self.view.makeToast("Geofence is set")
                    } else {
                        let error = ErrorModel.parseJSON(json)
                        self.view.makeToast("Server response Error" + error.message)
                    }
                }
            
            }
        }
    }
    
    func showIndicator() {
//        if self.indicator.alpha == 1 {
//            return
//        }
//        UIView.animate(withDuration: 0.2) {
//            self.indicator.alpha = 1
//        }
    }
    
    func hideIndicator() {
//        if self.indicator.alpha == 0 {
//            return
//        }
//        UIView.animate(withDuration: 0.2) {
//            self.indicator.alpha = 0
//        }
    }
    
    @objc func loadAllDrivers() {
       
        if assetList == nil {
            assetList = [AssetModel]()
        }
        if selectedAssets == nil {
            selectedAssets = [AssetModel]()
        }
        if trackers == nil {
            trackers = [AssetModel: TrackerModel]()
        }
        selectedAssets.removeAll()
        
        self.view.endEditing(true)
        
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!")
            
            let DELAY: Double! = 15.0
            DispatchQueue.main.asyncAfter(deadline: .now() + DELAY) {
                self.loadAllDrivers()
            }
            
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
        
        //showIndicator()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.httpBody, headers: headers)
        
        request.responseString { dataResponse in
            self.hideIndicator()
            //print(dataResponse)
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let items = json["items"]
                var newAssetList = [AssetModel]()
                var assetIds = [String]()
                for i in 0..<items.count {
                    newAssetList.append(AssetModel.parseJSON(items[i]))
                }
                for newAsset in newAssetList {
                    newAsset.isSelected = false
                    assetIds.append(newAsset._id)
                    for oldAsset in self.assetList {
                        if newAsset._id == oldAsset._id {
                            newAsset.isSelected = oldAsset.isSelected
                            break
                        }
                    }
                }
                self.assetList.removeAll()
                self.assetList.append(contentsOf: newAssetList)
                for asset in self.assetList {
                    if asset.isSelected {
                        self.selectedAssets.append(asset)
                    }
                }
                self.trackers.removeAll()
                self.getAllTrackers(assetIds)
            } else {
//                let error = ErrorModel.parseJSON(json)
//                self.view.makeToast(error.message)
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
                for asset in self.assetList {
                    for newTracker in newTrackerList {
                        if(asset.trackerId == newTracker._id) {
                            self.trackers[asset] = newTracker
                            
                            tempAssetList.append(asset)
                        }
                    }
                }
                self.assetList.removeAll()
                for asset in tempAssetList {
                    self.assetList.append(asset)
                }
                self.onTrackersAllLoaded()
            } else {
//                let error = ErrorModel.parseJSON(json)
//                self.view.makeToast(error.message)
            }
        }
    }
    
    func onTrackersAllLoaded() {
        
        setRightPanelData()
        showCarsOnMap()
        
        if stopLoading {
            return
        }
        
        let DELAY: Double! = 15.0
        DispatchQueue.main.asyncAfter(deadline: .now() + DELAY) {
            self.loadAllDrivers()
        }
    }
    func showCarsOnMap() {
       
        var ifContainsAtLeastOnePoint = false
        
        for asset in selectedAssets {
            if(trackers.keys.contains(asset)) {
                let tracker = trackers[asset]
                let latitude = tracker?.lat ?? 0.0
                let longitude = tracker?.lng ?? 0.0
                
                if latitude == 0 && longitude == 0 {
                    continue
                }
                
                let bounds = mapView.visibleCoordinateBounds
                
                let rect = MKMapRect(x: bounds.sw.latitude, y: bounds.sw.longitude, width: bounds.ne.latitude - bounds.sw.latitude, height: bounds.ne.longitude - bounds.sw.longitude)
                
                if rect.contains(MKMapPoint(x: latitude, y: longitude)) {
                    ifContainsAtLeastOnePoint  = true
                    break
                }
            }
        }
        
        //mapView.removeAnnotations(mapView.annotations ?? [])
        if self.carAnnotations?.count != nil{
            if let existingAnnotations = self.carAnnotations {
                mapView.removeAnnotations(existingAnnotations)
            }
            self.carAnnotations.removeAll()
        }
        
        var coordinates = [CLLocationCoordinate2D]()
        
        for asset in selectedAssets {
            if(trackers.keys.contains(asset)) {
                let tracker = trackers[asset]
                
                let latitude = tracker?.lat ?? 0.0
                let longitude = tracker?.lng ?? 0.0
                
                let annotation = MyCustomPointAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                annotation.coordinate = coordinate
                annotation.carImage = true
                self.Circle = false
                //mapView.addAnnotation(annotation)
                self.carAnnotations.append(annotation)
                coordinates.append(coordinate)
            }
        }
        
        //        if ifContainsAtLeastOnePoint {
        //            return
        //        }
        if(coordinates.count == 0)
        {
            return
        }
        
        mapView.camera = mapView.cameraThatFitsCoordinateBounds(MGLPolygon(coordinates: coordinates, count: UInt(coordinates.count)).overlayBounds, edgePadding: UIEdgeInsets(top: 140, left: 50, bottom: 70, right: 50))
        
        
        //mapView.zoomLevel = defaultPtZoom
        if(coordinates.count==1)
        {
            mapView.zoomLevel = defaultPtZoom
        }
        else
        {
            if( mapView.zoomLevel > defaultPtZoom )
            {
                mapView.zoomLevel = defaultPtZoom
            }
            //mapView.zoomLevel = defaultZoom
        }
    }
    
    
    func setRightPanelData() {
        self.assetMultiSelectTableView.setData(Global.shared.AllTrackerList)
        self.assetMultiSelectTableView.reloadData()
        self.indicator.alpha = 0
        self.tableViewHC.constant = self.assetMultiSelectTableView.getHeight()
        self.assetMultiSelectTableView.layer.borderColor = UIColor.gray.cgColor
        self.assetMultiSelectTableView.layer.borderWidth = 0.2
        self.assetMultiSelectTableView.layer.cornerRadius = 20.0
        self.assetMultiSelectTableView.layer.shadowColor = UIColor.black.cgColor
        self.assetMultiSelectTableView.layer.shadowOffset = CGSize(width:3.0,height:3.0)
        self.assetMultiSelectTableView.layer.shadowOpacity = 0.7
        self.assetMultiSelectTableView.layer.shadowRadius = 20.0
        self.assetMultiSelectTableView.layer.masksToBounds = false
    }
    
    override func setResult(_ result: Any, from id: String, sender: Any? = nil) {
        
        if id == "AssetMultiSelectTableViewCell-selectedItem" {
            let row = (result as! (Int, Bool)).0
            let isSelected = (result as! (Int, Bool)).1
            
            if assetList.count <= row {
                return
            }
            self.assetList[row].isSelected = isSelected
            self.selectedAssets.removeAll()
            for asset in self.assetList {
                if asset.isSelected {
                    self.selectedAssets.append(asset)
                }
            }
        }
        self.radius = 0
        showCarsOnMap()
    }
}
extension UIImage{
    func scaledImage(withSize size: CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(size,false,0.0)
        defer{UIGraphicsEndImageContext()}
        draw(in: CGRect(x:0.0,y:0.0,width:size.width,height:size.height))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
    func scaleImageToFitSize(size:CGSize) -> UIImage{
        let aspect = self.size.width / self.size.height
        if size.width / aspect <= size.height{
            return scaledImage(withSize:CGSize(width:size.width,height: size.width / aspect))
        }
        else{
            return scaledImage(withSize:CGSize(width:size.height * aspect, height:size.height))
        }
    }
}
// MGLMapViewDelegate delegate
extension GeofenceViewController: MGLMapViewDelegate {
    // Use the default marker. See also: our view annotation or custom marker examples.
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        let myAnnotation = annotation as! MyCustomPointAnnotation
        
        if (!myAnnotation.willUseImage) {
            if (myAnnotation.carImage)
            {
                print("display car")
                let annotationImage = MGLAnnotationImage(image: carImage.scaleImageToFitSize(size: CGSize(width:15,height:15)), reuseIdentifier: "car_image")
                return annotationImage
            }
            return nil;
        }
        let annotationImage = MGLAnnotationImage(image: circleImage, reuseIdentifier: "circle_image")
        return annotationImage
    }
    
    // Allow callout view to appear when an annotation is tapped.
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // This delegate method is where you tell the map to load a view for a specific annotation based on the willUseImage property of the custom subclass.
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        
        if let myAnnotation = annotation as? MyCustomPointAnnotation {
            if (myAnnotation.willUseImage) {
                return nil
            }
        }
        if(self.Circle){
        // Assign a reuse identifier to be used by both of the annotation views, taking advantage of their similarities.
            let reuseIdentifier = "reusableDotView"
            
            // For better performance, always try to reuse existing annotations.
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
            // If there’s no reusable annotation view available, initialize a new one.
            if annotationView == nil {
                annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
                if(radius == 0)
                {
                    return nil
                }
                annotationView?.frame = CGRect(x: 0, y: 0, width: radius, height: radius)
                annotationView?.layer.cornerRadius = (annotationView?.frame.size.width)! / 2
                annotationView?.layer.borderWidth = 2.0
                annotationView?.layer.borderColor = UIColor.red.cgColor
                annotationView!.backgroundColor = UIColor.clear
            }
            
                return annotationView
        }
        return nil
    }
}
