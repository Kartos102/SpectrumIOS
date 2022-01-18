import Foundation
import UIKit

class MainSlideMenuController: SlideMenuController {
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "MainSlideMenuController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func awakeFromNib() {
        
        self.mainViewController = MonitorViewController.getNewInstance()
        self.leftViewController = VCManager.shared.leftMenuVC
        super.awakeFromNib()
    }
    
}
