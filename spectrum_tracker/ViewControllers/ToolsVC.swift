//
//  ToolsVC.swift
//  spectrum_tracker
//
//  Created by Alex Chang on 2021/4/19.
//  Copyright © 2021 JO. All rights reserved.
//

import UIKit
import Mapbox

class ToolsVC: UIViewController {

    @IBOutlet weak var shareLocationContainerView: UIView!
    @IBOutlet weak var addGeofenceContainerView: UIView!
    @IBOutlet weak var familyCircleContainerView: UIView!
    @IBOutlet weak var satelliteMapSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        initUI()
    }
    
    func initUI() {
        [shareLocationContainerView, addGeofenceContainerView, familyCircleContainerView].forEach({ v in
            v?.layer.borderWidth = 1
            v?.layer.borderColor = UIColor(hexInt: 0xF96F00).cgColor
            v?.layer.cornerRadius = 5
        })
        
        if let monitorVC = MonitorViewController.instance {
            satelliteMapSwitch.isOn = monitorVC.mapStyle
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        MainContainerViewController.instance.hideOverlay()
    }
    
    @IBAction func shareLocationButtonTapped(_ sender: Any) {
        let controller = ShareTrackerViewController.getNewInstance()
        self.show(controller, sender: nil)
    }
    
    @IBAction func addGeofenceButtonTapped(_ sender: Any) {
        guard let monitorVC = MonitorViewController.instance else { return }
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EditGeofenceVC") as! EditGeofenceVC
        
        vc.tracker = monitorVC.selectedTrackers.first
        vc.defaultCenter = monitorVC.mapView.camera.centerCoordinate
        vc.defaultZoom = monitorVC.mapView.zoomLevel
        
        self.show(vc, sender: nil)
//        MainContainerViewController.instance.showOverlay(vc: vc)
    }
    
    @IBAction func familyCircleButtonTapped(_ sender: Any) {
        let controller = FamilyViewController.getNewInstance()
        self.show(controller, sender: nil)
    }
    
    @IBAction func satelliteMapSwitched(_ sender: Any) {
        guard let monitorVC = MonitorViewController.instance else { return }
        
        let mapStyle = monitorVC.mapStyle ?? false
        
        if(mapStyle) {
            monitorVC.mapView.styleURL = URL(string: "https://osm.spectrumtracking.com/styles/ciw6czz2n00242kmg6hw20box/style.json")
            let pCamera = monitorVC.mapView.camera
            pCamera.pitch = 45.0
            monitorVC.mapView.setCamera(pCamera, animated: false)
           // btn_style.setImage(UIImage(named: "mapstyle_satellite"),for:.normal)
        }
        else
        {
            monitorVC.mapView.styleURL = MGLStyle.satelliteStreetsStyleURL
            let pCamera = monitorVC.mapView.camera
            pCamera.pitch = 0.0
            monitorVC.mapView.setCamera(pCamera, animated: false)
           // btn_style.setImage(UIImage(named: "mapstyle_street"),for:.normal)
        }
        monitorVC.mapStyle = !mapStyle
    }
    
}
