
import UIKit
import SwiftyUserDefaults
class LeftMenuViewController: BaseViewController {

    
    @IBOutlet var activateBk: UIView!
    @IBOutlet var activateImage: UIImageView!

    @IBOutlet var monitorBk: UIView!
    @IBOutlet var monitorImage: UIImageView!

    @IBOutlet var replayBk: UIView!
    @IBOutlet var replayImage: UIImageView!

    @IBOutlet var reportsBk: UIView!
    @IBOutlet var reportsImage: UIImageView!

    @IBOutlet var geofenceBk: UIView!
    @IBOutlet var geofenceImage: UIImageView!
    
    @IBOutlet var setAlarmBk: UIView!
    @IBOutlet var setAlarmImage: UIImageView!
    
    @IBOutlet var orderTrackerBk: UIView!
    @IBOutlet var orderTrackerImage: UIImageView!

    @IBOutlet var orderServiceBk: UIView!
    @IBOutlet var orderServiceImage: UIImageView!

    @IBOutlet var updateDriverBk: UIView!
    @IBOutlet var updateDriverImage: UIImageView!

    //@IBOutlet var updateCreditBk: UIView!
    //@IBOutlet var updateCreditImage: UIImageView!
    
    @IBOutlet var labelUsername: UILabel!
    @IBOutlet var labelCurDateTime: UILabel!
    
    let selectedBkColor: UIColor = UIColor(hexString: "#aaaaaa")
    let normalColor: UIColor = UIColor(hexString: "#777777")
    let selectedColor: UIColor = UIColor(hexString: "#b9f39b")

    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "LeftMenuViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        _ = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _timer in
            
            let curDateTime = Date()
            let curTimeText = curDateTime.toString("MM/dd/yyyy HH:mm:ss")
            
            self.labelCurDateTime.text = curTimeText
        }
        
        setUsername(Global.shared.username)
        //print("leftmenu")
        onMonitor("")
    }
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
       // print("leftmenu")
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.layoutIfNeeded()
       // print("leftmenu")
    }
    
    
    func resetAllViews() {
        activateBk.backgroundColor = .clear
        activateImage.image = activateImage.image?.withRenderingMode(.alwaysTemplate)
        activateImage.tintColor = normalColor
        
        monitorBk.backgroundColor = .clear
        monitorImage.image = monitorImage.image?.withRenderingMode(.alwaysTemplate)
        monitorImage.tintColor = normalColor

        replayBk.backgroundColor = .clear
        replayImage.image = replayImage.image?.withRenderingMode(.alwaysTemplate)
        replayImage.tintColor = normalColor

        reportsBk.backgroundColor = .clear
        reportsImage.image = reportsImage.image?.withRenderingMode(.alwaysTemplate)
        reportsImage.tintColor = normalColor

        geofenceBk.backgroundColor = .clear
        geofenceImage.image = geofenceImage.image?.withRenderingMode(.alwaysTemplate)
        geofenceImage.tintColor = normalColor
        
        setAlarmBk.backgroundColor = .clear
        setAlarmImage.image = setAlarmImage.image?.withRenderingMode(.alwaysTemplate)
        setAlarmImage.tintColor = normalColor
        
        orderTrackerBk.backgroundColor = .clear
        orderTrackerImage.image = orderTrackerImage.image?.withRenderingMode(.alwaysTemplate)
        orderTrackerImage.tintColor = normalColor

        orderServiceBk.backgroundColor = .clear
        orderServiceImage.image = orderServiceImage.image?.withRenderingMode(.alwaysTemplate)
        orderServiceImage.tintColor = normalColor

        updateDriverBk.backgroundColor = .clear
        updateDriverImage.image = updateDriverImage.image?.withRenderingMode(.alwaysTemplate)
        updateDriverImage.tintColor = normalColor

        //updateCreditBk.backgroundColor = .clear
        //updateCreditImage.image = updateCreditImage.image?.withRenderingMode(.alwaysTemplate)
        //updateCreditImage.tintColor = normalColor

        
    }
    
    @IBAction func onActivate(_ sender: Any) {
        resetAllViews()

        activateBk.backgroundColor = selectedBkColor
        activateImage.tintColor = selectedColor
        
        self.slideMenuController()?.changeMainViewController(VCManager.shared.activateTrackerVC, close: true)

    }
    
    @IBAction func onMonitor(_ sender: Any) {
        resetAllViews()
        
        monitorBk.backgroundColor = selectedBkColor
        monitorImage.tintColor = selectedColor
        
        self.slideMenuController()?.changeMainViewController(MonitorViewController.getNewInstance(), close: true)
    }
    
    @IBAction func onReplay(_ sender: Any) {
        resetAllViews()
        
        replayBk.backgroundColor = selectedBkColor
        replayImage.tintColor = selectedColor
        
        self.slideMenuController()?.changeMainViewController(ReplayViewController.getNewInstance(), close: true)
        
    }
    
    @IBAction func onReports(_ sender: Any) {
        resetAllViews()
        
        reportsBk.backgroundColor = selectedBkColor
        reportsImage.tintColor = selectedColor
        
        self.slideMenuController()?.changeMainViewController(ReportsViewController.getNewInstance(), close: true)
    }
    
    @IBAction func onGeofence(_ sender: Any) {
        resetAllViews()
        
        geofenceBk.backgroundColor = selectedBkColor
        geofenceImage.tintColor = selectedColor
        
        self.slideMenuController()?.changeMainViewController(GeofenceViewController.getNewInstance(), close: true)
    }
    
    @IBAction func onSetAlarm(_ sender: Any) {
        resetAllViews()
        
        setAlarmBk.backgroundColor = selectedBkColor
        setAlarmImage.tintColor = selectedColor
        
        self.slideMenuController()?.changeMainViewController(SetAlarmViewController.getNewInstance(), close: true)
    }
    
    @IBAction func onOrderTracker(_ sender: Any) {
        resetAllViews()
        
        orderTrackerBk.backgroundColor = selectedBkColor
        orderTrackerImage.tintColor = selectedColor
        
        self.slideMenuController()?.changeMainViewController(OrderTrackerViewController.getNewInstance(), close: true)
        
    }
    
    @IBAction func onOrderService(_ sender: Any) {
        resetAllViews()
        
        orderServiceBk.backgroundColor = selectedBkColor
        orderServiceImage.tintColor = selectedColor
        
        self.slideMenuController()?.changeMainViewController(OrderServiceViewController.getNewInstance(), close: true)
        
    }
    
    @IBAction func onUpdateDriver(_ sender: Any) {
        resetAllViews()
        
        updateDriverBk.backgroundColor = selectedBkColor
        updateDriverImage.tintColor = selectedColor
        
        
        self.slideMenuController()?.changeMainViewController(VCManager.shared.updateDriverInfoVC, close: true)
        //        self.slideMenuController()?.changeMainViewController(VCManager.shared.allTransactionsVC, close: true)
    }
    
    @IBAction func onUpdateCredit(_ sender: Any) {
        resetAllViews()
        
        //updateCreditBk.backgroundColor = selectedBkColor
        //updateCreditImage.tintColor = selectedColor
        
        self.slideMenuController()?.changeMainViewController(VCManager.shared.updateCreditCardVC, close: true)
    }
    
    @IBAction func onLogout(_ sender: Any) {
        Defaults[.isLoggedIn] = false
        Global.shared.csrfToken = ""
        self.slideMenuController()?.dismiss(animated: true, completion: nil)
    }
    
    func setUsername(_ username: String) {
        self.labelUsername.text = username
    }
    
    
}
