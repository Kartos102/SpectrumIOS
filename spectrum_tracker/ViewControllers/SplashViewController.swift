//
//  SplashViewController.swift
//  spectrum_tracker
//
//  Created by JO on 2018/5/7.
//  Copyright © 2018 JO. All rights reserved.
//

import UIKit

class SplashViewController: BaseViewController {

    @IBOutlet var activityIndicatorView: NVActivityIndicatorView!
    @IBOutlet weak var loadingImageView: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        activityIndicatorView.startAnimating()
        activityIndicatorView.isHidden = true
        
        let gif = UIImage.gifImageWithName("earth")
        loadingImageView.image = gif
        
        self.perform(#selector(skipSlpash), with: nil, afterDelay: 2)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func skipSlpash() {
        
        self.present(LoginViewController.getNewInstance(), animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
