//
//  EditGeofenceVC.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2020/8/7.
//  Copyright © 2020 JO. All rights reserved.
//

import UIKit
import Mapbox
import MapboxGeocoder
import Alamofire
import SwiftyJSON

class EditGeofenceVC: UIViewController {

    var tracker: TrackerModel? = nil
    
    @IBOutlet weak var mapViewFrameView: UIView!
    @IBOutlet weak var polygonDescriptionLabel: UILabel!
    @IBOutlet weak var fenceNameTextField: UITextField!
    
    @IBOutlet weak var vehicleNameLabel: UILabel!
    @IBOutlet weak var vehicleNameButton: UIButton!
    @IBOutlet weak var touchEventView: UIView!
    
    @IBOutlet weak var circleButton: UIButton!
    @IBOutlet weak var polygonButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    
    var mapView: MGLMapView!
    
    var polyline: MGLPolyline? = nil
    var prevPolyline: MGLPolyline? = nil
    var polygon: MGLPolygon? = nil
    var prevPolygon: MGLPolygon? = nil
    var pointMarkers: [MGLPointAnnotation] = []
    
    var singleTap: UITapGestureRecognizer!
    var doubleTap: UITapGestureRecognizer!
    var panGesture: UIPanGestureRecognizer!
    
    var geocoder: Geocoder!
    var defaultCenter = CLLocationCoordinate2D(latitude: 38.2534189, longitude: -85.7551944)
    var defaultZoom = 15.0
    var isDrawing = false
    
    let vehicleDropdown = DropDown()
    var fenceType: Int = 0 {  // 0: Circle, 1: Polygon
        didSet {
            if fenceType == 0 {
                panGesture.isEnabled = true
                singleTap.isEnabled = false
                doubleTap.isEnabled = false
                polygonDescriptionLabel.isHidden = true
            } else {
                panGesture.isEnabled = false
                singleTap.isEnabled = true
                doubleTap.isEnabled = true
                polygonDescriptionLabel.isHidden = false
            }
        }
    }
    
    var polygonPoints: [CLLocationCoordinate2D] = []
    
    var moveFirstPoint: CLLocationCoordinate2D? = nil
    var moveEndPoint: CLLocationCoordinate2D? = nil
    
    var geofenceList: [Geofence] = []
    var newGeofence: Geofence? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initMapView()
        initDropdown()
        fenceNameTextField.placeholder = "Fence Name".localized()
        
        circleButton.setTitle("Circle".localized(), for: .normal)
        polygonButton.setTitle("Polygon".localized(), for: .normal)
        clearButton.setTitle("Clear".localized(), for: .normal)
        saveButton.setTitle("Save".localized(), for: .normal)
        
        circleButton.isHidden = false
        polygonButton.isHidden = false
        clearButton.isHidden = true
        saveButton.isHidden = true
        polygonDescriptionLabel.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func initDropdown() {
        vehicleDropdown.anchorView = vehicleNameButton
        
        let vehicleNames = Global.shared.AllTrackerList.map({ $0.driverName.isEmpty ? $0.plateNumber : $0.driverName })
        
        vehicleDropdown.dataSource = vehicleNames
        vehicleDropdown.direction = .bottom
        vehicleDropdown.selectionAction = { index, item in
            self.tracker = Global.shared.AllTrackerList[index]
            self.vehicleNameLabel.text = item
            self.vehicleDropdown.selectRow(at: nil)
        }
        vehicleDropdown.width = vehicleDropdown.anchorView!.plainView.bounds.width
        
        if let trackerId = Global.shared.selectedTrackerIds.first,
            let index = Global.shared.AllTrackerList.firstIndex(where: { $0._id == trackerId }) {
            self.tracker = Global.shared.AllTrackerList[index]
            self.vehicleNameLabel.text = (self.tracker?.driverName.isEmpty ?? true) ? self.tracker?.plateNumber : self.tracker?.driverName
        }
    }
    
