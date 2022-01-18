import UIKit
import Foundation

class VCManager {
    
    static var shared: VCManager! = VCManager()
    
    init() {
        self.leftMenuVC = LeftMenuViewController.getNewInstance()
        self.activateTrackerVC = ActivateTrackerViewController.getNewInstance()
        self.updateCreditCardVC = UpdateCreditCardViewController.getNewInstance()
        self.updateDriverInfoVC = UpdateDriverInfoViewController.getNewInstance()
    }
    
    
    var mainSlideMenuC: UIViewController!
    
    var leftMenuVC: UIViewController!
    var activateTrackerVC: UIViewController!
    var updateCreditCardVC: UIViewController!
    var updateDriverInfoVC: UIViewController!

}
