import UIKit
import Alamofire
import SwiftyJSON

import UIKit
import WebKit

class OrderTrackerViewController: ViewControllerWaitingResult , WKNavigationDelegate{
    
    @IBOutlet weak var webParentView: UIView!
    @IBOutlet weak var myIndicator: UIActivityIndicatorView!
    
    var webView: WKWebView!
    
    static func getNewInstance() -> UIViewController {
        let storyboardName = "Main"
        let viewControllerIdentifier = "OrderTrackerViewController"
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: viewControllerIdentifier)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myURL = URL(string: "https://spectrumtracking.com/buy_tracker.php")
        let myRequest = URLRequest(url: myURL!)
        
        webView = WKWebView(frame: self.view.frame)
        webView.navigationDelegate = self
        webView.load(myRequest)
        self.webParentView.addSubview(webView)
        self.webParentView.sendSubviewToBack(webView)
        showIndicator()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK:- WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Start to load")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("finish to load")
        hideIndicator()
    }
    
    func showIndicator() {
//        if self.myIndicator.alpha == 1 {
//            return
//        }
//        UIView.animate(withDuration: 0.2) {
//            self.myIndicator.alpha = 1
//        }
    }
    
    func hideIndicator() {
//        if self.myIndicator.alpha == 0 {
//            return
//        }
//        UIView.animate(withDuration: 0.2) {
//            self.myIndicator.alpha = 0
//        }
    }

}