    func initMapView() {
        self.mapView = MGLMapView(frame: mapViewFrameView.bounds)
        
        mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.maximumZoomLevel = 30
        mapView.attributionButton.isHidden = true
        mapView.contentInset = UIEdgeInsets(top:60,left:0,bottom:0,right:0)
        mapView.updateConstraints()
        
        singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapSingleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        singleTap.require(toFail: doubleTap)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMapPan(_:)))
        
        touchEventView.addGestureRecognizer(singleTap)
        touchEventView.addGestureRecognizer(doubleTap)
        touchEventView.addGestureRecognizer(panGesture)
        
        self.mapViewFrameView.addSubview(mapView)
        mapView.delegate = self
        geocoder = Geocoder(accessToken: MapboxAccessToken)
        
        updateMapView()
    }
    
    func updateMapView() {
        if let lat = self.tracker?.lat, let lng = self.tracker?.lng, lat != 0.0, lng != 0.0 {
            mapView.centerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } else {
            mapView.centerCoordinate = defaultCenter
        }
        mapView.zoomLevel = defaultZoom
        
        self.getGeofenceList()
    }
    
    @objc func handleMapSingleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: touchEventView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        self.polygonPoints.append(coordinate)
        
        self.drawPolygon(points: self.polygonPoints, drawPrev: false)
    }
    
    @objc func handleMapDoubleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: touchEventView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        self.polygonPoints.append(coordinate)
        
        self.drawPolygon(points: self.polygonPoints, drawPrev: false)
        
        if polygonPoints.count < 3 {
            return
        }
        
        self.finishDrawingPolygon()
    }
    
    @objc func handleMapPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: touchEventView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        if gesture.state == .began {
            moveFirstPoint = coordinate
            moveEndPoint = nil
        } else {
            moveEndPoint = coordinate
            var distance = 0.0
            
            if let firstCoord = self.moveFirstPoint, let secondCoord = self.moveEndPoint {
                let firstLocation = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
                let secondLocation = CLLocation(latitude: secondCoord.latitude, longitude: secondCoord.longitude)
                
                distance = firstLocation.distance(from: secondLocation)
                polygonPoints = getCirclePoints(center: firstCoord, radius: distance)
            }
            
            if gesture.state == .ended {
                self.drawPolygon(points: self.polygonPoints, drawPrev: false)
                self.finishDrawingCircle()
            } else {
                self.drawPolygon(points: self.polygonPoints, drawPrev: true)
            }
        }
    }
    
    func getCirclePoints(center: CLLocationCoordinate2D, radius: Double) -> [CLLocationCoordinate2D] {
        let degreesBetweenPoints = 1.0
        //45 sides
        let numberOfPoints = floor(360.0 / degreesBetweenPoints)
        let distRadians: Double = radius / 6371000.0
        // earth radius in meters
        let centerLatRadians: Double = center.latitude * Double.pi / 180
        let centerLonRadians: Double = center.longitude * Double.pi / 180
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
        
        return coordinates
    }
    
    func drawPolygon(points: [CLLocationCoordinate2D], drawPrev: Bool) {
        if points.count < 2 {
            self.clear(onlyForPolygon: true)
        }
        
        if points.count > 1 {
            if prevPolygon != nil {
                mapView.removeAnnotation(prevPolygon!)
            }
            if prevPolyline != nil {
                mapView.removeAnnotation(prevPolyline!)
            }
            
            if drawPrev {
                prevPolygon = polygon
                prevPolyline = polyline
            } else {
                if polygon != nil {
                    mapView.removeAnnotation(polygon!)
                }
                if polyline != nil {
                    mapView.removeAnnotation(polyline!)
                }
            }
            
            polyline = MGLPolyline(coordinates: points, count: UInt(points.count))
            mapView.addAnnotation(polyline!)
            
            polygon = MGLPolygon(coordinates: points, count: UInt(points.count))
            mapView.addAnnotation(polygon!)
        }
        
        if let coord = points.last {
            let pointAnnotation = MGLPointAnnotation()
            pointAnnotation.title = "polygon-point"
            pointAnnotation.coordinate = coord
            mapView.addAnnotation(pointAnnotation)
            self.pointMarkers.append(pointAnnotation)
        }
    }
    
    func finishDrawingCircle() {
        var distance = 0.0
        
        if let firstCoord = self.moveFirstPoint, let secondCoord = self.moveEndPoint {
            let firstLocation = CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
            let secondLocation = CLLocation(latitude: secondCoord.latitude, longitude: secondCoord.longitude)
            
            distance = firstLocation.distance(from: secondLocation)
            polygonPoints = getCirclePoints(center: firstCoord, radius: distance)
        }
        
        newGeofence = Geofence()
        newGeofence?.id = "\(Int(Date().timeIntervalSince1970))"
        newGeofence?.name = fenceNameTextField.text ?? ""
        newGeofence?.type = "Circle"
        newGeofence?.lat = self.moveFirstPoint?.latitude ?? 0.0
        newGeofence?.lng = self.moveFirstPoint?.longitude ?? 0.0
        newGeofence?.radius = distance
        newGeofence?.boundary = []
        
        polygonPoints.removeAll()
        moveFirstPoint = nil
        moveEndPoint = nil
    }
    
    func finishDrawingPolygon() {
        if polygonPoints.count < 3 {
            polygonPoints.removeAll()
            moveFirstPoint = nil
            moveEndPoint = nil
            
            if prevPolygon != nil {
                mapView.removeAnnotation(prevPolygon!)
            }
            if prevPolyline != nil {
                mapView.removeAnnotation(prevPolyline!)
            }
            if polygon != nil {
                mapView.removeAnnotation(polygon!)
            }
            if polyline != nil {
                mapView.removeAnnotation(polyline!)
            }
            return
        }
        
        polygonPoints.append(polygonPoints.first!)
        self.drawPolygon(points: self.polygonPoints, drawPrev: false)
        
        newGeofence = Geofence()
        newGeofence?.id = "\(Int(Date().timeIntervalSince1970))"
        newGeofence?.name = fenceNameTextField.text ?? ""
        newGeofence?.type = "Polygon"
        newGeofence?.lat = 0.0
        newGeofence?.lng = 0.0
        newGeofence?.radius = 0.0
        newGeofence?.boundary = polygonPoints
        
        polygonPoints.removeAll()
        moveFirstPoint = nil
        moveEndPoint = nil
    }
    
    func clear(onlyForPolygon: Bool = false) {
        
        if !onlyForPolygon {
            fenceNameTextField.text = ""
            newGeofence = nil
            polygonPoints.removeAll()
            moveFirstPoint = nil
            moveEndPoint = nil
        }
        
        if prevPolygon != nil {
            mapView.removeAnnotation(prevPolygon!)
        }
        if prevPolyline != nil {
            mapView.removeAnnotation(prevPolyline!)
        }
        if polygon != nil {
            mapView.removeAnnotation(polygon!)
        }
        if polyline != nil {
            mapView.removeAnnotation(polyline!)
        }
        
        mapView.removeAnnotations(self.pointMarkers)
        self.pointMarkers.removeAll()
    }
    
    func getGeofenceList() {
        guard let id = self.tracker?._id else { return }
        
        if URLManager.isConnectedToInternet == false {
            print("Yes! internet is unavailable.")
            self.view.makeToast("Weak cell phone signal is detected!".localized())
            return
            // do some tasks..
        }
        
        let reqInfo = URLManager.trackers_id(id)
        
        let parameters: Parameters = [:]
        
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: URLEncoding.queryString, headers: headers)
        
        request.responseString { dataResponse in
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error")
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                let tracker = TrackerModel.parseJSON(json)
                self.geofenceList = tracker.geofence
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    func updateGeofence() {
        guard let id = self.tracker?._id else { return }
        guard let newGeofence = self.newGeofence else { return }
        
        newGeofence.name = fenceNameTextField.text ?? ""
        geofenceList.append(newGeofence)
        
        let geofenceJson = JSON(geofenceList.map({ $0.dictionary }))
        let geofenceJsonString = geofenceJson.rawString(options: []) ?? ""
        
        // send alarm setting
        let reqInfo = URLManager.modify()
        let parameters: Parameters = [
            "id" : id,
            "geofence": geofenceList.map({ $0.dictionary })
        ]
        let headers: HTTPHeaders = [
            "X-CSRFToken": Global.shared.csrfToken
        ]
        
        //showIndicator()
        
        let request = Global.AFManager.request(reqInfo.0, method: reqInfo.1, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
        
        request.responseString {
            dataResponse in
            
            if(dataResponse.response == nil || dataResponse.value == nil) {
                self.view.makeToast("server connect error".localized())
                return
            }
            
            let code = dataResponse.response!.statusCode
            let json = JSON.init(parseJSON: dataResponse.value!)
            
            if(code == 200) {
                self.view.makeToast("Success".localized())
            } else {
                let error = ErrorModel.parseJSON(json)
                self.view.makeToast(error.message)
            }
        }
    }
    
    @IBAction func circleButtonTapped(_ sender: Any) {
        fenceType = 0
        isDrawing = true
        touchEventView.isHidden = false
        polygonPoints.removeAll()
        moveFirstPoint = nil
        moveEndPoint = nil
        
        polygonDescriptionLabel.isHidden = true
        circleButton.isHidden = true
        polygonButton.isHidden = true
        clearButton.isHidden = false
        saveButton.isHidden = false
    }
    
    @IBAction func polygonButtonTapped(_ sender: Any) {
        fenceType = 1
        isDrawing = true
        touchEventView.isHidden = false
        polygonPoints.removeAll()
        moveFirstPoint = nil
        moveEndPoint = nil
        
        polygonDescriptionLabel.isHidden = false
        circleButton.isHidden = true
        polygonButton.isHidden = true
        clearButton.isHidden = false
        saveButton.isHidden = false
    }
    
    @IBAction func onBackButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func vehicleButtonTapped(_ sender: Any) {
        vehicleDropdown.show()
    }
    
    @IBAction func clearButtonTapped(_ sender: Any) {
        finishDrawing(shouldSave: false)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        finishDrawing(shouldSave: true)
    }
    
    func finishDrawing(shouldSave: Bool) {
        isDrawing = false
        touchEventView.isHidden = true
        
        if self.polygonPoints.count > 0 {
            if fenceType == 0 {
                self.finishDrawingCircle()
            } else {
                self.finishDrawingPolygon()
            }
        }
        
        if shouldSave {
            self.updateGeofence()
        }
        
        self.clear()
        
        circleButton.isHidden = false
        polygonButton.isHidden = false
        clearButton.isHidden = true
        saveButton.isHidden = true
    }
}

extension EditGeofenceVC: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, fillColorForPolygonAnnotation annotation: MGLPolygon) -> UIColor {
        return UIColor(hexInt: 0xff0000, alpha: 0.5)
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return 3
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        return UIColor(hexInt: 0xff0000)
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        if annotation.title == "polygon-point" {
            return MGLAnnotationImage(image: UIImage(named: "ic_marker_polygon_point")!, reuseIdentifier: "polygon-point")
        }
        return nil
    }
}
